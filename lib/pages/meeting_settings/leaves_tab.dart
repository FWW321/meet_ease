import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer' as developer;
import '../../models/meeting.dart';
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

    // 记录组件构建时的请假申请状态
    developer.log(
      '构建LeavesTab: meetingId=${meeting.id}, 请假申请状态=${leavesAsync.toString()}',
      name: 'LeavesTab',
    );

    // 获取主题色
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: backgroundColor.withValues(alpha: 0.5),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  developer.log('手动刷新请假列表', name: 'LeavesTab');
                  ref.invalidate(meetingLeavesProvider(meeting.id));
                },
                child: leavesAsync.when(
                  data: (leaves) {
                    developer.log(
                      '显示请假列表: 数量=${leaves.length}',
                      name: 'LeavesTab',
                    );

                    if (leaves.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
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
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () {
                                      developer.log(
                                        '点击刷新按钮',
                                        name: 'LeavesTab',
                                      );
                                      ref.invalidate(
                                        meetingLeavesProvider(meeting.id),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('刷新'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: leaves.length,
                            separatorBuilder:
                                (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final leave = leaves[index];
                              developer.log(
                                '构建请假项: leaveId=${leave.leaveId}, userId=${leave.userId}, status=${leave.status}',
                                name: 'LeavesTab',
                              );
                              return LeaveTile(
                                leave: leave,
                                onApprove:
                                    () => _approveLeave(
                                      context,
                                      ref,
                                      leave.leaveId,
                                    ),
                                onReject:
                                    () => _rejectLeave(
                                      context,
                                      ref,
                                      leave.leaveId,
                                    ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) {
                    developer.log(
                      '请假列表加载失败: $error\n$stackTrace',
                      name: 'LeavesTab',
                      error: error,
                      stackTrace: stackTrace,
                    );

                    return Center(
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
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                developer.log('点击重试按钮', name: 'LeavesTab');
                                ref.invalidate(
                                  meetingLeavesProvider(meeting.id),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
      developer.log('尝试通过请假申请: leaveId=$leaveId', name: 'LeavesTab');
      final leaveService = ref.read(leaveServiceProvider);
      await leaveService.approveLeave(leaveId);

      // 刷新请假申请列表
      developer.log('请假申请通过成功，刷新列表', name: 'LeavesTab');
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
      developer.log('通过请假申请失败: $error', name: 'LeavesTab', error: error);
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
      developer.log('尝试拒绝请假申请: leaveId=$leaveId', name: 'LeavesTab');
      final leaveService = ref.read(leaveServiceProvider);
      await leaveService.rejectLeave(leaveId);

      // 刷新请假申请列表
      developer.log('请假申请拒绝成功，刷新列表', name: 'LeavesTab');
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
      developer.log('拒绝请假申请失败: $error', name: 'LeavesTab', error: error);
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
