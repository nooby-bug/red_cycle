import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:red/models/period_entry.dart';
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
  final List<PeriodEntry> periods;
  final PredictionData? prediction;
  final int periodLength;
  final void Function(DateTime start, DateTime end)? onLogPeriod;
  final void Function(PeriodEntry entry)? onDeletePeriod;

  const CalendarMonthView({
    super.key,
    required this.month,
    required this.periods,
    required this.prediction,
    this.periodLength = 5, // Default length for predicted periods
    this.onLogPeriod,
    this.onDeletePeriod,
  });

  @override
  State<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends State<CalendarMonthView> {
  static final _monthFormat = DateFormat.yMMMM();

  // ------------------ UTILITIES ------------------

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ------------------ DAY TYPE LOGIC ------------------

  DayType _getDayType(DateTime day) {
    final current = _normalize(day);

    // 1. Check Actual Period (Highest Priority)
    for (final entry in widget.periods) {
      final start = _normalize(entry.startDate);
      final end = _normalize(entry.endDate ?? entry.startDate);

      if (!current.isBefore(start) && !current.isAfter(end)) {
        return DayType.actualPeriod;
      }
    }

    // If not enough data or no prediction, return none
    if (widget.periods.length < 2 || widget.prediction == null) {
      return DayType.none;
    }

    final pred = widget.prediction!;

    // 2. Check Predicted Period (nextPeriod -> nextPeriod + periodLength - 1)
    final predStart = _normalize(pred.nextPeriod);
    final predEnd = predStart.add(Duration(days: widget.periodLength - 1));

    if (!current.isBefore(predStart) && !current.isAfter(predEnd)) {
      return DayType.predictedPeriod;
    }

    // 3. Check Ovulation
    final ovulation = _normalize(pred.ovulation);
    if (current.isAtSameMomentAs(ovulation)) {
      return DayType.ovulation;
    }

    // 4. Check Fertile Window (Inclusive range check)
    final fertileStart = _normalize(pred.fertileStart);
    final fertileEnd = _normalize(pred.fertileEnd);

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

    // Generate a unique key based on the data so TableCalendar rebuilds when data changes
    final String dataHash = widget.periods
        .map((e) => "${e.startDate.toIso8601String()}_${e.endDate?.toIso8601String()}")
        .join('|') +
        (widget.prediction?.nextPeriod.toIso8601String() ?? '');

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

    if (widget.periods.isNotEmpty) {
      final latestStart = widget.periods
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

    // Find if the selected day belongs to an existing period
    for (final entry in widget.periods) {
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
      endDate = selectedDay.add(Duration(days: widget.periodLength - 1));
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
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Delegate database and logic responsibilities to parent
                        widget.onLogPeriod?.call(startDate, endDate);
                        Navigator.pop(context);
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
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Period"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPeriodSheet(
                    context,
                    entry.startDate,
                    isEdit: true,
                    editingEntry: entry,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Period"),
                onTap: () {
                  // Delegate database and logic responsibilities to parent
                  widget.onDeletePeriod?.call(entry);
                  Navigator.pop(context);
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
    final isToday = _isSameDay(day, DateTime.now());

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