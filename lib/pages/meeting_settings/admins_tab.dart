import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../constants/app_constants.dart';
import '../../utils/http_utils.dart';
import '../../widgets/user_selection_dialog.dart';
import 'user_tile.dart';

/// 管理员管理标签页
class AdminsTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const AdminsTab({
    required this.meeting,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取管理员列表
    final managersAsync = ref.watch(meetingManagersProvider(meeting.id));

    // 检查当前用户是否为会议创建者
    final isCreator = meeting.isCreatorOnly(currentUserId);

    // 获取主题色
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: backgroundColor.withValues(alpha: 0.5),
      child: Column(
        children: [
          // 管理员列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: managersAsync.when(
                data: (managers) {
                  if (managers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '尚未添加管理员',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: managers.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final admin = managers[index];
                      return UserTile(
                        userId: admin.id,
                        label: '管理员',
                        canRemove: isCreator,
                        onRemove: () {
                          // 移除管理员
                          _removeAdmin(context, ref, admin.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载管理员列表失败',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),

          // 底部添加按钮，只有创建者可以添加管理员
          if (isCreator)
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showAddAdminDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_add),
                    SizedBox(width: 10),
                    Text(
                      '添加管理员',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context, WidgetRef ref) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以添加管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 获取管理员ID列表和创建者ID，用于过滤
    final managersAsync = ref.read(meetingManagersProvider(meeting.id));
    final adminIds =
        managersAsync.whenOrNull(
          data: (managers) => managers.map((admin) => admin.id).toList(),
        ) ??
        [];
    final creatorId = meeting.organizerId;

    // 根据会议类型决定从哪些用户中选择管理员
    if (meeting.visibility == MeetingVisibility.private) {
      // 私有会议：从参与者中选取管理员
      // 获取参与者列表
      final participantsAsync = ref.read(
        meetingParticipantsProvider(meeting.id),
      );
      final participantIds =
          participantsAsync.whenOrNull(
            data:
                (participants) =>
                    participants.map((participant) => participant.id).toList(),
          ) ??
          [];

      // 如果没有参与者，显示提示消息
      if (participantIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('私有会议没有找到参与者，请先添加参与者'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 使用UserSelectionDialog来选择管理员，从参与者中选择
      final selectedUserIds = await showUserSelectionDialog(
        context: context,
        initialSelectedUserIds: [], // 初始没有选择的管理员
        userIdFilter: participantIds, // 只显示参与者
      );

      // 如果用户取消了选择，则返回null
      if (selectedUserIds == null || selectedUserIds.isEmpty) return;

      // 过滤掉创建者ID和已有管理员ID
      final validSelectedIds =
          selectedUserIds
              .where((id) => id != creatorId && !adminIds.contains(id))
              .toList();

      if (validSelectedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所选用户都已是管理员或创建者'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 添加所有选中的用户为管理员
      for (final userId in validSelectedIds) {
        if (!context.mounted) return;
        _addAdmin(context, ref, userId);
      }
    } else {
      // 公开会议：从所有用户中选取管理员
      // 使用UserSelectionDialog来选择管理员，从所有用户中选择
      final selectedUserIds = await showUserSelectionDialog(
        context: context,
        initialSelectedUserIds: [], // 初始没有选择的管理员
      );

      // 如果用户取消了选择，则返回null
      if (selectedUserIds == null || selectedUserIds.isEmpty) return;

      // 过滤掉创建者ID和已有管理员ID
      final validSelectedIds =
          selectedUserIds
              .where((id) => id != creatorId && !adminIds.contains(id))
              .toList();

      if (validSelectedIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所选用户都已是管理员或创建者'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 添加所有选中的用户为管理员
      for (final userId in validSelectedIds) {
        if (!context.mounted) return;
        _addAdmin(context, ref, userId);
      }
    }
  }

  void _addAdmin(BuildContext context, WidgetRef ref, String userId) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以添加管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // 添加管理员
      final meetingService = ref.read(meetingServiceProvider);
      await meetingService.addMeetingAdmin(meeting.id, userId);

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meeting.id));
      // 立即刷新管理员列表
      ref.invalidate(meetingManagersProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理员添加成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加管理员失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAdmin(BuildContext context, WidgetRef ref, String userId) async {
    // 检查当前用户是否为会议创建者
    if (!meeting.isCreatorOnly(currentUserId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有会议创建者可以移除管理员'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // 获取当前用户ID
      final currentUserId = await ref.read(currentUserIdProvider.future);

      // 构建API请求
      final response = await http
          .delete(
            Uri.parse(
              '${AppConstants.apiBaseUrl}/meeting/admin/remove',
            ).replace(
              queryParameters: {
                'meetingId': meeting.id,
                'userId': userId,
                'currentUserId': currentUserId,
              },
            ),
            headers: HttpUtils.createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // 解析响应
      final responseData = jsonDecode(response.body);

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '移除管理员失败');
      }

      // 刷新会议详情
      ref.invalidate(meetingDetailProvider(meeting.id));
      // 立即刷新管理员列表
      ref.invalidate(meetingManagersProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('管理员移除成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除管理员失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
