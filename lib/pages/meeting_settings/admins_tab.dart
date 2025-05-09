import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    // 获取所有参与者（排除创建者和已有管理员）
    final participantsAsync = ref.watch(
      meetingParticipantsProvider(meeting.id),
    );

    // 获取管理员列表
    final managersAsync = ref.watch(meetingManagersProvider(meeting.id));

    // 检查当前用户是否为会议创建者
    final isCreator = meeting.isCreatorOnly(currentUserId);

    // 打印调试信息
    managersAsync.whenOrNull(
      data:
          (managers) => print(
            '找到${managers.length}个管理员: ${managers.map((m) => '${m.id}-${m.name}').join(', ')}',
          ),
      error: (error, _) => print('获取管理员列表出错: $error'),
      loading: () => print('正在加载管理员列表...'),
    );

    return Column(
      children: [
        // 管理员列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 创建者信息（固定在顶部）
              UserTile(
                userId: meeting.organizerId,
                label: '创建者',
                canRemove: false,
                onRemove: null,
              ),

              // 刷新按钮
              ListTile(
                title: const Text('手动刷新管理员列表'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // 刷新管理员列表
                    ref.invalidate(meetingManagersProvider(meeting.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在刷新管理员列表...')),
                    );
                  },
                ),
              ),

              const Divider(),

              // 现有管理员列表
              managersAsync.when(
                data: (managers) {
                  if (managers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          '尚未添加管理员',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        managers
                            .map(
                              (admin) => UserTile(
                                userId: admin.id,
                                label: '管理员',
                                canRemove: isCreator,
                                onRemove: () {
                                  // 移除管理员
                                  _removeAdmin(context, ref, admin.id);
                                },
                              ),
                            )
                            .toList(),
                  );
                },
                loading:
                    () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, stackTrace) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              '加载管理员列表失败: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                            if (stackTrace != null)
                              Text(
                                '堆栈: $stackTrace',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),

        // 底部添加按钮，只有创建者可以添加管理员
        if (isCreator)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAddAdminDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12.0),
                ),
                child: const Text('添加管理员'),
              ),
            ),
          ),
      ],
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
      _addAdmin(context, ref, userId);
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
