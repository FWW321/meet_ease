import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/user_providers.dart';
import '../models/user.dart';

class ProfileSettingsPage extends HookConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('个人信息设置')),
      body: userAsync.when(
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
        data: (user) {
          if (user == null) {
            return const Center(child: Text('用户未登录'));
          }

          return _ProfileForm(user: user);
        },
      ),
    );
  }
}

class _ProfileForm extends HookConsumerWidget {
  final User user;

  const _ProfileForm({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 表单控制器
    final nameController = useTextEditingController(text: user.name);
    final emailController = useTextEditingController(text: user.email);
    final phoneController = useTextEditingController(
      text: user.phoneNumber ?? '',
    );

    // 表单验证状态
    final formKey = GlobalKey<FormState>();

    // 保存按钮状态
    final isSaving = useState(false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像设置
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage:
                            user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                        child:
                            user.avatarUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            // TODO: 实现更换头像功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('头像更换功能开发中')),
                            );
                          },
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 基本信息
            Text(
              '基本信息',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 姓名
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 邮箱
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 电话
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '电话',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    isSaving.value
                        ? null
                        : () async {
                          if (formKey.currentState!.validate()) {
                            isSaving.value = true;

                            // 构建更新后的用户信息
                            final updatedUser = user.copyWith(
                              name: nameController.text,
                              email: emailController.text,
                              phoneNumber:
                                  phoneController.text.isEmpty
                                      ? null
                                      : phoneController.text,
                            );

                            try {
                              // 更新用户信息
                              await ref
                                  .read(userNotifierProvider.notifier)
                                  .updateUser(updatedUser);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('个人信息更新成功')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('更新失败: $e')),
                                );
                              }
                            } finally {
                              isSaving.value = false;
                            }
                          }
                        },
                child:
                    isSaving.value
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
