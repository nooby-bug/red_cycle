import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MyCycleApp());
}

class MyCycleApp extends StatelessWidget {
  const MyCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyCycle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}