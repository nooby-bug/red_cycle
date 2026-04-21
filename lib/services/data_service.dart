import 'package:red/database/database_helper.dart';
import 'package:red/utils/user_preferences.dart';

class DataService {
  static Future<void> resetPeriods() async {
    await DatabaseHelper.instance.clearAllData();
  }

  static Future<void> resetPreferences() async {
    await UserPreferences.saveCycleLength(28);
    await UserPreferences.savePeriodLength(5);
  }

  static Future<void> resetAllData() async {
    await resetPeriods();
    await resetPreferences();
  }
}