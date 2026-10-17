import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/main/main_screen.dart';

class CRMApp extends StatelessWidget {
  const CRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Relations CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
