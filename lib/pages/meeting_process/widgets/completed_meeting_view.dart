import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/meeting.dart';
import '../../../providers/meeting_providers.dart';

/// 构建已结束会议的主视图
class CompletedMeetingView extends StatelessWidget {
  final WidgetRef ref;
  final Meeting meeting;
  final String meetingId;

  const CompletedMeetingView({
    required this.ref,
    required this.meeting,
    required this.meetingId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 获取签到状态
    final signInStatusAsync = ref.watch(meetingSignInProvider(meetingId));

    return Column(
      children: [
        // 会议状态和签到信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '会议已结束',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '会议结束时间：${meeting.endTime.toString().substring(0, 16)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // 签到状态
              Row(
                children: [
                  const Text('签到状态：', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  signInStatusAsync.when(
                    data:
                        (isSignedIn) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSignedIn
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSignedIn
                                      ? Colors.green
                                      : Colors.red.shade300,
                            ),
                          ),
                          child: Text(
                            isSignedIn ? '已签到' : '未签到',
                            style: TextStyle(
                              color:
                                  isSignedIn
                                      ? Colors.green
                                      : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    loading:
                        () => const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    error:
                        (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Text(
                            '加载失败',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 会议历史记录入口提示
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_toggle_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '此会议已结束',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您可以通过底部功能栏查看会议记录',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('发送会议纪要至邮箱'),
                  onPressed: () {
                    // 实现发送会议纪要功能
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
