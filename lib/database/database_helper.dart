import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/period_entry.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mycycle.db');
    return _database!;
  }

  Future<int> insertFullPeriod(DateTime start, DateTime end) async {
    final db = await instance.database;

    return await db.insert(
      'period_entries',
      {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE period_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_date TEXT NOT NULL,
        end_date TEXT
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // CRUD OPERATIONS
  // ---------------------------------------------------------------------------


  /// Fetches all periods sorted by the most recent start date (DESC).
  Future<List<PeriodEntry>> getAllPeriods() async {
    try {
      final db = await instance.database;

      final result = await db.query(
        'period_entries',
        orderBy: 'start_date DESC',
      );

      return result.map((map) => PeriodEntry.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch periods: $e');
    }
  }

  Future<int> insertPeriod(DateTime date) async {
    // fallback: treat as 1-day period
    return await insertFullPeriod(date, date);
  }

  Future<void> deleteAllPeriods() async {
    final db = await database;
    await db.delete('period_entries'); // ✅ correct table
  }

  Future<void> endPeriod(int id, DateTime endDate) async {
    final db = await database;

    final result = await db.query(
      'period_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return;

    final entry = PeriodEntry.fromMap(result.first);

    // Replace with full period update
    await db.update(
      'period_entries',
      {
        'start_date': entry.startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a specific period entry by its ID.
  Future<int> deletePeriod(int id) async {
    try {
      final db = await instance.database;

      return await db.delete(
        'period_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete period: $e');
    }
  }

  /// Clears all data from the database.
  Future<void> clearAllData() async {
    try {
      final db = await instance.database;
      await db.delete('period_entries');
    } catch (e) {
      throw Exception('Failed to clear database: $e');
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}