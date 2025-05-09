import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/my_meetings_page.dart';
import 'pages/meeting_list_page.dart';
import 'pages/profile_settings_page.dart';
import 'pages/account_security_page.dart';
import 'pages/notification_settings_page.dart';
import 'pages/help_center_page.dart';
import 'pages/about_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/create_meeting_page.dart';
import 'pages/meeting_detail/meeting_detail_page.dart';
import 'pages/splash_screen.dart';
import 'pages/icon_generator_page.dart';
import 'configs/app_theme.dart';
import 'constants/app_constants.dart';
import 'utils/time_utils.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 加载保存的服务器地址
    await AppConstants.loadApiDomain();

    // 初始化时区数据
    await TimeUtils.initialize();

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
      home: const SplashScreen(),
      routes: {
        AppConstants.loginRoute: (context) => const LoginPage(),
        AppConstants.registerRoute: (context) => const RegisterPage(),
        AppConstants.myMeetingsRoute: (context) => const MyMeetingsPage(),
        AppConstants.meetingListRoute: (context) => const MeetingListPage(),
        AppConstants.profileSettingsRoute:
            (context) => const ProfileSettingsPage(),
        AppConstants.accountSecurityRoute:
            (context) => const AccountSecurityPage(),
        AppConstants.notificationSettingsRoute:
            (context) => const NotificationSettingsPage(),
        AppConstants.helpCenterRoute: (context) => const HelpCenterPage(),
        AppConstants.aboutRoute: (context) => const AboutPage(),
        AppConstants.privacyPolicyRoute: (context) => const PrivacyPolicyPage(),
        AppConstants.createMeetingRoute: (context) => const CreateMeetingPage(),
        AppConstants.iconGeneratorRoute: (context) => const IconGeneratorPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppConstants.meetingDetailRoute) {
          final meetingId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => MeetingDetailPage(meetingId: meetingId),
          );
        }
        return null;
      },
    );
  }
}
