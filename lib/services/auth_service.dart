import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

/// Enum to track the authentication provider type
enum AuthProviderType { email, phone, google, unknown }

/// Result class for sign-in operations that includes verification status
class AuthSignInResult {
  final UserCredential credential;
  final AuthProviderType provider;
  final bool isVerified;

  AuthSignInResult({
    required this.credential,
    required this.provider,
    required this.isVerified,
  });
}

/// Service class for handling Firebase Authentication operations
/// Centralizes all authentication logic for easy maintenance
class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _db = FirebaseService.firestore;

  /// Stream of auth state changes - use this to listen for login/logout events
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Get the currently signed-in user, if any
  User? get currentUser => _auth.currentUser;

  /// Check if the current user's email is verified
  /// Returns true for phone auth users (already verified)
  /// or if email is verified for email-based auth
  Future<bool> isUserVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Get the provider used to sign in
    final providerType = await _getUserProviderType(user);

    // Phone authentication doesn't require email verification
    if (providerType == AuthProviderType.phone) {
      return true;
    }

    // For email/google auth, reload and check verification status
    await user.reload();
    final refreshedUser = _auth.currentUser;
    return refreshedUser?.emailVerified ?? false;
  }

  /// Get the primary authentication provider for a user
  Future<AuthProviderType> _getUserProviderType(User user) async {
    // Check provider data first
    for (final provider in user.providerData) {
      if (provider.providerId == 'phone') {
        return AuthProviderType.phone;
      } else if (provider.providerId == 'google.com') {
        return AuthProviderType.google;
      }
    }

    // Default to email for password-based auth
    return AuthProviderType.email;
  }

  /// Sign up with email and password
  /// Automatically sends verification email after signup
  Future<AuthSignInResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // Create the user account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name if provided
    if (displayName != null) {
      await cred.user?.updateDisplayName(displayName);
    }

    // Send email verification
    await cred.user?.sendEmailVerification();

    // Create user profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'photoURL': cred.user?.photoURL ?? '',
      'provider': 'email',
      'emailVerified': false,
    });

    return AuthSignInResult(
      credential: cred,
      provider: AuthProviderType.email,
      isVerified: false,
    );
  }

  /// Sign in with email and password
  /// Returns AuthSignInResult with verification status
  Future<AuthSignInResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Reload user to get latest verification status
    await cred.user?.reload();
    final refreshedUser = _auth.currentUser;

    return AuthSignInResult(
      credential: cred,
      provider: AuthProviderType.email,
      isVerified: refreshedUser?.emailVerified ?? false,
    );
  }

  /// Sign in with Google
  /// Google accounts are typically pre-verified by Google
  Future<AuthSignInResult> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope(
      'https://www.googleapis.com/auth/contacts.readonly',
    );
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    try {
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final user = userCredential.user;

      if (user != null) {
        // Create or update user profile in Firestore
        await _db.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'emailVerified': user.emailVerified,
        }, SetOptions(merge: true));

        // Reload to get latest verification status
        await user.reload();
        final refreshedUser = _auth.currentUser;

        return AuthSignInResult(
          credential: userCredential,
          provider: AuthProviderType.google,
          isVerified: refreshedUser?.emailVerified ?? user.emailVerified,
        );
      }

      return AuthSignInResult(
        credential: userCredential,
        provider: AuthProviderType.google,
        isVerified: true, // Google accounts are typically verified
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with phone number
  /// Phone authentication doesn't require email verification
  Future<AuthSignInResult> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);

    // Create user profile in Firestore if it doesn't exist
    await _db.collection('users').doc(cred.user!.uid).set({
      'phoneNumber': cred.user?.phoneNumber ?? '',
      'displayName': cred.user?.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'provider': 'phone',
      'emailVerified': true, // Phone auth is already verified
    }, SetOptions(merge: true));

    return AuthSignInResult(
      credential: cred,
      provider: AuthProviderType.phone,
      isVerified: true, // Phone auth is always verified
    );
  }

  /// Send phone verification code
  /// Returns the verification ID needed to complete sign-in
  Future<String> sendPhoneVerification(String phoneNumber) async {
    String? verificationId;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in when verification is complete on some devices
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verificationIdInternal, int? resendToken) {
        verificationId = verificationIdInternal;
      },
      codeAutoRetrievalTimeout: (String verificationIdInternal) {
        verificationId = verificationIdInternal;
      },
    );

    // Wait for the code to be sent
    await Future.delayed(const Duration(milliseconds: 1500));
    return verificationId ?? '';
  }

  /// Sign out the current user
  Future<void> signOut() => _auth.signOut();

  /// Send email verification to current user
  /// Only works for email-based accounts that aren't verified yet
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload the current user to get latest verification status
  /// Important: Call this after email verification to update the user's status
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      // Update Firestore with latest verification status
      await _db.collection('users').doc(user.uid).set({
        'emailVerified': user.emailVerified,
      }, SetOptions(merge: true));
    }
  }

  /// Get user profile from Firestore
  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    return _db.collection('users').doc(uid).get();
  }

  /// Update user profile fields (both FirebaseAuth display name and Firestore).
  /// Any non-null parameter will be written; null fields are ignored.
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? city,
    String? bio,
  }) async {
    final user = _auth.currentUser;

    // Keep auth user in sync with profile name
    if (user != null && user.uid == uid && displayName != null) {
      await user.updateDisplayName(displayName);
    }

    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (city != null) data['city'] = city;
    if (bio != null) data['bio'] = bio;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }
}
