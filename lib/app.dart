import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
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

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;
    currentSession = auth.currentSession;

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
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  void handlePasswordUpdated() {
    setState(() {
      isPasswordRecovery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isPasswordRecovery) {
      return ResetPasswordScreen(onPasswordUpdated: handlePasswordUpdated);
    }

    if (currentSession == null) {
      return const LoginScreen();
    }

    return const DashboardScreen();
  }
}
