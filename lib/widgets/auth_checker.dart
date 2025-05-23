import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  /// 提前加载认证状态，用于启动屏幕优化
  static Future<void> preload() async {
    // 这个方法会提前执行认证检查，以便在启动屏幕时预加载
    final rememberLogin = await AuthService.getRememberLoginSetting();

    // 仅当启用了记住登录状态时，才检查登录状态
    if (rememberLogin) {
      await AuthService.getLoginStatus();
    } else {
      // 未启用记住登录状态时，清除登录状态
      await AuthService.clearLoginStatus();
    }
  }

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 获取记住登录状态设置
    final rememberLogin = await AuthService.getRememberLoginSetting();

    // 仅当启用了记住登录状态时，才检查登录状态
    if (rememberLogin) {
      final status = await AuthService.getLoginStatus();
      setState(() => _isLoggedIn = status);
    } else {
      // 未启用记住登录状态时，清除登录状态
      await AuthService.clearLoginStatus();
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? const HomePage() : LoginPage();
  }
}
