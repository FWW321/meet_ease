import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../widgets/user_selection_dialog.dart';
import '../../constants/app_constants.dart';
import '../../utils/http_utils.dart';
import 'user_tile.dart';

/// 为当前页面创建黑名单列表提供者
final blacklistProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  meetingId,
) async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/blacklist/list/$meetingId'),
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] == 200 && responseData['data'] != null) {
        return responseData['data'] as List<dynamic>;
      } else {
        throw Exception(responseData['message'] ?? '获取黑名单列表失败');
      }
    } else {
      throw Exception(
        HttpUtils.extractErrorMessage(response, defaultMessage: '获取黑名单列表请求失败'),
      );
    }
  } catch (e) {
    throw Exception('获取黑名单列表时出错: $e');
  }
});

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
    // 获取黑名单列表
    final blacklistAsync = ref.watch(blacklistProvider(meeting.id));

    // 获取所有参与者
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
              child: blacklistAsync.when(
                data: (blacklistMembers) {
                  if (blacklistMembers.isEmpty) {
                    return Center(
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
                    );
                  } else {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: blacklistMembers.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = blacklistMembers[index];
                        final userId = member['userId'].toString();

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
                    );
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stack) => Center(
                      child: Text(
                        '加载黑名单失败: $error',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
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

                // 获取已在黑名单中的用户ID
                final blacklistedUserIds =
                    blacklistAsync.whenOrNull(
                      data:
                          (members) =>
                              members
                                  .map((m) => m['userId'].toString())
                                  .toList(),
                    ) ??
                    [];

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
                    onPressed: () {
                      // 根据会议类型选择从哪些用户中选择
                      if (meeting.visibility == MeetingVisibility.private) {
                        // 从参与者中选择用户添加到黑名单（排除管理员和创建者）
                        final availableIds =
                            participants
                                .map((user) => user.id)
                                .where(
                                  (id) =>
                                      id != meeting.organizerId &&
                                      !adminIds.contains(id) &&
                                      !blacklistedUserIds.contains(id),
                                )
                                .toList();

                        if (availableIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('没有可添加的用户'),
                              backgroundColor: Colors.amber,
                            ),
                          );
                          return;
                        }

                        _showSelectParticipantsDialog(
                          context,
                          ref,
                          availableIds,
                        );
                      } else {
                        // 公开会议，从所有用户中选择
                        _showSelectUserDialog(
                          context,
                          ref,
                          blacklistedUserIds,
                          [meeting.organizerId, ...adminIds],
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off),
                        const SizedBox(width: 10),
                        const Text(
                          '添加到黑名单',
                          style: TextStyle(
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

  // 选择参与者对话框（私有会议）
  Future<void> _showSelectParticipantsDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> availableIds,
  ) async {
    final selectedUserIds = await showUserSelectionDialog(
      context: context,
      initialSelectedUserIds: const [],
      userIdFilter: availableIds,
    );

    if (selectedUserIds != null &&
        selectedUserIds.isNotEmpty &&
        context.mounted) {
      for (final userId in selectedUserIds) {
        await _addToBlacklist(context, ref, userId);
      }
    }
  }

  // 选择用户对话框（公开会议）
  Future<void> _showSelectUserDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> blacklistedUserIds,
    List<String> excludeIds,
  ) async {
    // 排除已在黑名单中的用户和创建者以及管理员
    final userIdFilter = [...blacklistedUserIds, ...excludeIds];

    final selectedUserIds = await showUserSelectionDialog(
      context: context,
      initialSelectedUserIds: const [],
      userIdFilter: userIdFilter.isEmpty ? null : userIdFilter,
    );

    if (selectedUserIds != null &&
        selectedUserIds.isNotEmpty &&
        context.mounted) {
      for (final userId in selectedUserIds) {
        await _addToBlacklist(context, ref, userId);
      }
    }
  }

  Future<void> _addToBlacklist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    // 添加到黑名单
    final meetingService = ref.read(meetingServiceProvider);
    try {
      await meetingService.addUserToBlacklist(meeting.id, userId);

      // 刷新会议详情和黑名单列表
      ref.invalidate(meetingDetailProvider(meeting.id));
      ref.invalidate(blacklistProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已将用户添加到黑名单'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加到黑名单失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFromBlacklist(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    // 从黑名单移除
    final meetingService = ref.read(meetingServiceProvider);
    try {
      await meetingService.removeUserFromBlacklist(meeting.id, userId);

      // 刷新会议详情和黑名单列表
      ref.invalidate(meetingDetailProvider(meeting.id));
      ref.invalidate(blacklistProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已将用户从黑名单移除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('从黑名单移除失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
