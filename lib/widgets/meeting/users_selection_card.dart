import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/user_providers.dart';
import '../../constants/app_constants.dart';

/// 用户选择卡片组件
class UsersSelectionCard extends HookConsumerWidget {
  final List<String> selectedUserIds;
  final VoidCallback onUserSelectionPressed;

  const UsersSelectionCard({
    super.key,
    required this.selectedUserIds,
    required this.onUserSelectionPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 是否展示所有用户
    final showAllUsers = useState(false);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(26)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Expanded(
                  child: Text(
                    '参会人员 *',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onUserSelectionPressed,
                  icon: Icon(
                    selectedUserIds.isEmpty ? Icons.add : Icons.edit_outlined,
                    size: 18,
                  ),
                  label: Text(selectedUserIds.isEmpty ? '添加用户' : '编辑用户'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingXS,
                    ),
                  ),
                ),
              ],
            ),

            // 提示信息
            if (selectedUserIds.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: AppConstants.paddingM),
                padding: const EdgeInsets.all(AppConstants.paddingS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(77),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(
                        '私有会议必须选择至少一名参会者',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppConstants.paddingM),

                  // 已选用户数量统计
                  Text(
                    '已选择 ${selectedUserIds.length} 位参会者',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingS),

                  // 已选用户列表
                  _buildSelectedUsersInfo(
                    ref,
                    theme,
                    context,
                    showAllUsers.value,
                    () => showAllUsers.value = !showAllUsers.value,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUsersInfo(
    WidgetRef ref,
    ThemeData theme,
    BuildContext context,
    bool showAll,
    VoidCallback toggleShowAll,
  ) {
    final currentUserIdAsync = ref.watch(currentLoggedInUserIdProvider);
    final usersAsync = ref.watch(searchUsersProvider());

    return usersAsync.when(
      data: (users) {
        // 获取当前登录用户ID
        final currentUserId = currentUserIdAsync.valueOrNull;

        // 筛选出已选择的用户数据
        final selectedUsers =
            users.where((user) => selectedUserIds.contains(user.id)).toList();

        return Column(
          children: [
            // 用户列表
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    showAll
                        ? selectedUsers.length
                        : selectedUsers.length > 3
                        ? 3
                        : selectedUsers.length,
                separatorBuilder:
                    (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withAlpha(26),
                      indent: AppConstants.paddingM,
                      endIndent: AppConstants.paddingM,
                    ),
                itemBuilder: (context, index) {
                  final user = selectedUsers[index];
                  final isCurrentUser = user.id == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isCurrentUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondaryContainer,
                      child: Icon(
                        isCurrentUser ? Icons.person : Icons.person_outline,
                        color:
                            isCurrentUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      isCurrentUser ? '创建者 (你)' : user.email,
                      style: theme.textTheme.bodySmall,
                    ),
                    dense: true,
                  );
                },
              ),
            ),

            // 查看全部/收起按钮
            if (selectedUsers.length > 3)
              TextButton.icon(
                onPressed: toggleShowAll,
                icon: Icon(
                  showAll ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  showAll ? '收起' : '查看全部 ${selectedUsers.length} 位参会者',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              ),
          ],
        );
      },
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingM),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      error:
          (error, stackTrace) => Container(
            margin: const EdgeInsets.all(AppConstants.paddingS),
            padding: const EdgeInsets.all(AppConstants.paddingS),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withAlpha(128),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              '加载用户信息失败: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
    );
  }
}
