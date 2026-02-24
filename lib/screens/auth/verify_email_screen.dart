import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    await ref.read(authServiceProvider).reloadUser();
    // authStateChanges will update automatically
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reloaded user state')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          const Text('A verification email was sent. Please check your inbox.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _sending ? null : _send, child: const Text('Resend verification')),
          ElevatedButton(onPressed: _check, child: const Text('I have verified — reload')),
        ]),
      ),
    );
  }
}
