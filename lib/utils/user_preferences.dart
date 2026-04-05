import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyName = 'user_name';
  static const String _keyBirthdate = 'user_birthdate';

  // Save name
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  // Get name
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // Save birthdate
  static Future<void> saveBirthdate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBirthdate, date.toIso8601String());
  }

  // Get birthdate
  static Future<DateTime?> getBirthdate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateString = prefs.getString(_keyBirthdate);

    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }
}