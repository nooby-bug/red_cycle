import 'package:flutter/material.dart';
import 'package:red/services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint("Notification init failed: $e");
  }

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