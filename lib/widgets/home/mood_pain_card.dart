import 'package:flutter/material.dart';
import '../../services/mood_pain_service.dart';

class MoodPainCard extends StatefulWidget {
  const MoodPainCard({super.key});

  @override
  State<MoodPainCard> createState() => _MoodPainCardState();
}

class _MoodPainCardState extends State<MoodPainCard> {
  bool _isSavedToday = false;
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
        _isSavedToday = true; // 🔥 ADD
        _isLoading = false;
      });
    } else {
      setState(() {
        _isSavedToday = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    await _service.saveLog(
      date: DateTime.now(),
      mood: _mood,
      pain: _pain.round(),
    );

    setState(() {
      _isSavedToday = true;
    });
  }

  Widget _buildInputView({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.center,
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

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

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
    );
  }

  Widget _buildSavedView({Key? key}) {
    final emoji = emojis[_mood - 1];

    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 LEFT SIDE (TEXT)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8), // ✅ HERE

              Text(
                "Mood logged $emoji",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4C51),
                ),
              ),

              const SizedBox(height: 6), // ✅ HERE

              Text(
                "Pain: ${_pain.round()}",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // 🔥 RIGHT SIDE (BIG EDIT BUTTON)
        Container(
          margin: const EdgeInsets.only(left: 14),
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF48FB1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isSavedToday = false;
              });
            },
            icon: const Icon(
              Icons.edit_rounded,
              color: Color(0xFFF06292),
              size: 24,
            ),
            splashRadius: 20,
          ),
        ),
      ],
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.98, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _isSavedToday
            ? _buildSavedView(key: const ValueKey("saved"))
            : _buildInputView(key: const ValueKey("input")),
      ),
    );
  }
}