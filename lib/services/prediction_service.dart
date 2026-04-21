// ---------------------------------------------------------------------------
// TODO: SMART CYCLE PREDICTION (FUTURE IMPROVEMENT)
//
// Currently:
// - App uses user-defined cycleLength & periodLength (manual input)
//
// Future upgrade:
// - Calculate average cycle length from past PeriodEntry data
// - Use historical cycles to improve prediction accuracy
//
// Example:
// - Cycle lengths: 28, 30, 27 → avg ≈ 28.3
//
// Planned improvements:
// - `calculateAverageCycleLength(List<PeriodEntry>)`
// - handle irregular cycles
// - weighted averaging (recent cycles more important)
// - confidence scoring for predictions
//
// NOTE:
// Do NOT implement until base system is fully stable.
// ---------------------------------------------------------------------------

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/hero_state.dart';
import '../models/period_entry.dart';
import 'package:red/models/prediction_data.dart';

class PredictionService {

  String getCurrentPhase({
    required List<PeriodEntry> periodEntries,
    required int cycleLength,
    required DateTime today,
  }) {
    if (periodEntries.length < 2) return "unknown";

    // sort ascending
    final sorted = List<PeriodEntry>.from(periodEntries)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final lastStart = sorted.last.startDate;

    final day = today.difference(lastStart).inDays;

    if (day < 0) return "unknown";

    if (day <= 4) return "period";
    if (day <= 12) return "follicular";
    if (day <= 16) return "ovulation";
    return "luteal";
  }

  PredictionData getPredictionData({
    required List<PeriodEntry> periodEntries,
    required int cycleLength,
    required DateTime today,
  }) {
    if (periodEntries.length < 2) {
      return PredictionData.empty();
    }

    final sorted = List<PeriodEntry>.from(periodEntries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final latestStart = _normalize(sorted.first.startDate);

    int effectiveCycleLength = cycleLength;

    if (periodEntries.length >= 3) {
      final result = _calculateSmartCycle(periodEntries);
      if (result.avg > 10) {
        effectiveCycleLength = result.avg.round();
      }
    }

    final nextPeriod =
    latestStart.add(Duration(days: effectiveCycleLength));

    final ovulation = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulation.subtract(const Duration(days: 2));
    final fertileEnd = ovulation.add(const Duration(days: 2));

    return PredictionData(
      nextPeriod: nextPeriod,
      ovulation: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
    );
  }

  HeroState getHeroState({
    required List<PeriodEntry> periodEntries,
    required int cycleLength,
    required int defaultPeriodLength,
    required DateTime today,
  }) {
    if (periodEntries.isEmpty) {
      return const HeroState(
        primaryText: "Log your first period",
        secondaryText: "",
        infoText: "",
        showLogButton: true,
      );
    }

    final DateTime normalizedToday = _normalize(today);

    final List<PeriodEntry> sortedEntries = List.from(periodEntries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final PeriodEntry latestEntry = sortedEntries.first;
    final DateTime latestStart = _normalize(latestEntry.startDate);

    // ------------------------------------------------------------
    // 🔥 SMART CYCLE LENGTH
    // ------------------------------------------------------------
    int effectiveCycleLength = cycleLength;

    if (periodEntries.length >= 3) {
      final result = _calculateSmartCycle(periodEntries);

      if (result.avg > 10)   {
        effectiveCycleLength = result.avg.round();
      }

      debugPrint("📈 SMART AVG: ${result.avg}");
      debugPrint("🎯 CONFIDENCE: ${(result.confidence * 100).toStringAsFixed(1)}%");
    }

    final int cycleDay =
        normalizedToday.difference(latestStart).inDays + 1;

    // ------------------------------------------------------------------
    // ACTIVE PERIOD
    // ------------------------------------------------------------------
    if (latestEntry.endDate == null &&
        !normalizedToday.isBefore(latestStart)) {
      final int periodDay =
          normalizedToday.difference(latestStart).inDays + 1;

      return HeroState(
        primaryText: "Day $periodDay of period",
        secondaryText: "Period",
        infoText: "",
        showLogButton: true,
      );
    }

    final DateTime latestEnd = _normalize(latestEntry.endDate!);

    if (!normalizedToday.isBefore(latestStart) &&
        !normalizedToday.isAfter(latestEnd)) {
      final int periodDay =
          normalizedToday.difference(latestStart).inDays + 1;

      return HeroState(
        primaryText: "Day $periodDay of period",
        secondaryText: "Period",
        infoText: "",
        showLogButton: true,
      );
    }

    // ------------------------------------------------------------------
    // PREDICTIONS
    // ------------------------------------------------------------------

    final DateTime nextPeriodDate =
    latestStart.add(Duration(days: effectiveCycleLength));

    if (normalizedToday.isAfter(nextPeriodDate)) {
      final int daysLate =
          normalizedToday.difference(nextPeriodDate).inDays;

      return HeroState(
        primaryText: "Late by $daysLate days",
        secondaryText: "",
        infoText: "",
        showLogButton: true,
      );
    }

    final int daysRemaining =
        nextPeriodDate.difference(normalizedToday).inDays;

    final int ovulationDay = effectiveCycleLength - 14;

    final int fertileStart = ovulationDay - 3;
    final int fertileEnd = ovulationDay + 1;

    String phase;

    if (cycleDay == ovulationDay) {
      phase = "Ovulation";
    } else if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      phase = "Fertile Window";
    } else {
      phase = "Safe Phase";
    }

    return HeroState(
      primaryText: "Day $cycleDay of cycle",
      secondaryText: phase,
      infoText: "Next period in $daysRemaining days",
      showLogButton: true,
    );
  }

  // --------------------------------------------------------------------------
  // 🔥 SMART CYCLE ENGINE
  // --------------------------------------------------------------------------

  _SmartResult _calculateSmartCycle(List<PeriodEntry> periods) {
    final sorted = List<PeriodEntry>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    List<int> lengths = [];

    for (int i = 0; i < sorted.length - 1; i++) {
      final int diff = _normalize(sorted[i + 1].startDate)
          .difference(_normalize(sorted[i].startDate))
          .inDays;

      // 🔥 OUTLIER FILTER
      if (diff >= 21 && diff <= 45) {
        lengths.add(diff);
      } else {
        debugPrint("⛔ Ignored outlier: $diff days");
      }
    }

    if (lengths.isEmpty) {
      return _SmartResult(avg: 28, confidence: 0.3);
    }

    // 🔥 WEIGHTED AVERAGE
    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < lengths.length; i++) {
      final weight = i + 1; // recent = higher weight
      weightedSum += lengths[i] * weight;
      totalWeight += weight;
    }

    final avg = weightedSum / totalWeight;

    final confidence = _calculateConfidence(lengths);

    return _SmartResult(avg: avg, confidence: confidence);
  }

  double _calculateConfidence(List<int> lengths) {
    if (lengths.length < 2) return 0.3;

    final mean = lengths.reduce((a, b) => a + b) / lengths.length;

    double variance = 0;
    for (final l in lengths) {
      variance += pow(l - mean, 2);
    }

    variance /= lengths.length;

    final stdDev = sqrt(variance);

    final confidence = (1 / (1 + stdDev)).clamp(0.0, 1.0);

    return confidence;
  }

  // --------------------------------------------------------------------------
  // UTILITIES
  // --------------------------------------------------------------------------

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

// --------------------------------------------------------------------------
// HELPER CLASS
// --------------------------------------------------------------------------

class _SmartResult {
  final double avg;
  final double confidence;

  _SmartResult({
    required this.avg,
    required this.confidence,
  });
}