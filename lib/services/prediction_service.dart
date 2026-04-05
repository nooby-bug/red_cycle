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

    final DateTime normalizedToday =
    DateTime(today.year, today.month, today.day);

    final List<PeriodEntry> sortedEntries = List.from(periodEntries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final PeriodEntry latestEntry = sortedEntries.first;

    final DateTime latestStart = DateTime(
        latestEntry.startDate.year,
        latestEntry.startDate.month,
        latestEntry.startDate.day);

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

    final DateTime latestEnd = DateTime(
        latestEntry.endDate!.year,
        latestEntry.endDate!.month,
        latestEntry.endDate!.day);

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
    latestStart.add(Duration(days: cycleLength));

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

    final int ovulationDay = cycleLength - 14;

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
}