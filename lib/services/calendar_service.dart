import '../models/period_entry.dart';

enum DayType {
  none,
  actualPeriod,
  predictedPeriod,
  ovulation,
  fertile,
}

class CalendarService {
  /// Determines the cycle phase (DayType) for a given calendar day.
  DayType getDayType({
    required DateTime day,
    required List<PeriodEntry> periods,
    required int cycleLength,
    required int periodLength,
  }) {
    if (periods.isEmpty) return DayType.none;

    final DateTime targetDay = _normalizeDate(day);

    // 1. ACTUAL PERIOD (highest priority)
    for (final entry in periods) {
      final DateTime start = _normalizeDate(entry.startDate);

      // Ongoing periods are only active up to 'today'
      final DateTime end = entry.endDate != null
          ? _normalizeDate(entry.endDate!)
          : _normalizeDate(DateTime.now());

      if (!targetDay.isBefore(start) && !targetDay.isAfter(end)) {
        return DayType.actualPeriod;
      }
    }

    // 2. FIND LATEST ENTRY
    final List<PeriodEntry> sortedPeriods = List.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final PeriodEntry latestEntry = sortedPeriods.last;
    final DateTime latestStart = _normalizeDate(latestEntry.startDate);

    // If before latest cycle → no prediction
    if (targetDay.isBefore(latestStart)) return DayType.none;

    // 3. PREDICTED PERIOD
    final DateTime nextPeriodStart =
    latestStart.add(Duration(days: cycleLength));

    final DateTime nextPeriodEnd =
    nextPeriodStart.add(Duration(days: periodLength - 1));

    // Check if any actual period overlaps with the predicted range
    bool overlapsActual = periods.any((entry) {
      final start = _normalizeDate(entry.startDate);

      if (start.isBefore(latestStart)) return false;

      final end = entry.endDate != null
          ? _normalizeDate(entry.endDate!)
          : _normalizeDate(DateTime.now());

      return !(end.isBefore(nextPeriodStart) || start.isAfter(nextPeriodEnd));
    });

    if (!overlapsActual &&
        !targetDay.isBefore(nextPeriodStart) &&
        !targetDay.isAfter(nextPeriodEnd)) {
      return DayType.predictedPeriod;
    }

    // 4. OVULATION & FERTILE WINDOW
    final int cycleDay = targetDay.difference(latestStart).inDays + 1;

    final int ovulationDay = cycleLength - 14;

    final int fertileStart = ovulationDay - 3;
    final int fertileEnd = ovulationDay + 1;

    if (cycleDay == ovulationDay) return DayType.ovulation;

    if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      return DayType.fertile;
    }

    return DayType.none;
  }

  /// Helper to normalize date (remove time)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}