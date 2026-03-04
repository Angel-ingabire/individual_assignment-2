import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

// Google Sign In stub - will be implemented properly after UI setup
class GoogleSignInHelper {
  static bool isSupported() => false;
  static Future<Map<String, String>?> signIn() async => null;
  static Future<void> signOut() async {}
}

class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _db = FirebaseService.firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null) {
      await cred.user?.updateDisplayName(displayName);
    }
    await cred.user?.sendEmailVerification();
    // create user profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'photoURL': cred.user?.photoURL ?? '',
      'provider': 'email',
    });
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign in with Google - requires proper setup in Firebase Console
  // and google-services.json configuration
  Future<UserCredential> signInWithGoogle() async {
    // Use Firebase Auth's Google provider for sign-in
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope(
      'https://www.googleapis.com/auth/contacts.readonly',
    );
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    try {
      final userCredential = await _auth.signInWithPopup(googleProvider);

      // Create or update user profile in Firestore
      final user = userCredential.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
  ) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  // Phone verification - returns the verification ID for manual verification
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

    // Wait a bit for the code to be sent
    await Future.delayed(const Duration(milliseconds: 1500));
    return verificationId ?? '';
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) await user.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) await user.reload();
  }

  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    return _db.collection('users').doc(uid).get();
  }
}
