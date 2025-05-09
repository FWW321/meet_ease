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

    return Column(
      children: [
        // 黑名单列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (meeting.blacklist.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('黑名单为空', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...meeting.blacklist.map(
                  (userId) => UserTile(
                    userId: userId,
                    label: '已封禁',
                    canRemove: meeting.canUserManage(currentUserId),
                    onRemove: () {
                      // 从黑名单移除
                      _removeFromBlacklist(context, ref, userId);
                    },
                  ),
                ),
            ],
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

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
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
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: const Text('添加到黑名单'),
                  ),
                ),
              );
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('加载参与者失败: $error')),
                ),
          ),
      ],
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
            title: const Text('添加到黑名单'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableParticipants.length,
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
                    title: Text(user.name),
                    subtitle: Text(user.email),
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
