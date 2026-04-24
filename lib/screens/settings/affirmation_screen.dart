import 'package:flutter/material.dart';
import 'package:red/services/affirmation_service.dart';
import '../../services/affirmation_notification_service.dart'; // ✅ ADD
import '../../widgets/settings/affirmation_input_card.dart';
import '../../widgets/settings/affirmation_list.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  final TextEditingController _affirmationController = TextEditingController();
  final AffirmationService _service = AffirmationService.instance;

  final _notificationService =
      AffirmationNotificationService.instance; // ✅ ADD

  bool _isLoading = true;
  bool _isEnabled = false;
  int _frequency = 5;
  List<String> _affirmations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _affirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final enabled = await _service.getToggle();
    final frequency = await _service.getFrequency();
    final affirmations = await _service.getAffirmations();

    if (!mounted) return;

    setState(() {
      _isEnabled = enabled;
      _frequency = frequency;
      _affirmations = affirmations;
      _isLoading = false;
    });
  }

  // 🔥 CENTRAL NOTIFICATION UPDATE
  Future<void> _updateNotifications() async {
    final affirmations = await _service.getAffirmations();
    final frequency = await _service.getFrequency();
    final enabled = await _service.getToggle();

    await _notificationService.reschedule(
      isEnabled: enabled,
      affirmations: affirmations,
      frequency: frequency,
    );
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _isEnabled = value);

    await _service.saveToggle(value);
    await _updateNotifications(); // ✅ ADD
  }

  Future<void> _updateFrequency(double value) async {
    final newFrequency = value.round();

    setState(() => _frequency = newFrequency);

    await _service.saveFrequency(newFrequency);
    await _updateNotifications(); // ✅ ADD
  }

  Future<void> _addAffirmation() async {
    final text = _affirmationController.text.trim();
    if (text.isEmpty) return;

    final success = await _service.addAffirmation(text);

    if (!mounted) return;

    if (success) {
      _affirmationController.clear();
      FocusScope.of(context).unfocus();

      await _loadData();
      await _updateNotifications(); // ✅ ADD
    }
  }

  Future<void> _deleteAffirmation(int index) async {
    final success = await _service.deleteAffirmationByIndex(index);

    if (!mounted) return;

    if (success) {
      await _loadData();
      await _updateNotifications(); // ✅ ADD
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
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
        title: const Text(
          'Affirmations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF06292),
        ),
      )
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: const Text(
                    'Daily Affirmations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C51),
                    ),
                  ),
                  subtitle: const Text(
                    'Receive your affirmations throughout the day',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  value: _isEnabled,
                  onChanged: _toggleEnabled,

                  // 🔥 KEY FIXES
                  activeThumbColor: const Color(0xFFF06292), // thumb when ON
                  activeTrackColor: const Color(0xFFF8BBD0), // soft pink track

                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),

              Opacity(
                opacity: _isEnabled ? 1.0 : 0.5,
                child: _buildCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Frequency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D4C51),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context).copyWith(
                            sliderTheme: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), // 🔥 smaller
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10), // touch area
                              trackHeight: 3, // thinner track
                            ),
                          ),
                          child: Slider(
                            value: _frequency.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: const Color(0xFFF06292),
                            inactiveColor: Colors.pink.withValues(alpha: 0.1),
                            onChanged: _isEnabled ? _updateFrequency : null,
                          ),
                        ),
                        Center(
                          child: Text(
                            '$_frequency times/day',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF06292),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Opacity(
                opacity: _isEnabled ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                      EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Your Affirmations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6D4C51),
                        ),
                      ),
                    ),

                    AffirmationInputCard(
                      controller: _affirmationController,
                      isEnabled: _isEnabled,
                      onAdd: _addAffirmation,
                    ),

                    AffirmationList(
                      affirmations: _affirmations,
                      isEnabled: _isEnabled,
                      onDelete: _deleteAffirmation,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}