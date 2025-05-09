import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../models/user.dart';
import '../../providers/meeting_providers.dart';
import 'user_tile.dart';

/// 黑名单管理标签页
class BlacklistTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const BlacklistTab({
    required this.meeting,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有参与者（排除已在黑名单中的用户）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
    );

    // 获取管理员列表
    final managersAsync = ref.watch(meetingManagersProvider(meeting.id));

    // 获取主题色
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: backgroundColor.withOpacity(0.5),
      child: Column(
        children: [
          // 黑名单列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  meeting.blacklist.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '黑名单为空',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '所有用户都可以正常参与会议',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: meeting.blacklist.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final userId = meeting.blacklist[index];
                          return UserTile(
                            userId: userId,
                            label: '已封禁',
                            labelColor: Colors.red.shade700,
                            canRemove: meeting.canUserManage(currentUserId),
                            onRemove: () {
                              // 从黑名单移除
                              _removeFromBlacklist(context, ref, userId);
                            },
                          );
                        },
                      ),
            ),
          ),

          // 底部添加按钮
          if (meeting.canUserManage(currentUserId))
            participantsAsync.when(
              data: (participants) {
                // 获取管理员ID列表用于过滤
                final adminIds =
                    managersAsync.whenOrNull(
                      data:
                          (managers) =>
                              managers.map((admin) => admin.id).toList(),
                    ) ??
                    [];

                // 过滤掉已在黑名单中的用户和创建者以及管理员
                final availableParticipants =
                    participants
                        .where(
                          (user) =>
                              !meeting.blacklist.contains(user.id) &&
                              user.id != meeting.organizerId &&
                              !adminIds.contains(user.id),
                        )
                        .toList();

                return Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade300.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        availableParticipants.isEmpty
                            ? null
                            : () => _showAddToBlacklistDialog(
                              context,
                              ref,
                              availableParticipants,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off),
                        const SizedBox(width: 10),
                        Text(
                          availableParticipants.isEmpty ? '没有可添加的用户' : '添加到黑名单',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        '加载参与者失败: $error',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  void _showAddToBlacklistDialog(
    BuildContext context,
    WidgetRef ref,
    List<User> availableParticipants,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_off, color: Colors.red.shade700),
                const SizedBox(width: 10),
                const Text('添加到黑名单'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: availableParticipants.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = availableParticipants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child:
                          user.avatarUrl == null
                              ? Text(user.name.substring(0, 1))
                              : null,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.block, color: Colors.red),
                    onTap: () {
                      Navigator.of(context).pop();
                      _addToBlacklist(context, ref, user.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ],
          ),
    );
  }

  void _addToBlacklist(BuildContext context, WidgetRef ref, String userId) {
    // 添加到黑名单
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .addUserToBlacklist(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已将用户添加到黑名单'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('添加到黑名单失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _removeFromBlacklist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    // 从黑名单移除
    final meetingService = ref.read(meetingServiceProvider);
    meetingService
        .removeUserFromBlacklist(meeting.id, userId)
        .then((_) {
          // 刷新会议详情
          ref.invalidate(meetingDetailProvider(meeting.id));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已将用户从黑名单移除'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('从黑名单移除失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }
}
