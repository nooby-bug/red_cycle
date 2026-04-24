import 'package:flutter/material.dart';
import '../services/mood_pain_service.dart';
import '../models/daily_log.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  final _service = MoodPainService.instance;

  int _selectedMood = 3; // default neutral
  double _painLevel = 5;

  bool _isLoading = true;

  final List<String> _emojis = ["😄", "🙂", "😐", "😞", "😢"];

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final log = await _service.getTodayLog();

    if (!mounted) return;

    if (log != null) {
      setState(() {
        _selectedMood = log.mood;
        _painLevel = log.pain.toDouble();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    await _service.saveLog(
      date: DateTime.now(),
      mood: _selectedMood,
      pain: _painLevel.round(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved successfully")),
    );

    Navigator.pop(context);
  }

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_emojis.length, (index) {
        final moodValue = index + 1;

        final isSelected = moodValue == _selectedMood;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedMood = moodValue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF48FB1).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _emojis[index],
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pink.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        title: const Text("Log Mood"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MOOD
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How are you feeling today?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C51),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMoodSelector(),
                ],
              ),
            ),

            // PAIN
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pain Level",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C51),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _painLevel,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: const Color(0xFFF06292),
                    inactiveColor:
                    Colors.pink.withValues(alpha: 0.1),
                    onChanged: (value) {
                      setState(() => _painLevel = value);
                    },
                  ),
                  Center(
                    child: Text(
                      _painLevel.round().toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF06292),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF06292),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}