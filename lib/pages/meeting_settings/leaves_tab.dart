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

    // 获取主题色
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: backgroundColor.withOpacity(0.5),
      child: Column(
        children: [
          // 请假申请列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              child: leavesAsync.when(
                data: (leaves) {
                  if (leaves.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有请假申请',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '所有参与者都将参加会议',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 请假申请数量概览
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '共有 ${leaves.length} 个请假申请',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // 请假申请列表
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: leaves.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final leave = leaves[index];
                            return LeaveTile(
                              leave: leave,
                              onApprove:
                                  () => _approveLeave(
                                    context,
                                    ref,
                                    leave.leaveId,
                                  ),
                              onReject:
                                  () =>
                                      _rejectLeave(context, ref, leave.leaveId),
                            );
                          },
                        ),
                      ),
                    ],
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
                              '加载请假申请失败',
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
        ],
      ),
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
