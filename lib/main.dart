import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/directory_screen.dart';
import 'screens/my_listings_screen.dart';
import 'screens/map_view_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kigali City Services',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC857), // warm yellow
          secondary: Color(0xFF4ECDC4),
          surface: Color(0xFF062345),
        ),
        scaffoldBackgroundColor: const Color(0xFF021E3A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF021E3A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF062345),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        cardColor: const Color(0xFF062345),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF021E3A),
          selectedItemColor: Color(0xFFFFC857),
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// AuthGate - Handles authentication state and navigation
///
/// This widget monitors Firebase authentication state and decides which screen to show:
/// - If user is signed in and email is verified (or phone auth) → HomePage
/// - If user is signed in but email is not verified → VerifyEmailScreen
/// - If user is not signed in → AuthScreen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes stream - this will rebuild when user signs in/out
    final authStateAsync = ref.watch(authStateChangesProvider);

    return authStateAsync.when(
      data: (user) {
        // Check if user is signed in
        if (user != null) {
          // User is signed in, check verification status
          return const _AuthGateContent();
        }
        // No user signed in - show auth screen
        return const AuthScreen();
      },
      loading: () => _buildLoadingScreen(context),
      error: (error, stack) => _buildErrorScreen(context, error.toString()),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021E3A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Loading...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF021E3A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inner widget that checks verification status for authenticated users
class _AuthGateContent extends ConsumerStatefulWidget {
  const _AuthGateContent();

  @override
  ConsumerState<_AuthGateContent> createState() => _AuthGateContentState();
}

class _AuthGateContentState extends ConsumerState<_AuthGateContent> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final isVerified = await _authService.isUserVerified();
    if (mounted) {
      setState(() {
        _isVerified = isVerified;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildLoadingScreen(context);
    }

    // Check if email is verified (or if phone auth was used)
    if (!_isVerified) {
      // Email not verified - show verification screen
      return const VerifyEmailScreen();
    }
    // Email verified (or phone auth) - show main app
    return const HomePage();
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021E3A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Loading...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DirectoryScreen(),
    MyListingsScreen(),
    MapViewScreen(),
    SettingsScreen(),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
