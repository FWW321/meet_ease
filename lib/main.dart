import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/auth_checker.dart';
import 'pages/login_page.dart';
import 'pages/my_meetings_page.dart';
import 'pages/profile_settings_page.dart';
import 'pages/account_security_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/help_center_page.dart';
import 'pages/about_page.dart';
import 'pages/privacy_policy_page.dart';
import 'configs/app_theme.dart';
import 'constants/app_constants.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 设置优选方向
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    debugPrint('初始化失败: $e\n$stackTrace');
    rethrow;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MeetEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthChecker(),
      routes: {
        AppConstants.loginRoute: (context) => const LoginPage(),
        AppConstants.myMeetingsRoute: (context) => const MyMeetingsPage(),
        AppConstants.profileSettingsRoute:
            (context) => const ProfileSettingsPage(),
        AppConstants.accountSecurityRoute:
            (context) => const AccountSecurityPage(),
        AppConstants.notificationSettingsRoute:
            (context) => const NotificationSettingsPage(),
        AppConstants.helpCenterRoute: (context) => const HelpCenterPage(),
        AppConstants.aboutRoute: (context) => const AboutPage(),
        AppConstants.privacyPolicyRoute: (context) => const PrivacyPolicyPage(),
      },
    );
  }
}
