import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/user_providers.dart';

/// 用户选择卡片组件
class UsersSelectionCard extends ConsumerWidget {
  final List<String> selectedUserIds;
  final VoidCallback onUserSelectionPressed;

  const UsersSelectionCard({
    super.key,
    required this.selectedUserIds,
    required this.onUserSelectionPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '参与用户',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(selectedUserIds.isEmpty ? '选择用户' : '修改选择'),
                  onPressed: onUserSelectionPressed,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 只在有选择用户时显示用户信息区域
            if (selectedUserIds.isNotEmpty) _buildSelectedUsersInfo(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUsersInfo(WidgetRef ref) {
    final currentUserIdAsync = ref.watch(currentLoggedInUserIdProvider);

    return currentUserIdAsync.when(
      data: (currentUserId) {
        // 过滤掉当前用户
        final actualSelectedCount =
            selectedUserIds.where((id) => id != currentUserId).length;

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade100),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '已选择 $actualSelectedCount 名参与用户',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 如果选择用户数量较多，增加可滚动区域
              actualSelectedCount > 5
                  ? SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < actualSelectedCount; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  'User ${i + 1}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  : Text(
                    '点击"修改选择"按钮可编辑参与用户',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
            ],
          ),
        );
      },
      loading:
          () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error:
          (_, __) => Container(
            padding: const EdgeInsets.all(12),
            child: const Text('加载用户信息失败', style: TextStyle(color: Colors.red)),
          ),
    );
  }
}
