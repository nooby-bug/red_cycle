import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:red/services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _isLoading = true;

  bool _masterEnabled = false;
  bool _periodReminderEnabled = false;
  bool _loggingReminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _masterEnabled = prefs.getBool('reminders_master') ?? false;
      _periodReminderEnabled = prefs.getBool('reminders_period') ?? false;
      _loggingReminderEnabled = prefs.getBool('reminders_logging') ?? false;

      final hour = prefs.getInt('reminders_time_hour') ?? 8;
      final minute = prefs.getInt('reminders_time_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);

      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _handleMasterToggle(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();

      if (!granted) {
        setState(() => _masterEnabled = false);
        return;
      }

      await NotificationService.instance.scheduleDailyNotification(
        _reminderTime.hour,
        _reminderTime.minute,
      );
    } else {
      await NotificationService.instance.cancelAll();
    }

    setState(() => _masterEnabled = value);
    await _saveSetting('reminders_master', value);
  }

  // --- CUSTOM BOTTOM SHEET TIME PICKER ---
  void _showCustomTimePicker() {
    if (!_masterEnabled) return;

    int selectedHour = _reminderTime.hour;
    int selectedMinuteIndex = (_reminderTime.minute / 5).round().clamp(0, 11);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Time',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6D4C51),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour Picker
                      SizedBox(
                        height: 120,
                        width: 80,
                        child: CupertinoPicker(
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(initialItem: selectedHour),
                          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                            background: const Color(0xFFF06292).withValues(alpha: 0.1),
                          ),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedHour = index);
                          },
                          children: List.generate(24, (i) {
                            final isSelected = i == selectedHour;
                            return Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFFF06292) : const Color(0xFF333333),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          ':',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),

                      // Minute Picker
                      SizedBox(
                        height: 120,
                        width: 80,
                        child: CupertinoPicker(
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(initialItem: selectedMinuteIndex),
                          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                            background: const Color(0xFFF06292).withValues(alpha: 0.1),
                          ),
                          onSelectedItemChanged: (index) {
                            setModalState(() => selectedMinuteIndex = index);
                          },
                          children: List.generate(12, (i) {
                            final isSelected = i == selectedMinuteIndex;
                            final minuteValue = i * 5;
                            return Center(
                              child: Text(
                                minuteValue.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFFF06292) : const Color(0xFF333333),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: () async {
                            final selectedMinute = selectedMinuteIndex * 5;
                            final newTime = TimeOfDay(hour: selectedHour, minute: selectedMinute);

                            setState(() {
                              _reminderTime = newTime;
                            });

                            await _saveSetting('reminders_time_hour', selectedHour);
                            await _saveSetting('reminders_time_minute', selectedMinute);

                            // 🔥 ADD THIS PART (THIS IS STEP 5)
                            if (_masterEnabled) {
                              await NotificationService.instance.cancelAll();

                              await NotificationService.instance.scheduleDailyNotification(
                                _reminderTime.hour,
                                _reminderTime.minute,
                              );
                            }

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,)
                          )
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- REUSABLE UI COMPONENTS ---

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.pink.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildCustomSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: disabled ? Colors.grey.shade400 : Colors.grey,
                      fontSize: 13
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: disabled ? null : onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFFF06292),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeString = _reminderTime.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F6),
      appBar: AppBar(
        title: const Text('Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MASTER TOGGLE ---
            _buildCard(
              child: _buildCustomSwitchRow(
                title: 'Enable Reminders',
                subtitle: 'Turn on notifications for cycle tracking',
                value: _masterEnabled,
                onChanged: _handleMasterToggle, // Uses new permission handler
              ),
            ),
            const SizedBox(height: 24),

            // --- REMINDER TYPES ---
            Opacity(
              opacity: _masterEnabled ? 1.0 : 0.5,
              child: _buildCard(
                child: Column(
                  children: [
                    _buildCustomSwitchRow(
                      title: 'Period Reminder',
                      subtitle: 'Get notified before your next period',
                      value: _periodReminderEnabled,
                      disabled: !_masterEnabled,
                      onChanged: (bool value) {
                        setState(() => _periodReminderEnabled = value);
                        _saveSetting('reminders_period', value);
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.pink.withValues(alpha: 0.1),
                    ),
                    _buildCustomSwitchRow(
                      title: 'Logging Reminder',
                      subtitle: 'Reminds you to log your period',
                      value: _loggingReminderEnabled,
                      disabled: !_masterEnabled,
                      onChanged: (bool value) {
                        setState(() => _loggingReminderEnabled = value);
                        _saveSetting('reminders_logging', value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- TIME PICKER ---
            Opacity(
              opacity: _masterEnabled ? 1.0 : 0.5,
              child: _buildCard(
                child: InkWell(
                  onTap: _showCustomTimePicker,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF06292).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFF06292),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Reminder Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD36275),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}