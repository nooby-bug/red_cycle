class PeriodEntry {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;

  PeriodEntry({
    this.id,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  factory PeriodEntry.fromMap(Map<String, dynamic> map) {
    return PeriodEntry(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
    );
  }

  // Optional: Keeping copyWith for robust state manipulation later if needed
  PeriodEntry copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PeriodEntry(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}