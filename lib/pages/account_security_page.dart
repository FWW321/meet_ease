import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_constants.dart';
import '../services/service_providers.dart' as service_providers;
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../providers/user_providers.dart';
import 'dart:developer' as developer;

class AccountSecurityPage extends HookConsumerWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号与安全')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 更改密码
          _buildSection(
            context,
            title: '密码管理',
            children: [
              ListTile(
                title: const Text('修改密码'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangePasswordDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 登录安全
          _buildSection(
            context,
            title: '登录安全',
            children: [
              SwitchListTile(
                title: const Text('记住登录状态'),
                subtitle: const Text('开启后，应用将在您下次打开时自动登录'),
                value: true, // 应当从用户偏好设置中获取实际值
                onChanged: (value) {
                  // TODO: 实现记住登录状态功能
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('记住登录状态${value ? '已开启' : '已关闭'}')),
                  );
                },
              ),

              SwitchListTile(
                title: const Text('生物识别登录'),
                subtitle: const Text('使用指纹或面部识别快速登录'),
                value: false, // 应当从用户偏好设置中获取实际值
                onChanged: (value) {
                  // TODO: 实现生物识别登录功能
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('生物识别登录功能开发中')));
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 账号管理
          _buildSection(
            context,
            title: '账号管理',
            children: [
              ListTile(
                title: const Text('注销账号'),
                textColor: Colors.red,
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red,
                ),
                onTap: () => _showDeactivateAccountDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建分区
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }

  // 修改密码对话框
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // 表单验证状态
    final formKey = GlobalKey<FormState>();

    // 获取用户服务
    final userService = ref.read(service_providers.userServiceProvider);

    // 加载状态
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('修改密码'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: '当前密码',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入当前密码';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: newPasswordController,
                            decoration: const InputDecoration(
                              labelText: '新密码',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入新密码';
                              }
                              if (value.length < 6) {
                                return '密码长度至少为6位';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: '确认新密码',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请确认新密码';
                              }
                              if (value != newPasswordController.text) {
                                return '两次输入的密码不一致';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    // 获取当前用户
                                    final currentUser =
                                        await userService.getCurrentUser();
                                    if (currentUser == null) {
                                      throw Exception('未获取到用户信息，请重新登录');
                                    }

                                    // 调用密码修改API
                                    final success = await userService
                                        .updatePassword(
                                          currentUser.id,
                                          currentPasswordController.text,
                                          newPasswordController.text,
                                        );

                                    if (success) {
                                      // 关闭对话框
                                      Navigator.of(context).pop();

                                      try {
                                        // 显示成功提示
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('密码修改成功，请重新登录'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        // 先清除本地登录状态
                                        await AuthService.clearLoginStatus();

                                        // 使用Riverpod清除用户状态
                                        await ref
                                            .read(authStateProvider.notifier)
                                            .logout();

                                        // 确保上下文有效，立即跳转到登录页面
                                        if (context.mounted) {
                                          // 返回到登录页面，清除所有路由历史
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            AppConstants.loginRoute,
                                            (route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        developer.log(
                                          '退出登录时出错: ${e.toString()}',
                                        );
                                        // 确保即使出错也返回登录页面
                                        if (context.mounted) {
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            AppConstants.loginRoute,
                                            (route) => false,
                                          );
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    // 显示错误信息
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('密码修改失败：${e.toString()}'),
                                      ),
                                    );
                                  } finally {
                                    // 更新加载状态
                                    if (context.mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('确认修改'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 注销账号对话框
  void _showDeactivateAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('注销账号', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '警告：账号注销后将无法恢复，所有数据将被永久删除。',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('请输入密码确认注销操作：'),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 实现注销账号功能
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('账号注销功能开发中')));
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('确认注销'),
              ),
            ],
          ),
    );
  }
}
