class PredictionData {
  final DateTime nextPeriod;
  final DateTime ovulation;
  final DateTime fertileStart;
  final DateTime fertileEnd;

  PredictionData({
    required this.nextPeriod,
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
  });

  // ✅ ADD THIS
  factory PredictionData.empty() {
    final now = DateTime.now();

    return PredictionData(
      nextPeriod: now,
      ovulation: now,
      fertileStart: now,
      fertileEnd: now,
    );
  }
}