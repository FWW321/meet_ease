import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/leave_providers.dart';
import 'leave_tile.dart';

/// 请假申请标签页
class LeavesTab extends HookConsumerWidget {
  final Meeting meeting;
  final String currentUserId;

  const LeavesTab({
    required this.meeting,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取请假申请列表
    final leavesAsync = ref.watch(meetingLeavesProvider(meeting.id));

    return Column(
      children: [
        // 请假申请列表
        Expanded(
          child: leavesAsync.when(
            data: (leaves) {
              if (leaves.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('没有请假申请', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  return LeaveTile(
                    leave: leave,
                    onApprove: () => _approveLeave(context, ref, leave.leaveId),
                    onReject: () => _rejectLeave(context, ref, leave.leaveId),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => Center(
                  child: Text(
                    '加载请假申请失败: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
          ),
        ),

        // 底部按钮 - 刷新列表
        if (meeting.canUserManage(currentUserId))
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('刷新请假申请列表'),
                onPressed: () {
                  // 刷新请假申请列表
                  ref.invalidate(meetingLeavesProvider(meeting.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('正在刷新请假申请列表...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12.0),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 通过请假申请
  void _approveLeave(
    BuildContext context,
    WidgetRef ref,
    String leaveId,
  ) async {
    try {
      final leaveService = ref.read(leaveServiceProvider);
      await leaveService.approveLeave(leaveId);

      // 刷新请假申请列表
      ref.invalidate(meetingLeavesProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已通过请假申请'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('通过请假申请失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 拒绝请假申请
  void _rejectLeave(BuildContext context, WidgetRef ref, String leaveId) async {
    try {
      final leaveService = ref.read(leaveServiceProvider);
      await leaveService.rejectLeave(leaveId);

      // 刷新请假申请列表
      ref.invalidate(meetingLeavesProvider(meeting.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已拒绝请假申请'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拒绝请假申请失败: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
