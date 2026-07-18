import 'package:flutter/material.dart';
import 'package:my_personal_tracker/core/theme.dart';
import 'package:my_personal_tracker/app/app_startup_lock_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OwnFi',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const AppStartupLockGate(),
    );
  }
}
