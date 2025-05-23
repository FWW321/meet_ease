import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/leave.dart';
import '../../providers/user_providers.dart';

/// 请假申请条目组件
class LeaveTile extends HookConsumerWidget {
  final Leave leave;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const LeaveTile({
    required this.leave,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用userNameProvider获取用户名
    final userNameAsync = ref.watch(userNameProvider(leave.userId));

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息和创建时间
            Row(
              children: [
                userNameAsync.when(
                  data:
                      (userName) => Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  loading: () => const Text('加载中...'),
                  error:
                      (_, __) => Text(
                        '用户 ${leave.userId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                ),
                const Spacer(),
                Text(
                  '${leave.createdAt.year}-${leave.createdAt.month.toString().padLeft(2, '0')}-${leave.createdAt.day.toString().padLeft(2, '0')} ${leave.createdAt.hour.toString().padLeft(2, '0')}:${leave.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 请假原因
            Text(leave.reason),
            const SizedBox(height: 12),

            // 请假状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: leave.getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: leave.getStatusColor().withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    leave.status,
                    style: TextStyle(
                      color: leave.getStatusColor(),
                      fontSize: 12,
                    ),
                  ),
                ),

                // 仅对待审批的请假显示审批按钮
                if (leave.status == '待审批')
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check, color: Colors.green),
                        label: const Text('通过'),
                        onPressed: onApprove,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('拒绝'),
                        onPressed: onReject,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
