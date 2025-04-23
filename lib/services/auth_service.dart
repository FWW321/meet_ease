import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

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

  // 保存"记住登录状态"设置
  static Future<void> saveRememberLoginSetting(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.rememberLoginKey, remember);
  }

  // 获取"记住登录状态"设置
  static Future<bool> getRememberLoginSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.rememberLoginKey) ?? true; // 默认为true
  }
}
