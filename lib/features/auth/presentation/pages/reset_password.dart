import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../main.dart' show recoveryAccessToken;
import '../provider/auth_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;
  bool isVerifying = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _handlePasswordReset();
  }

  Future<void> _handlePasswordReset() async {
    if (kDebugMode) {
      print('=== Reset Password Page Loaded ===');
    }

    // First wait a moment for Supabase to process the URL
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      final supabase = ref.read(supabaseClientProvider);

      // Check if we already have a session (auto-exchanged)
      var session = supabase.auth.currentSession;

      if (kDebugMode) {
        print('Initial session check: ${session != null ? "EXISTS" : "NULL"}');
        if (session != null) {
          print('Session user: ${session.user.email}');
        }
      }

      // If we have a session, we're good to go
      if (session != null) {
        if (kDebugMode) {
          print('✅ Valid session found, showing password reset form');
        }
        setState(() {
          isVerifying = false;
        });
        return;
      }

      // No session yet - check if we have a code to exchange
      if (kDebugMode) {
        print('No session found, checking for PKCE code...');
        print('Recovery token from URL: ${recoveryAccessToken ?? "NULL"}');
      }

      if (recoveryAccessToken == null || recoveryAccessToken!.isEmpty) {
        if (kDebugMode) {
          print('❌ No recovery code found in URL');
        }
        if (!mounted) return;
        setState(() {
          isVerifying = false;
          errorMessage =
              'Invalid or missing reset token. Please request a new password reset link.';
        });
        return;
      }

      // Try to exchange the PKCE code for a session
      if (kDebugMode) {
        print('Attempting to exchange PKCE code for session...');
      }

      try {
        // Use exchangeCodeForSession for PKCE flow
        await supabase.auth.exchangeCodeForSession(recoveryAccessToken!);

        // Check if session was created
        session = supabase.auth.currentSession;

        if (kDebugMode) {
          if (session != null) {
            print('✅ Successfully exchanged code! User: ${session.user.email}');
          } else {
            print('⚠️ Code exchanged but no session found');
          }
        }

        if (!mounted) return;
        setState(() {
          isVerifying = false;
        });
        return;
      } on AuthException catch (e) {
        if (kDebugMode) {
          print('❌ Auth error during code exchange: ${e.message}');
          print('Status code: ${e.statusCode}');
        }

        // Check for code verifier not found error (PKCE flow issue)
        if (e.message.contains('Code verifier') ||
            e.message.contains('local storage') ||
            e.message.contains('verifier could not be found')) {
          if (!mounted) return;
          setState(() {
            isVerifying = false;
            errorMessage =
                'Browser session mismatch. Please open the reset link in the SAME browser where you requested the password reset. Or request a new reset link from THIS browser.';
          });
          return;
        }

        // Check if it's an expired token error
        if (e.message.contains('expired') ||
            e.message.contains('invalid') ||
            e.statusCode == '400') {
          if (!mounted) return;
          setState(() {
            isVerifying = false;
            errorMessage =
                'Your reset link has expired. Password reset links are valid for 1 hour. Please request a new one.';
          });
          return;
        }

        // Other auth errors
        if (!mounted) return;
        setState(() {
          isVerifying = false;
          errorMessage =
              'Authentication error: ${e.message}\n\nPlease try requesting a new password reset link.';
        });
        return;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Unexpected error during code exchange: $e');
        }
        if (!mounted) return;
        setState(() {
          isVerifying = false;
          errorMessage =
              'An error occurred while verifying your reset link. Please try requesting a new one.';
        });
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Fatal error in _handlePasswordReset: $e');
      }
      if (!mounted) return;
      setState(() {
        isVerifying = false;
        errorMessage =
            'An unexpected error occurred. Please try again or request a new reset link.';
      });
    }
  }

  Future<void> updatePassword() async {
    final supabase = ref.read(supabaseClientProvider);
    final newPassword = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (newPassword.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill both fields')));
      return;
    }
    if (newPassword != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => loading = true);
    try {
      final res = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated. Please login.')),
        );
        context.go('/login'); // or your login route
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update password')),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isVerifying
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (kDebugMode) {
                          print('Go to Login button pressed');
                        }
                        context.go('/login');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: loading ? null : updatePassword,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('Set new password'),
                  ),
                ],
              ),
      ),
    );
  }
}
