import 'package:shared_preferences/shared_preferences.dart';

/// 应用常量
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  /// API相关
  static String apiDomain = 'fwwhub.fun:8080'; // Android模拟器访问主机的特殊IP
  static String get apiBaseUrl => 'http://$apiDomain/api';
  static const int apiTimeout = 10000; // 毫秒

  /// 更新服务器地址并保存到本地存储
  static Future<void> updateApiDomain(String newDomain) async {
    apiDomain = newDomain;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_domain', newDomain);
  }

  /// 从本地存储加载服务器地址
  static Future<void> loadApiDomain() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDomain = prefs.getString('api_domain');
    if (savedDomain != null && savedDomain.isNotEmpty) {
      apiDomain = savedDomain;
    }
  }

  /// 缓存相关
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_info';
  static const String rememberLoginKey = 'remember_login';

  /// 路由名称
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String meetingRoute = '/meeting';
  static const String myMeetingsRoute = '/my-meetings';
  static const String meetingListRoute = '/meeting-list';
  static const String profileSettingsRoute = '/profile-settings';
  static const String accountSecurityRoute = '/account-security';
  static const String notificationSettingsRoute = '/notification-settings';
  static const String helpCenterRoute = '/help-center';
  static const String aboutRoute = '/about';
  static const String privacyPolicyRoute = '/privacy-policy';
  static const String createMeetingRoute = '/create-meeting';
  static const String meetingDetailRoute = '/meeting-detail';
  static const String iconGeneratorRoute = '/icon-generator';

  /// 动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  /// 边距
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  /// 圆角
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  /// 图标路径
  static const String appIconPath = 'assets/images/app_icon.png';
  static const String appLogoPath = 'assets/images/app_logo.png';
}
