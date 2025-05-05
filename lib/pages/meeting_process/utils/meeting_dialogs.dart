import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/meeting.dart';
import '../../../providers/meeting_providers.dart';
import '../../../services/service_providers.dart';

/// 显示会议信息对话框
void showMeetingInfo(BuildContext context, Meeting meeting) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('会议信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('标题', meeting.title),
              _buildInfoRow(
                '开始时间',
                meeting.startTime.toString().substring(0, 16),
              ),
              _buildInfoRow(
                '结束时间',
                meeting.endTime.toString().substring(0, 16),
              ),
              _buildInfoRow('地点', meeting.location),
              _buildInfoRow('状态', getMeetingStatusText(meeting.status)),
              _buildInfoRow('类型', getMeetingTypeText(meeting.type)),
              _buildInfoRow('组织者', meeting.organizerName),
              if (meeting.description != null)
                _buildInfoRow('描述', meeting.description!),
              _buildInfoRow('参与人数', meeting.participantCount.toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
  );
}

/// 显示签到对话框
void showSignInDialog(
  BuildContext context,
  WidgetRef ref,
  String meetingId,
  VoidCallback onComplete,
) {
  final meeting = ref.read(meetingDetailProvider(meetingId)).value;

  // 检查是否为私有会议
  if (meeting != null && meeting.visibility != MeetingVisibility.private) {
    // 显示不支持签到的提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('只有私有会议支持签到功能'),
        backgroundColor: Colors.red,
      ),
    );
    onComplete();
    return;
  }

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('会议签到'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('确认签到本次会议吗？'),
              const SizedBox(height: 16),
              Text(
                meeting?.title ?? '当前会议',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (meeting != null)
                Text(
                  '开始时间：${meeting.startTime.toString().substring(0, 16)}',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onComplete();
              },
              child: const Text('取消'),
            ),
            Consumer(
              builder: (context, ref, child) {
                // 使用新的签到状态提供者
                final signInStatusAsync = ref.watch(
                  meetingSignInStatusProvider(meetingId),
                );
                final isLoading = signInStatusAsync is AsyncLoading;

                return TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            try {
                              // 使用新的签到操作提供者
                              await ref
                                  .read(
                                    meetingSignInOperationProvider(meetingId),
                                  )
                                  .signIn();

                              if (context.mounted) {
                                // 显示签到成功提示
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('签到成功'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.of(context).pop();
                                onComplete();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                // 显示错误提示
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('签到失败: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );

                                Navigator.of(context).pop();
                                onComplete();
                              }
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('确认签到'),
                );
              },
            ),
          ],
        ),
  );
}

/// 显示结束会议确认对话框
void showEndMeetingConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  String currentUserId,
  String meetingId,
) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('结束会议'),
          content: const Text('确认要结束此会议吗？此操作不可撤销，所有参会者将收到会议已结束的通知。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // 显示加载指示器
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 调用结束会议服务
                  final meetingService = ref.read(meetingServiceProvider);
                  await meetingService.endMeeting(meetingId, currentUserId);

                  // 刷新会议详情
                  ref.invalidate(meetingDetailProvider(meetingId));

                  if (context.mounted) {
                    // 关闭加载指示器
                    Navigator.of(context).pop();

                    // 显示成功提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('会议已成功结束'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // 返回会议列表
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    // 关闭加载指示器
                    Navigator.of(context).pop();

                    // 显示错误提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('结束会议失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确定结束'),
            ),
          ],
        ),
  );
}

/// 构建信息行
Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16)),
        const Divider(height: 16),
      ],
    ),
  );
}
