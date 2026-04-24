import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AffirmationService {
  AffirmationService._privateConstructor();
  static final AffirmationService instance =
  AffirmationService._privateConstructor();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _keyAffirmations = 'affirmation_list';
  static const String _keyFrequency = 'affirmation_frequency';
  static const String _keyEnabled = 'affirmation_enabled';

  // ------------------ AFFIRMATIONS ------------------

  Future<List<String>> getAffirmations() async {
    final jsonString = _prefs.getString(_keyAffirmations);

    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((e) => e.toString()).toList();
  }

  Future<bool> _saveAffirmations(List<String> list) async {
    final jsonString = jsonEncode(list);
    return await _prefs.setString(_keyAffirmations, jsonString);
  }

  Future<bool> addAffirmation(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return false;

    final list = await getAffirmations();

    if (!list.contains(clean)) {
      list.add(clean);
      return await _saveAffirmations(list);
    }

    return true;
  }

  Future<bool> deleteAffirmationByIndex(int index) async {
    final list = await getAffirmations();

    if (index < 0 || index >= list.length) return false;

    list.removeAt(index);
    return await _saveAffirmations(list);
  }

  // ------------------ FREQUENCY ------------------

  Future<bool> saveFrequency(int value) async {
    final safe = value.clamp(1, 10);
    return await _prefs.setInt(_keyFrequency, safe);
  }

  Future<int> getFrequency() async {
    return _prefs.getInt(_keyFrequency) ?? 5;
  }

  // ------------------ TOGGLE ------------------

  Future<bool> saveToggle(bool value) async {
    return await _prefs.setBool(_keyEnabled, value);
  }

  Future<bool> getToggle() async {
    return _prefs.getBool(_keyEnabled) ?? false;
  }

  // ------------------ CLEAR ------------------

  Future<void> clearAll() async {
    await _prefs.remove(_keyAffirmations);
    await _prefs.remove(_keyFrequency);
    await _prefs.remove(_keyEnabled);
  }
}