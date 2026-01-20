import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Token management
  Future<void> saveAccessToken(String token) async {
    await _prefs.setString('access_token', token);
  }

  String? getAccessToken() {
    return _prefs.getString('access_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString('refresh_token', token);
  }

  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }

  // User data
  Future<void> saveUserId(String userId) async {
    await _prefs.setString('user_id', userId);
  }

  String? getUserId() {
    return _prefs.getString('user_id');
  }

  Future<void> saveCompanyId(String companyId) async {
    await _prefs.setString('company_id', companyId);
  }

  String? getCompanyId() {
    return _prefs.getString('company_id');
  }

  // Theme
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'system';
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Generic methods
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
