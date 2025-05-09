import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/user_providers.dart';

/// 用户条目组件
class UserTile extends HookConsumerWidget {
  final String userId;
  final String label;
  final bool canRemove;
  final VoidCallback? onRemove;
  final Color? labelColor;

  const UserTile({
    required this.userId,
    required this.label,
    required this.canRemove,
    required this.onRemove,
    this.labelColor,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用userNameProvider获取用户名，而不是整个用户信息
    final userNameAsync = ref.watch(userNameProvider(userId));

    return userNameAsync.when(
      data:
          (userName) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLabelColor(label).withAlpha(51),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(color: _getLabelColor(label)),
              ),
            ),
            title: Text(userName),
            subtitle: label == '创建者' ? const Text('会议创建者') : null,
            trailing:
                canRemove && onRemove != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '移除',
                      onPressed: onRemove,
                    )
                    : Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: _getLabelColor(label).withAlpha(25),
                      side: BorderSide(
                        color: _getLabelColor(label).withAlpha(128),
                      ),
                      labelStyle: TextStyle(color: _getLabelColor(label)),
                    ),
          ),
      loading:
          () => ListTile(
            leading: const CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: const Text('加载中...'),
            trailing: Chip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              backgroundColor: _getLabelColor(label).withAlpha(25),
            ),
          ),
      error:
          (_, __) => ListTile(
            leading: CircleAvatar(
              backgroundColor: _getLabelColor(label).withAlpha(51),
              child: Text('?', style: TextStyle(color: _getLabelColor(label))),
            ),
            title: Text('用户 $userId'),
            trailing:
                canRemove && onRemove != null
                    ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: '移除',
                      onPressed: onRemove,
                    )
                    : Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      backgroundColor: _getLabelColor(label).withAlpha(25),
                      side: BorderSide(
                        color: _getLabelColor(label).withAlpha(128),
                      ),
                      labelStyle: TextStyle(color: _getLabelColor(label)),
                    ),
          ),
    );
  }

  // 根据标签获取颜色
  Color _getLabelColor(String label) {
    // 如果提供了自定义颜色，优先使用自定义颜色
    if (labelColor != null) {
      return labelColor!;
    }

    switch (label) {
      case '创建者':
        return Colors.orange;
      case '管理员':
        return Colors.blue;
      case '已封禁':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
