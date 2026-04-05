import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/period_entry.dart';
import '../models/hero_state.dart';
import 'package:red/services/prediction_service.dart';
import '../widgets/home/cycle_hero_card.dart';
import '../widgets/home/date_strip.dart';
import '../widgets/home/prediction_summary.dart';
import '../widgets/home/top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<PeriodEntry> _periodEntries = [];
  bool _isLoading = true;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPeriods();
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
    }
  }

  Future<void> _loadPeriods() async {
    final existing = await DatabaseHelper.instance.getAllPeriods();

    // if (existing.isEmpty) {
    //   await DatabaseHelper.instance.insertPeriod(
    //     _today.subtract(const Duration(days: 20)),
    //   );
    // }

    final data = await DatabaseHelper.instance.getAllPeriods();

    if (mounted) {
      setState(() {
        _periodEntries = data..sort((a, b) => b.startDate.compareTo(a.startDate));
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogPeriod() async {
    final activeEntry = _periodEntries.firstWhere(
          (entry) => entry.endDate == null,
      orElse: () => PeriodEntry(startDate: DateTime(0)),
    );

    if (activeEntry.startDate.year != 0) {
      if (activeEntry.id != null) {
        await DatabaseHelper.instance.endPeriod(activeEntry.id!, _today);
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF48FB1))),
      );
    }

    final bool isPeriodActive = _periodEntries.any((entry) => entry.endDate == null);

    final predictionService = PredictionService();

    final heroState = predictionService.getHeroState(
      periodEntries: _periodEntries,
      cycleLength: 28,
      defaultPeriodLength: 5, // <-- THE FIX IS HERE
      today: _today,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                const SizedBox(height: 16),
                TopBar(today: _today),
                const SizedBox(height: 32),

                CycleHeroCard(
                  state: heroState,
                  isPeriodActive: isPeriodActive,
                  onLogPeriod: _handleLogPeriod,
                ),

                const SizedBox(height: 32),
                const DateStrip(),
                const SizedBox(height: 32),
                const PredictionSummary(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}