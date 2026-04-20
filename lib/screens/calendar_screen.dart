import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/period_entry.dart';
import '../widgets/calendar/calendar_month_view.dart';
import 'package:red/services/prediction_service.dart';
import 'package:red/models/prediction_data.dart';
import 'package:red/utils/user_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _months = [];
  int _cycleLength = 28;
  int _periodLength = 5;

  // 🔴 FIX 1: Use full PeriodEntry instead of DateTime
  List<PeriodEntry> _periods = [];
  bool _isLoading = true;

  static const double _monthItemHeight = 420.0;

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _loadPeriods();
    _loadPreferences();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToCurrentMonth();
    });
  }

  void _generateMonths() {
    final today = DateTime.now();
    final start = DateTime(today.year - 1, today.month);
    final end = DateTime(today.year + 1, today.month);

    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      _months.add(current);
      current = DateTime(current.year, current.month + 1);
    }
  }

  Future<void> _loadPreferences() async {
    final cycle = await UserPreferences.getCycleLength();
    final period = await UserPreferences.getPeriodLength();

    if (!mounted) return;

    setState(() {
      _cycleLength = cycle ?? 28;
      _periodLength = period ?? 5;
    });
  }

  Future<void> _loadPeriods() async {
    final List<PeriodEntry> data =
    await DatabaseHelper.instance.getAllPeriods();

    if (mounted) {
      setState(() {
        _periods = data;
        _isLoading = false;
      });
    }
  }

  void _scrollToCurrentMonth() {
    final today = DateTime.now();

    final currentIndex = _months.indexWhere(
          (m) => m.year == today.year && m.month == today.month,
    );

    if (currentIndex == -1) return;

    final offset = currentIndex * _monthItemHeight;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(offset);
    } else {
      // fallback retry (rare but important)
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  PredictionData? _getPrediction() {
    if (_periods.length < 2) return null;

    final predictionService = PredictionService();

    return predictionService.getPredictionData(
      periodEntries: _periods,
      cycleLength: _cycleLength, // ✅ dynamic
      today: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF48FB1),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon:
                    const Icon(Icons.close, color: Color(0xFF333333)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemExtent: _monthItemHeight,
                itemCount: _months.length,
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                      child: CalendarMonthView(
                        month: _months[index],
                        periods: _periods,
                        prediction: _getPrediction(),
                        periodLength: _periodLength, // ✅ dynamic now

                        onLogPeriod: (start, end) async {
                          await DatabaseHelper.instance.insertFullPeriod(start, end);
                          await _loadPeriods();
                        },

                        onDeletePeriod: (entry) async {
                          if (entry.id != null) {
                            await DatabaseHelper.instance.deletePeriod(entry.id!);
                            await _loadPeriods();

                          }
                        },
                      )
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}