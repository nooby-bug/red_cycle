import 'package:flutter/material.dart';
import '../../services/mood_pain_service.dart';

class MoodPainCard extends StatefulWidget {
  const MoodPainCard({super.key});

  @override
  State<MoodPainCard> createState() => _MoodPainCardState();
}

class _MoodPainCardState extends State<MoodPainCard> {
  final _service = MoodPainService.instance;

  int _mood = 3;
  double _pain = 5;

  bool _isLoading = true;

  final List<String> emojis = ["😄", "🙂", "😐", "😞", "😢"];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final log = await _service.getTodayLog();

    if (!mounted) return;

    if (log != null) {
      setState(() {
        _mood = log.mood;
        _pain = log.pain.toDouble();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    await _service.saveLog(
      date: DateTime.now(),
      mood: _mood,
      pain: _pain.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How are you feeling today?",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF6D4C51),
            ),
          ),

          const SizedBox(height: 12),

          // MOOD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(emojis.length, (index) {
              final value = index + 1;

              return GestureDetector(
                onTap: () {
                  setState(() => _mood = value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _mood == value
                        ? const Color(0xFFF48FB1).withValues(alpha: 0.105)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // PAIN
          const Text(
            "Pain level",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6D4C51),
            ),
          ),
      Theme(
        data: Theme.of(context).copyWith(
          sliderTheme: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            trackHeight: 3,
          ),
        ),
        child: Slider(
          value: _pain,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: const Color(0xFFF06292),
          inactiveColor: Colors.pink.withValues(alpha: 0.08),
          onChanged: (value) {
            setState(() => _pain = value);
          },
        ),
      ),

// ✅ OUTSIDE Theme
      const SizedBox(height: 12),

      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context); // ✅ capture early

            await _save();

            if (!mounted) return;

            messenger.showSnackBar(
              const SnackBar(
                content: Text("Saved 💗"),
                duration: Duration(milliseconds: 800),
              ),
            );
          },
          child: const Text(
            "Save",
            style: TextStyle(
              color: Color(0xFFF06292),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}