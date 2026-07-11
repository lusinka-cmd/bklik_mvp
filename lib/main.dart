import 'package:flutter/material.dart';

import 'screens/bklik_mvp_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BklikApp());
}

class BklikApp extends StatelessWidget {
  const BklikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Բկլիկ ձկնիկ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF31B9DC),
        ),
      ),
      home: const BklikMvpScreen(),
    );
  }
}