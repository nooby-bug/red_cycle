import '../database/database_helper.dart';
import '../models/daily_log.dart';

class MoodPainService {
  MoodPainService._();
  static final MoodPainService instance = MoodPainService._();

  final _db = DatabaseHelper.instance;

  // ------------------ SAVE / UPDATE ------------------

  Future<void> saveLog({
    required DateTime date,
    required int mood,
    required int pain,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    await _db.insertOrUpdateLog({
      'date': normalizedDate.toIso8601String(),
      'mood': mood,
      'pain': pain,
    });
  }

  // ------------------ GET ALL ------------------

  Future<List<DailyLog>> getLogs() async {
    final data = await _db.getAllLogs();

    return data.map((map) => DailyLog.fromMap(map)).toList();
  }

  // ------------------ GET TODAY ------------------

  Future<DailyLog?> getTodayLog() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final data = await _db.getLogByDate(today);

    if (data != null) {
      return DailyLog.fromMap(data);
    }

    return null;
  }
}