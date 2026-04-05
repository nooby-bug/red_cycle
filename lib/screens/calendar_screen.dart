import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/period_entry.dart';
import '../widgets/calendar/calendar_month_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<DateTime> _months = [];

  // 🔴 FIX 1: Use full PeriodEntry instead of DateTime
  List<PeriodEntry> _periods = [];
  bool _isLoading = true;

  static const double _monthItemHeight = 420.0;

  @override
  void initState() {
    super.initState();
    _generateMonths();
    _loadPeriods();
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

  Future<void> _loadPeriods() async {
    final List<PeriodEntry> data =
    await DatabaseHelper.instance.getAllPeriods();

    if (mounted) {
      setState(() {
        // 🔴 FIX 2: Keep full data (do NOT convert to DateTime)
        _periods = data;
        _isLoading = false;
      });

      final today = DateTime.now();

      final currentIndex = _months.indexWhere(
            (m) => m.year == today.year && m.month == today.month,
      );

      if (currentIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(currentIndex * _monthItemHeight);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                      periods: _periods, // 🔴 FIX 3: Pass full data
                    ),
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