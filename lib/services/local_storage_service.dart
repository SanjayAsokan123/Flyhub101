import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static Future<void> saveUserDetails({
    required String userId,
    required String name,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('name', name);
    await prefs.setString('role', role);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}