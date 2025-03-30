import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/user_providers.dart';
import '../constants/app_constants.dart';

class MyPage extends HookConsumerWidget {
  const MyPage({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('确认退出？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  await AuthService.clearLoginStatus(); // 清除登录状态
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.loginRoute,
                      (route) => false,
                    );
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听用户信息
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) => _buildUserInfo(context, user, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '获取用户信息失败\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(text: error.toString()),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, user, WidgetRef ref) {
    // 如果用户为null，显示未登录状态
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('您尚未登录'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacementNamed(
                    context,
                    AppConstants.loginRoute,
                  ),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
    }

    // 显示用户信息
    return ListView(
      children: [
        // 用户头像和基本信息
        _buildUserHeader(context, user),

        // 分割线
        const Divider(height: 1),

        // 设置选项列表
        _buildSettingsList(context, ref),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      color: Theme.of(context).primaryColor.withAlpha(13),
      child: Column(
        children: [
          // 头像
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blueGrey,
            backgroundImage:
                user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl) as ImageProvider
                    : null,
            child:
                user.avatarUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
          ),
          const SizedBox(height: 16),

          // 用户名
          Text(user.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),

          // 邮箱
          Text(
            user.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),

          // 部门和职位
          if (user.department != null && user.position != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${user.department} · ${user.position}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 我参加的会议
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('我参加的会议'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.myMeetingsRoute);
          },
        ),

        // 个人信息设置
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('个人信息设置'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.profileSettingsRoute);
          },
        ),

        // 账号与安全
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('账号与安全'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.accountSecurityRoute);
          },
        ),

        // 通知设置
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('通知设置'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppConstants.notificationSettingsRoute,
            );
          },
        ),

        // 帮助中心
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('帮助中心'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.helpCenterRoute);
          },
        ),

        // 关于我们
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于我们'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.aboutRoute);
          },
        ),

        // 隐私政策
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('隐私政策'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushNamed(context, AppConstants.privacyPolicyRoute);
          },
        ),

        const SizedBox(height: 16),

        // 退出登录按钮
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingM,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              child: const Text('退出登录'),
            ),
          ),
        ),
      ],
    );
  }
}
