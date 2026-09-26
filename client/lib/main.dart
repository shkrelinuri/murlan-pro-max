import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murlan_pro/screens/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: MurlanApp()));
}

class MurlanApp extends StatelessWidget {
  const MurlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Murlan Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E4D92)),
        scaffoldBackgroundColor: const Color(0xFF0A1F2E),
      ),
      home: const LoginScreen(),
    );
  }
}
