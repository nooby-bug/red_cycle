import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/period_entry.dart';
import '../models/hero_state.dart';
import 'package:red/services/prediction_service.dart';
import '../widgets/home/cycle_hero_card.dart';
import '../widgets/home/date_strip.dart';
import '../widgets/home/prediction_summary.dart';
import '../widgets/home/top_bar.dart';
import '../utils/user_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<PeriodEntry> _periodEntries = [];
  bool _isLoading = true;
  DateTime _today = DateTime.now();

  int _cycleLength = 28;
  int _periodLength = 5;

  final PredictionService _predictionService = PredictionService();

  void _handleReturnFromSettings() {
    _loadSettings();
    _loadPeriods(); // ✅ FIX: refresh data when returning
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPeriods();
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _today = DateTime.now();
      });

      _loadPeriods(); // ✅ FIX: refresh when app resumes
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)}";
  }

  String _formatRange(DateTime start, DateTime end) {
    return "${start.day}–${end.day} ${_monthName(end.month)}";
  }

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
    final data = await DatabaseHelper.instance.getAllPeriods();

    if (!mounted) return;

    setState(() {
      _periodEntries =
      data..sort((a, b) => b.startDate.compareTo(a.startDate));
      _isLoading = false;
    });
  }
  Future<void> _refreshData() async {
    await _loadSettings();
    await _loadPeriods();

    // optional smoothness
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _handleLogPeriod() async {
    final activeEntry = _periodEntries.firstWhere(
          (entry) => entry.endDate == null,
      orElse: () => PeriodEntry(startDate: DateTime(0)),
    );

    if (activeEntry.startDate.year != 0) {
      if (activeEntry.id != null) {
        await DatabaseHelper.instance.endPeriod(
            activeEntry.id!, _today);
      }
    } else {
      final alreadyExists = _periodEntries.any((entry) =>
      entry.startDate.year == _today.year &&
          entry.startDate.month == _today.month &&
          entry.startDate.day == _today.day);

      if (!alreadyExists) {
        await DatabaseHelper.instance.insertPeriod(_today);
      }
    }

    await _loadPeriods();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF48FB1)),
        ),
      );
    }

    final bool isPeriodActive =
    _periodEntries.any((entry) => entry.endDate == null);

// ✅ USE class-level instance
    final prediction = _predictionService.getPredictionData(
      periodEntries: _periodEntries,
      cycleLength: _cycleLength,
      today: _today,
    );

    final heroState = _predictionService.getHeroState(
      periodEntries: _periodEntries,
      cycleLength: _cycleLength,
      defaultPeriodLength: _periodLength,
      today: _today,
    );

    String nextPeriodStr = "--";
    String ovulationStr = "--";
    String fertileStr = "--";

    if (_periodEntries.length >= 2) {
      nextPeriodStr = _formatDate(prediction.nextPeriod);
      ovulationStr = _formatDate(prediction.ovulation);
      fertileStr = _formatRange(
        prediction.fertileStart,
        prediction.fertileEnd,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFFF48FB1),

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // 🔥 IMPORTANT
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                TopBar(
                  today: _today,
                  onReturn: _handleReturnFromSettings,
                ),

                const SizedBox(height: 32),

                CycleHeroCard(
                  state: heroState,
                  isPeriodActive: isPeriodActive,
                  onLogPeriod: _handleLogPeriod,
                ),

                const SizedBox(height: 32),

                const DateStrip(),

                const SizedBox(height: 32),

                PredictionSummary(
                  nextPeriodDate: nextPeriodStr,
                  ovulationDate: ovulationStr,
                  fertileWindow: fertileStr,
                ),

                const SizedBox(height: 40),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}