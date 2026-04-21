import '../database/database_helper.dart';
import '../utils/user_preferences.dart';

class DataResetService {
  static Future<void> resetPeriods() async {
    await DatabaseHelper.instance.deleteAllPeriods();
  }

  static Future<void> resetPreferences() async {
    await UserPreferences.clearAll();
  }

  static Future<void> resetAll() async {
    await resetPeriods();
    await resetPreferences();
  }
}