///TODO ADD ANIMATIONS LIKE TAP TO RESPONSE
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/calendar_service.dart';
import '../../utils/user_preferences.dart';
import '../../database/database_helper.dart';
import 'package:red/models/period_entry.dart';

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

  final CalendarService _calendarService = CalendarService();

  static final _monthFormat = DateFormat.yMMMM();

  // ------------------ INIT ------------------

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPeriods();
  }

  // ------------------ DATA LOADING ------------------

  Future<void> _loadSettings() async {
    final cycle = await UserPreferences.getCycleLength();
    final period = await UserPreferences.getPeriodLength();

    if (!mounted) return;

    setState(() {
      _cycleLength = cycle ?? 28;
      _periodLength = period ?? 5;
    });
  }

  Future<void> _loadPeriods() async {
    final periods = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    setState(() {
    _periods = periods..sort((a, b) => b.startDate.compareTo(a.startDate));
    });
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
    final type = _calendarService.getDayType(
      day: day,
      periods: _periods,
      cycleLength: _cycleLength,
      periodLength: _periodLength,
    );

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

      final normalizedStart =
      DateTime(latestStart.year, latestStart.month, latestStart.day);

      final diff = day.difference(normalizedStart).inDays;

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
    final type = _calendarService.getDayType(
      day: day,
      periods: _periods,
      cycleLength: _cycleLength,
      periodLength: _periodLength,
    );

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
          border:
          isToday ? Border.all(color: Colors.grey.shade400, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
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
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w500),
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
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87),
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