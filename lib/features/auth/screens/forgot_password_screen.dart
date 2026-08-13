import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  late final AuthService authService;

  bool isSending = false;
  bool isSubmitted = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail.trim());
    authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> requestPasswordReset() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!kIsWeb) {
      setState(() {
        errorMessage =
            'Password recovery is not configured for this platform yet. '
            'Contact your administrator.';
      });
      return;
    }

    setState(() {
      isSending = true;
      errorMessage = null;
    });

    try {
      await authService.requestPasswordReset(
        email: emailController.text,
        redirectTo: Uri.base.origin,
      );

      if (!mounted) return;

      setState(() {
        isSubmitted = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not send the recovery email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: isSubmitted
                    ? _RecoveryEmailSent(
                        email: emailController.text.trim(),
                        onBackToLogin: () => Navigator.of(context).pop(),
                      )
                    : Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Forgot your password?',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Enter your MaxShade account email. '
                              'We will send a secure link for choosing a new password.',
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: emailController,
                              enabled: !isSending,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Enter your email address';
                                }

                                if (!email.contains('@')) {
                                  return 'Enter a valid email address';
                                }

                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (!isSending) {
                                  requestPasswordReset();
                                }
                              },
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: isSending
                                  ? null
                                  : requestPasswordReset,
                              icon: isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.mark_email_read_outlined),
                              label: Text(
                                isSending
                                    ? 'Sending...'
                                    : 'Send Recovery Email',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: isSending
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Back to Login'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryEmailSent extends StatelessWidget {
  const _RecoveryEmailSent({required this.email, required this.onBackToLogin});

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 54,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Check your email',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'If an account exists for $email, a password recovery link has been sent.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'For security, the link will expire. Check your spam folder if it does not arrive.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onBackToLogin,
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
