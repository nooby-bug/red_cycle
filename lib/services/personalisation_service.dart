import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationService {
  static const _keyName = 'user_name';
  static const _keyAccent = 'accent_color';

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> saveAccent(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccent, colorValue);
  }

  static Future<int?> getAccent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAccent);
  }
}