import 'package:flutter/material.dart';
import 'widgets/auth_checker.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保插件初始化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthChecker(),
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}