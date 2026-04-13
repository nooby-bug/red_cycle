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

import '../models/hero_state.dart';
import '../models/period_entry.dart';

class PredictionService {
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
    // SMART CYCLE LENGTH (AUTO / FALLBACK)
    // ------------------------------------------------------------
    int effectiveCycleLength = cycleLength;

    if (periodEntries.length >= 3) {
      final avg = calculateAverageCycleLength(periodEntries);

      if (avg > 10) {
        effectiveCycleLength = avg.round();
      }
    }

    final int cycleDay =
        normalizedToday.difference(latestStart).inDays + 1;

    // ------------------------------------------------------------------
    // ✅ ACTIVE PERIOD (ONGOING)
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

    // ------------------------------------------------------------------
    // ✅ COMPLETED PERIOD (STRICT RANGE CHECK)
    // ------------------------------------------------------------------
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

    // ✅ Late only AFTER expected date
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

    // ✅ FIXED fertile window
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
  // UTILITIES
  // --------------------------------------------------------------------------

  /// Strips the time from a DateTime to ensure flawless day-to-day comparisons.
  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calculates average cycle length using historical period data
  double calculateAverageCycleLength(List<PeriodEntry> periods) {
    if (periods.length < 2) {
      return 0.0;
    }

    final sortedPeriods = List<PeriodEntry>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final List<int> cycleLengths = [];

    for (int i = 0; i < sortedPeriods.length - 1; i++) {
      final DateTime day1 = _normalize(sortedPeriods[i].startDate);
      final DateTime day2 = _normalize(sortedPeriods[i + 1].startDate);

      final int length = day2.difference(day1).inDays;
      cycleLengths.add(length);
    }

    if (cycleLengths.isEmpty) {
      return 0.0;
    }

    final int sum = cycleLengths.reduce((a, b) => a + b);
    return sum / cycleLengths.length;
  }
}