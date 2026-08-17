import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/validation/auth_validation.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class LupinusBuildApp extends StatelessWidget {
  const LupinusBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LupinusBuild',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final StreamSubscription<AuthState> authSubscription;

  Session? currentSession;
  bool isPasswordRecovery = false;
  bool isProcessingAuthCallback = false;
  String? authCallbackError;

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;
    final initialUri = Uri.base;

    currentSession = auth.currentSession;
    isProcessingAuthCallback = hasAuthCodeCallback(initialUri);

    final callbackError = readAuthCallbackError(initialUri);

    if (callbackError != null && callbackError.trim().isNotEmpty) {
      authCallbackError = callbackError;
      unawaited(_clearAuthCallbackUrl());
    }

    authSubscription = auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      setState(() {
        currentSession = authState.session;

        if (authState.event == AuthChangeEvent.passwordRecovery) {
          isPasswordRecovery = true;
        } else if (authState.event == AuthChangeEvent.signedOut) {
          isPasswordRecovery = false;
        }
      });
    });

    if (isProcessingAuthCallback) {
      unawaited(_processInitialAuthCallback(initialUri));
    }
  }

  Future<void> _processInitialAuthCallback(Uri callbackUri) async {
    try {
      final response = await Supabase.instance.client.auth.getSessionFromUrl(
        callbackUri,
      );

      await _clearAuthCallbackUrl();

      if (!mounted) return;

      setState(() {
        currentSession = response.session;
        isPasswordRecovery = isPasswordRecoveryRedirectType(
          response.redirectType,
        );
        isProcessingAuthCallback = false;
        authCallbackError = null;
      });
    } on AuthException catch (error) {
      await _handleAuthCallbackFailure(error.message);
    } catch (_) {
      await _handleAuthCallbackFailure(
        'The recovery link could not be processed. '
        'Request a new link and try again.',
      );
    }
  }

  Future<void> _handleAuthCallbackFailure(String message) async {
    await _clearAuthCallbackUrl();

    if (!mounted) return;

    setState(() {
      isProcessingAuthCallback = false;
      isPasswordRecovery = false;
      authCallbackError = message;
    });
  }

  Future<void> _clearAuthCallbackUrl() async {
    final cleanUri = Uri.base.replace(queryParameters: const {}, fragment: '');

    await SystemNavigator.routeInformationUpdated(uri: cleanUri, replace: true);
  }

  Future<void> _returnToLogin() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    setState(() {
      currentSession = null;
      isPasswordRecovery = false;
      isProcessingAuthCallback = false;
      authCallbackError = null;
    });
  }

  void handlePasswordUpdated() {
    setState(() {
      isPasswordRecovery = false;
    });
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessingAuthCallback) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying recovery link...'),
            ],
          ),
        ),
      );
    }

    if (authCallbackError != null) {
      return _AuthCallbackErrorScreen(
        message: authCallbackError!,
        onReturnToLogin: _returnToLogin,
      );
    }

    if (isPasswordRecovery) {
      return ResetPasswordScreen(onPasswordUpdated: handlePasswordUpdated);
    }

    if (currentSession == null) {
      return const LoginScreen();
    }

    return const DashboardScreen();
  }
}

class _AuthCallbackErrorScreen extends StatelessWidget {
  const _AuthCallbackErrorScreen({
    required this.message,
    required this.onReturnToLogin,
  });

  final String message;
  final Future<void> Function() onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off_outlined,
                      size: 54,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Recovery link unavailable',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: onReturnToLogin,
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
