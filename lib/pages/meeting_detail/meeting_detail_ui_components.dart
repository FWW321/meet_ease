import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';

/// 构建信息卡片
Widget buildInfoCard(List<Widget> children) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

/// 构建信息项
Widget buildInfoItem(
  String label,
  String value, {
  IconData? icon,
  Color? color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color ?? Colors.grey[700]),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// 构建角色标签
Widget buildRoleTag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(128)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
    ),
  );
}

/// 获取权限对应的颜色
Color getPermissionColor(MeetingPermission permission) {
  switch (permission) {
    case MeetingPermission.creator:
      return Colors.orange;
    case MeetingPermission.admin:
      return Colors.blue;
    case MeetingPermission.participant:
      return Colors.green;
    case MeetingPermission.blocked:
      return Colors.red;
  }
}

/// 格式化日期时间
String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// 构建组织者和管理员列表（用于公开和可搜索会议）
Widget buildOrganizersAndAdminsList(
  BuildContext context,
  WidgetRef ref,
  Meeting meeting,
) {
  // 如果是私有会议，不显示此组件（私有会议显示完整参会人员列表）
  if (meeting.visibility == MeetingVisibility.private) {
    return const SizedBox.shrink();
  }

  String descriptionText;
  if (meeting.visibility == MeetingVisibility.public) {
    descriptionText = '这是一个公开会议，任何人都可以参加';
  } else if (meeting.visibility == MeetingVisibility.searchable) {
    descriptionText = '这是一个可搜索会议，知道会议ID的人都可以参加';
  } else {
    // 添加一个兜底处理，虽然这个分支不应该被执行
    descriptionText = '私有会议';
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '组织者和管理员',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              descriptionText,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),

          // 显示组织者信息
          Consumer(
            builder: (context, ref, child) {
              final organizerNameAsync = ref.watch(
                userNameProvider(meeting.organizerId),
              );

              return organizerNameAsync.when(
                data:
                    (name) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withAlpha(51),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                      title: Text(name),
                      subtitle: const Text('会议创建者'),
                      trailing: buildRoleTag('创建者', Colors.orange),
                    ),
                loading:
                    () => const ListTile(
                      leading: CircleAvatar(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      title: Text('加载中...'),
                      subtitle: Text('会议创建者'),
                    ),
                error:
                    (_, __) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.error, size: 16, color: Colors.white),
                      ),
                      title: Text(meeting.organizerName),
                      subtitle: const Text('会议创建者（加载失败）'),
                    ),
              );
            },
          ),

          // 显示管理员列表
          Consumer(
            builder: (context, ref, child) {
              final managersAsync = ref.watch(
                meetingManagersProvider(meeting.id),
              );

              return managersAsync.when(
                data: (managers) {
                  if (managers.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          '管理员',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...managers
                          .map(
                            (manager) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withAlpha(51),
                                child: Text(
                                  manager.name.isNotEmpty
                                      ? manager.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                              title: Text(manager.name),
                              trailing: buildRoleTag('管理员', Colors.blue),
                              dense: true,
                            ),
                          )
                          .toList(),
                    ],
                  );
                },
                loading:
                    () => const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                error:
                    (error, _) => Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        '加载管理员列表失败: $error',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// 构建会议参与者列表
Widget buildParticipantsList(
  BuildContext context,
  WidgetRef ref,
  Meeting meeting,
  String meetingId,
  String? currentUserId,
) {
  // 如果不是私有会议，直接返回空组件，不显示参会人员列表
  if (meeting.visibility != MeetingVisibility.private) {
    return const SizedBox.shrink();
  }

  final participantsAsync = ref.watch(meetingParticipantsProvider(meetingId));
  final canManageMeeting =
      currentUserId != null && meeting.canUserManage(currentUserId);

  // 为私有会议设置标题和描述
  const titleText = '允许参加的人员';
  const descriptionText = '只有被邀请的人员才能参加此私有会议';

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                titleText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // 私有会议用户是管理员时，显示管理按钮
              if (canManageMeeting)
                TextButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('管理'),
                  onPressed: () {
                    // TODO: 实现添加/删除参会人员的功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('管理参会人员功能即将上线')),
                    );
                  },
                ),
            ],
          ),
          // 显示描述文字
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              descriptionText,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          participantsAsync.when(
            data: (participants) {
              if (participants.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children:
                    participants.map((user) {
                      // 确定用户角色标签
                      Widget? roleTag;
                      if (user.role == MeetingPermission.creator) {
                        roleTag = buildRoleTag('创建者', Colors.orange);
                      } else if (user.role == MeetingPermission.admin) {
                        roleTag = buildRoleTag('管理员', Colors.blue);
                      } else if (user.role == MeetingPermission.participant) {
                        roleTag = buildRoleTag('参会者', Colors.green);
                      }

                      // 使用用户名提供者来获取最新用户名
                      return Consumer(
                        builder: (context, ref, child) {
                          final userNameAsync = ref.watch(
                            userNameProvider(user.id),
                          );

                          return userNameAsync.when(
                            data: (userName) {
                              return _buildParticipantListTile(
                                context,
                                userName,
                                user,
                                roleTag,
                              );
                            },
                            loading:
                                () => _buildParticipantListTile(
                                  context,
                                  user.name,
                                  user,
                                  roleTag,
                                  isLoading: true,
                                ),
                            error:
                                (_, __) => _buildParticipantListTile(
                                  context,
                                  user.name,
                                  user,
                                  roleTag,
                                ),
                          );
                        },
                      );
                    }).toList(),
              );
            },
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error: (error, _) => Center(child: Text('加载参会人员失败: $error')),
          ),
        ],
      ),
    ),
  );
}

/// 构建参会者列表项
Widget _buildParticipantListTile(
  BuildContext context,
  String userName,
  dynamic user, // 简化起见，使用dynamic，实际应当定义具体的User类型
  Widget? roleTag, {
  bool isLoading = false,
}) {
  return ListTile(
    leading:
        isLoading
            ? CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withAlpha(51),
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
            : CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withAlpha(51),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
    title: Text(userName),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.email.isNotEmpty) Text(user.email),
        // 如果用户请假状态为"请假"，显示已请假，否则显示签到状态
        if (user.leaveStatus == '请假')
          const Text(
            '状态: 已请假',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          )
        else if (user.signInStatus != null)
          Text(
            '签到状态: ${user.signInStatus}',
            style: TextStyle(
              color: user.signInStatus == '已签到' ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
        // 显示请假驳回或审核中状态
        if (user.leaveStatus == '请假驳回')
          const Text(
            '请假申请已被驳回',
            style: TextStyle(color: Colors.red, fontSize: 12),
          )
        else if (user.leaveStatus == '请假审核中')
          const Text(
            '请假申请审核中',
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
      ],
    ),
    trailing: roleTag,
  );
}
