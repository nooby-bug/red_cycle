class DailyLog {
  final int? id;
  final DateTime date;
  final int mood; // 1–5
  final int pain; // 0–10

  DailyLog({
    this.id,
    required this.date,
    required this.mood,
    required this.pain,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'pain': pain,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mood: map['mood'],
      pain: map['pain'],
    );
  }
}