import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

class MellIQApp extends StatelessWidget {
  const MellIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MellIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
