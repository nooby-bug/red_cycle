import 'package:flutter/material.dart';
import 'package:red/services/notification_service.dart';
import 'screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:red/services/affirmation_notification_service.dart';
import'package:red/services/affirmation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 REQUIRED for scheduled notifications
  tz.initializeTimeZones();

  try {
    await NotificationService.instance.init();
    await AffirmationNotificationService.instance.init();
    await AffirmationService.instance.init();
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