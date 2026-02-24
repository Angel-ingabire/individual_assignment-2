import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/verify_email_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Sign In')),
                ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text('Sign Up')),
              ]),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Signed in as: ${user.email ?? ''}'),
              Text('UID: ${user.uid}'),
              const SizedBox(height: 8),
              Text('Email verified: ${user.emailVerified}'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen())), child: const Text('Email verification')),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Location notifications'),
                const Spacer(),
                Switch(value: true, onChanged: (v) {}),
              ]),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () async => await ref.read(authServiceProvider).signOut(), child: const Text('Sign out')),
            ]),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
