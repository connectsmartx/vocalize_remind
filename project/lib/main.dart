import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const IntentScreen(),
    );
  }
}

class IntentScreen extends StatefulWidget {
  const IntentScreen({super.key});

  @override
  State<IntentScreen> createState() => _IntentScreenState();
}

class _IntentScreenState extends State<IntentScreen> {
  final controller = TextEditingController();

  void scheduleAlarm() async {
    final now = DateTime.now().add(const Duration(seconds: 30));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("intent", controller.text);

    await AndroidAlarmManager.oneShotAt(
      now,
      0,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "What do you need to remember?",
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: scheduleAlarm,
                child: const Text("Schedule in 30 seconds"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> alarmCallback() async {
  final tts = FlutterTts();
  final prefs = await SharedPreferences.getInstance();
  final intent = prefs.getString("intent") ?? "your task";

  await WakelockPlus.enable();
  await tts.setVolume(0.2);

  double volume = 0.2;

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    volume += 0.05;
    if (volume >= 1.0) {
      volume = 1.0;
      timer.cancel();
    }
    await tts.setVolume(volume);
  });

  while (true) {
    await tts.speak("Excuse me, it is time to $intent.");
    await Future.delayed(const Duration(seconds: 4));
  }
}
