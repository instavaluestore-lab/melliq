import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';

class LupinusBuildApp extends StatelessWidget {
  const LupinusBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LupinusBuild',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
