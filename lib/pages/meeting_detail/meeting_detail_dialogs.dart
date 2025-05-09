import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/service_providers.dart';

/// 显示取消会议确认对话框
void showCancelConfirmDialog(
  BuildContext context,
  WidgetRef ref,
  String creatorId,
) {
  showDialog(
    context: context,
    builder: (context) => _CancelMeetingDialog(creatorId: creatorId),
  );
}

/// 取消会议对话框组件
class _CancelMeetingDialog extends ConsumerWidget {
  final String creatorId;

  const _CancelMeetingDialog({required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从路由中获取meetingId
    final settings = ModalRoute.of(context)?.settings;
    final meetingId =
        settings?.arguments is String ? settings!.arguments as String : '';

    return AlertDialog(
      title: const Text('取消会议'),
      content: const Text('确定要取消此会议吗？此操作不可撤销，所有参会者将收到会议取消的通知。'),
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
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            try {
              // 调用取消会议服务
              final meetingService = ref.read(meetingServiceProvider);
              await meetingService.cancelMeeting(meetingId, creatorId);

              // 刷新会议详情
              ref.invalidate(meetingDetailProvider(meetingId));

              if (context.mounted) {
                // 关闭加载指示器
                Navigator.of(context).pop();

                // 显示成功提示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('会议已成功取消'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                // 关闭加载指示器
                Navigator.of(context).pop();

                // 显示错误提示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('取消会议失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('确定取消'),
        ),
      ],
    );
  }
}

/// 显示请假申请对话框
void showLeaveRequestDialog(
  BuildContext context,
  WidgetRef ref,
  Meeting meeting,
) {
  showDialog(
    context: context,
    builder: (context) => _LeaveRequestDialog(meeting: meeting),
  );
}

/// 请假申请对话框组件
class _LeaveRequestDialog extends ConsumerStatefulWidget {
  final Meeting meeting;

  const _LeaveRequestDialog({required this.meeting});

  @override
  ConsumerState<_LeaveRequestDialog> createState() =>
      _LeaveRequestDialogState();
}

class _LeaveRequestDialogState extends ConsumerState<_LeaveRequestDialog> {
  final reasonController = TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('申请请假'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('请输入请假理由'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: '请假理由',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => _submitLeaveRequest(context),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: const Text('提交'),
        ),
      ],
    );
  }

  Future<void> _submitLeaveRequest(BuildContext context) async {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入请假理由'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).pop();

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 调用请假服务
      final meetingService = ref.read(meetingServiceProvider);
      final currentUserId = await ref.read(currentUserIdProvider.future);

      if (currentUserId == null) {
        throw Exception('用户未登录');
      }

      final result = await meetingService.submitLeaveRequest(
        currentUserId,
        widget.meeting.id,
        reason,
      );

      print('请假申请结果: $result');

      if (!context.mounted) {
        print('context已卸载，不执行后续操作');
        return;
      }

      // 关闭加载指示器
      Navigator.of(context, rootNavigator: true).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请假申请已成功提交'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('请假申请出错: $e');

      if (!context.mounted) {
        print('context已卸载，不执行后续操作');
        return;
      }

      // 关闭加载指示器
      Navigator.of(context, rootNavigator: true).pop();

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交请假申请失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
