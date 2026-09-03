import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DataRecoveryApp()));
}

class DataRecoveryApp extends StatelessWidget {
  const DataRecoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '01 Data Recovery',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
