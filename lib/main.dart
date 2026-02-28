import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eirafocus/core/theme/theme.dart';
import 'package:eirafocus/features/onboarding/presentation/splash_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EiraFocusApp(),
    ),
  );
}

class EiraFocusApp extends StatelessWidget {
  const EiraFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EiraFocus',
      theme: EiraTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
