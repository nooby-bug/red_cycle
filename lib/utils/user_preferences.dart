import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyName = 'user_name';
  static const String _keyBirthdate = 'user_birthdate';
  static const String _keyCycleLength = 'user_cycle_length';
  static const String _keyPeriodLength = 'user_period_length';

  // --- NAME ---
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // --- BIRTHDATE ---
  static Future<void> saveBirthdate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBirthdate, date.toIso8601String());
  }

  static Future<DateTime?> getBirthdate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_keyBirthdate);

    if (dateString != null && dateString.isNotEmpty) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }

  // --- CYCLE LENGTH ---
  static Future<void> saveCycleLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCycleLength, value);
  }

  static Future<int?> getCycleLength() async {
    final prefs = await SharedPreferences.getInstance();
    // Returns 28 as the default value if no data is found
    return prefs.getInt(_keyCycleLength) ?? 28;
  }

  // --- PERIOD LENGTH ---
  static Future<void> savePeriodLength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPeriodLength, value);
  }

  static Future<int?> getPeriodLength() async {
    final prefs = await SharedPreferences.getInstance();
    // Returns 5 as the default value if no data is found
    return prefs.getInt(_keyPeriodLength) ?? 5;
  }
}