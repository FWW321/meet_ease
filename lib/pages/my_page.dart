import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.clearLoginStatus(); // 清除登录状态
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('我的页面'),
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}