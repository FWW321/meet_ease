/// 应用常量
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  /// API相关
  static const String apiBaseUrl = 'https://api.meetease.com';
  static const int apiTimeout = 10000; // 毫秒

  /// 缓存相关
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_info';

  /// 路由名称
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String meetingRoute = '/meeting';
  static const String myMeetingsRoute = '/my_meetings';
  static const String profileSettingsRoute = '/profile_settings';
  static const String accountSecurityRoute = '/account_security';
  static const String notificationSettingsRoute = '/notification_settings';
  static const String helpCenterRoute = '/help_center';
  static const String aboutRoute = '/about';
  static const String privacyPolicyRoute = '/privacy_policy';
  static const String createMeetingRoute = '/create_meeting';
  static const String meetingDetailRoute = '/meeting_detail';

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
}
