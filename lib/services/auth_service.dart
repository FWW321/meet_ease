import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _authKey = 'is_logged_in';

  // 保存登录状态
  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, isLoggedIn);
  }

  // 获取登录状态
  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  // 清除登录状态
  static Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
  }
}