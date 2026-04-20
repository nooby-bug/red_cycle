///TODO ADD ANIMATIONS LIKE TAP TO RESPONSE
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/user_preferences.dart';
import '../../database/database_helper.dart';
import 'package:red/models/period_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red/services/notification_service.dart';
import 'package:red/services/prediction_service.dart';
import 'package:red/models/prediction_data.dart';

enum DayType {
  none,
  actualPeriod,
  predictedPeriod,
  ovulation,
  fertile,
}

class CalendarMonthView extends StatefulWidget {
  final DateTime month;

  const CalendarMonthView({
    super.key,
    required this.month,
  });

  @override
  State<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends State<CalendarMonthView> {
  // ------------------ STATE ------------------

  int _cycleLength = 28;
  int _periodLength = 5;
  List<PeriodEntry> _periods = [];
  PredictionData? _cachedPrediction;

  final PredictionService _predictionService = PredictionService();
  static final _monthFormat = DateFormat.yMMMM();

  // ------------------ INIT & DATA LOADING ------------------

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final cycle = await UserPreferences.getCycleLength() ?? 28;
    final period = await UserPreferences.getPeriodLength() ?? 5;
    final periods = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    setState(() {
      _cycleLength = cycle;
      _periodLength = period;
      _periods = periods..sort((a, b) => b.startDate.compareTo(a.startDate));
    });

    _updatePredictionCache();
  }

  Future<void> _reloadSettingsAndRecalculate() async {
    final cycle = await UserPreferences.getCycleLength() ?? 28;
    final period = await UserPreferences.getPeriodLength() ?? 5;

    if (!mounted) return;

    setState(() {
      _cycleLength = cycle;
      _periodLength = period;
    });

    _updatePredictionCache();
  }

  Future<void> _loadPeriods() async {
    final periods = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    setState(() {
      _periods = periods..sort((a, b) => b.startDate.compareTo(a.startDate));
      _updatePredictionCache();
    });
  }

  void _updatePredictionCache() {
    if (_periods.length < 2) {
      _cachedPrediction = null;
      return;
    }

    // Calculate prediction ONCE based on today's actual date
    _cachedPrediction = _predictionService.getPredictionData(
      periodEntries: _periods,
      cycleLength: _cycleLength,
      today: _periods.first.startDate,
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ------------------ DAY TYPE LOGIC ------------------

  DayType _getDayType(DateTime day) {
    final current = _normalize(day);

    // 1. Check Actual Period (Highest Priority)
    for (final entry in _periods) {
      final start = _normalize(entry.startDate);
      final end = _normalize(entry.endDate ?? entry.startDate);

      if (!current.isBefore(start) && !current.isAfter(end)) {
        return DayType.actualPeriod;
      }
    }

    if (_cachedPrediction == null) return DayType.none;

    // 2. Check Predicted Period
    final predStart = _normalize(_cachedPrediction!.nextPeriod);
    final predEnd = predStart.add(Duration(days: _periodLength - 1));

    bool overlapsActual = _periods.any((entry) {
      final start = _normalize(entry.startDate);
      final end = _normalize(entry.endDate ?? entry.startDate);

      return !(end.isBefore(predStart) || start.isAfter(predEnd));
    });

    if (!overlapsActual &&
        !current.isBefore(predStart) &&
        !current.isAfter(predEnd)) {
      return DayType.predictedPeriod;
    }

    // 3. Check Ovulation
    final ovulation = _normalize(_cachedPrediction!.ovulation);
    if (current.isAtSameMomentAs(ovulation)) {
      return DayType.ovulation;
    }

    // 4. Check Fertile Window
    final fertileStart = _normalize(_cachedPrediction!.fertileStart);
    final fertileEnd = _normalize(_cachedPrediction!.fertileEnd);

    if (!current.isBefore(fertileStart) && !current.isAfter(fertileEnd)) {
      return DayType.fertile;
    }

    // 5. None
    return DayType.none;
  }

  // ------------------ BUILD ------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            _monthFormat.format(widget.month),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: widget.month,
            rowHeight: 48,
            daysOfWeekHeight: 24,

            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),

            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.symmetric(vertical: 6),
              outsideDaysVisible: false,
            ),

            headerVisible: false,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.none,

            onDaySelected: (selectedDay, focusedDay) {
              _showDayDetails(context, selectedDay);
            },

            onDayLongPressed: (selectedDay, focusedDay) {
              _showAddPeriodSheet(context, selectedDay);
            },

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ------------------ INTERACTION ------------------

  void _showDayDetails(BuildContext context, DateTime day) {
    final type = _getDayType(day);

    String phaseText;
    switch (type) {
      case DayType.actualPeriod:
        phaseText = "Period";
        break;
      case DayType.predictedPeriod:
        phaseText = "Predicted Period";
        break;
      case DayType.ovulation:
        phaseText = "Ovulation";
        break;
      case DayType.fertile:
        phaseText = "Fertile Window";
        break;
      default:
        phaseText = "Safe Phase";
    }

    int? cycleDay;

    if (_periods.isNotEmpty) {
      final latestStart = _periods
          .map((e) => e.startDate)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      final normalizedStart = _normalize(latestStart);
      final diff = _normalize(day).difference(normalizedStart).inDays;

      if (diff >= 0) cycleDay = diff + 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd().format(day),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  phaseText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getPhaseColor(type),
                  ),
                ),
                const SizedBox(height: 8),
                if (cycleDay != null)
                  Text(
                    "Cycle Day $cycleDay",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPeriodSheet(
      BuildContext context,
      DateTime selectedDay, {
        bool isEdit = false,
        PeriodEntry? editingEntry,
      }) {
    PeriodEntry? existing;

    for (final entry in _periods) {
      final start = _normalize(entry.startDate);
      final end = _normalize(entry.endDate ?? entry.startDate);
      final target = _normalize(selectedDay);

      if (!target.isBefore(start) && !target.isAfter(end)) {
        existing = entry;
        break;
      }
    }

    if (!isEdit && existing != null) {
      _showEditOptions(context, existing);
      return;
    }

    DateTime startDate;
    DateTime endDate;

    if (isEdit && editingEntry != null) {
      startDate = editingEntry.startDate;
      endDate = editingEntry.endDate ?? editingEntry.startDate;
    } else {
      startDate = selectedDay;
      endDate = selectedDay.add(const Duration(days: 4));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Log Period",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Start Date
                  ListTile(
                    title: const Text("Start Date"),
                    trailing: Text(DateFormat.yMMMd().format(startDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setModalState(() {
                          startDate = picked;
                        });
                      }
                    },
                  ),

                  // End Date
                  ListTile(
                    title: const Text("End Date"),
                    trailing: Text(DateFormat.yMMMd().format(endDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setModalState(() {
                          endDate = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Save Logic
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);

                        DateTime newStart = startDate;
                        DateTime newEnd = endDate;
                        List<PeriodEntry> toRemove = [];

                        // Find overlapping periods
                        for (final entry in _periods) {
                          final existingStart = entry.startDate;
                          final existingEnd = entry.endDate ?? existingStart;

                          final overlaps = !(newEnd.isBefore(existingStart) || newStart.isAfter(existingEnd));

                          if (overlaps) {
                            if (existingStart.isBefore(newStart)) {
                              newStart = existingStart;
                            }
                            if (existingEnd.isAfter(newEnd)) {
                              newEnd = existingEnd;
                            }
                            toRemove.add(entry);
                          }
                        }

                        // Remove overlapping entries
                        for (final entry in toRemove) {
                          if (entry.id != null) {
                            await DatabaseHelper.instance.deletePeriod(entry.id!);
                          }
                        }

                        // Insert merged period
                        final id = await DatabaseHelper.instance.insertPeriod(newStart);
                        await DatabaseHelper.instance.endPeriod(id, newEnd);

                        // Refresh local UI data and prediction cache
                        await _loadPeriods();
                        final updatedHistory = _periods;
                        final prefs = await SharedPreferences.getInstance();

                        final hour = prefs.getInt('reminders_time_hour') ?? 8;
                        final minute = prefs.getInt('reminders_time_minute') ?? 0;

                        final periodEnabled = prefs.getBool('reminders_period') ?? false;
                        final loggingEnabled = prefs.getBool('reminders_logging') ?? false;

                        await NotificationService.instance.refreshAllReminders(
                          history: updatedHistory,
                          hour: hour,
                          minute: minute,
                          periodEnabled: periodEnabled,
                          loggingEnabled: loggingEnabled,
                        );

                        if (!mounted) return;
                        navigator.pop();
                      },
                      child: const Text("Save Period"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditOptions(BuildContext context, PeriodEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EDIT
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Period"),
                onTap: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _showAddPeriodSheet(
                    context,
                    entry.startDate,
                    isEdit: true,
                    editingEntry: entry,
                  );
                },
              ),

              // DELETE
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Period"),
                onTap: () async {
                  final navigator = Navigator.of(context);

                  if (entry.id != null) {
                    await DatabaseHelper.instance.deletePeriod(entry.id!);
                    await _loadPeriods(); // Refreshes UI and cache

                    final updatedHistory = _periods;
                    final prefs = await SharedPreferences.getInstance();

                    await NotificationService.instance.refreshAllReminders(
                      history: updatedHistory,
                      hour: prefs.getInt('reminders_time_hour') ?? 8,
                      minute: prefs.getInt('reminders_time_minute') ?? 0,
                      periodEnabled: prefs.getBool('reminders_period') ?? false,
                      loggingEnabled: prefs.getBool('reminders_logging') ?? false,
                    );
                  }

                  if (!mounted) return;
                  navigator.pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPhaseColor(DayType type) {
    switch (type) {
      case DayType.actualPeriod:
      case DayType.predictedPeriod:
        return const Color(0xFFD81B60);
      case DayType.fertile:
      case DayType.ovulation:
        return Colors.blue.shade700;
      default:
        return Colors.black87;
    }
  }

  // ------------------ UI BUILDERS ------------------

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final type = _getDayType(day);
    final isToday = isSameDay(day, DateTime.now());

    const pink = Color(0xFFF48FB1);
    const blue = Color(0xFFB3D9FF);

    Widget child;

    switch (type) {
      case DayType.actualPeriod:
        child = _filledCircle(day, pink, isToday: isToday);
        break;
      case DayType.predictedPeriod:
        child = _dottedCircle(day, pink, isToday: isToday);
        break;
      case DayType.ovulation:
        child = _filledCircle(day, blue, isToday: isToday);
        break;
      case DayType.fertile:
        child = _dottedCircle(day, blue, isToday: isToday);
        break;
      default:
        child = isToday ? _todayOnly(day) : _normalDay(day);
    }

    return GestureDetector(
      onTap: () => _showDayDetails(context, day),
      child: AnimatedScale(
        scale: isToday ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  Widget _filledCircle(DateTime day, Color color, {bool isToday = false}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: isToday ? Border.all(color: Colors.grey.shade400, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _dottedCircle(DateTime day, Color color, {bool isToday = false}) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: DottedCirclePainter(color),
        child: Container(
          alignment: Alignment.center,
          decoration: isToday
              ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
          )
              : null,
          child: Text(
            '${day.day}',
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _todayOnly(DateTime day) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade300,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _normalDay(DateTime day) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}

// ------------------ CUSTOM PAINTER ------------------

class DottedCirclePainter extends CustomPainter {
  final Color color;

  DottedCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.5;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width / 2) - (strokeWidth / 2);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const dashAngle = 0.25;
    const gapAngle = 0.18;

    double startAngle = 0;

    while (startAngle < 2 * math.pi) {
      canvas.drawArc(rect, startAngle, dashAngle, false, paint);
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}