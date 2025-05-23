import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_vote.dart';
import '../../providers/meeting_process_providers.dart';
import '../../utils/time_utils.dart';
import 'vote_dialog.dart';

/// 投票卡片组件
class VoteCardWidget extends ConsumerWidget {
  final MeetingVote vote;
  final String meetingId;

  const VoteCardWidget({
    required this.vote,
    required this.meetingId,
    super.key,
  });

  // 获取投票状态颜色
  Color _getVoteStatusColor(VoteStatus status) {
    switch (status) {
      case VoteStatus.pending:
        return Colors.orange;
      case VoteStatus.active:
        return Colors.blue;
      case VoteStatus.closed:
        return Colors.grey;
    }
  }

  // 获取投票状态文本
  String _getVoteStatusText(VoteStatus status) {
    switch (status) {
      case VoteStatus.pending:
        return '待开始';
      case VoteStatus.active:
        return '进行中';
      case VoteStatus.closed:
        return '已结束';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getVoteStatusColor(vote.status);
    final statusText = _getVoteStatusText(vote.status);

    // 判断是否可以投票（进行中状态且未过截止时间）
    final now = TimeUtils.nowInShanghaiTimeZone();
    final bool canVote =
        vote.status == VoteStatus.active &&
        (vote.endTime == null ||
            now.isBefore(TimeUtils.utcToShanghaiTimeZone(vote.endTime!)));

    return InkWell(
      onTap: canVote ? () => _showVoteDialog(context, vote, ref) : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      vote.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),

              // 描述
              if (vote.description != null && vote.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    vote.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              // 投票类型
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      vote.type == VoteType.singleChoice
                          ? Icons.radio_button_checked
                          : Icons.check_box,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vote.type == VoteType.singleChoice ? '单选' : '多选',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (vote.isAnonymous) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '匿名投票',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              // 保留开始和结束时间
              if (vote.startTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '开始于: ${TimeUtils.formatDateTime(TimeUtils.utcToShanghaiTimeZone(vote.startTime!), format: 'yyyy-MM-dd HH:mm')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              if (vote.endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '截止于: ${TimeUtils.formatDateTime(TimeUtils.utcToShanghaiTimeZone(vote.endTime!), format: 'yyyy-MM-dd HH:mm')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

              // 进度指示器（仅针对活动投票）
              if (vote.status == VoteStatus.active) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value:
                      vote.totalVotes > 0
                          ? vote.totalVotes / 10
                          : 0, // 假设10人参与会议
                  backgroundColor: Colors.grey[200],
                  color: Colors.blue,
                ),
              ],

              // 操作按钮（仅保留开始投票按钮）
              if (vote.status == VoteStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _startVote(context, vote.id, ref),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始投票'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // 如果是活动状态，添加提示文字
              if (vote.status == VoteStatus.active)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        '点击卡片参与投票',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示投票对话框
  void _showVoteDialog(BuildContext context, MeetingVote vote, WidgetRef ref) {
    // 检查投票是否已经结束（当前时间已超过截止时间）
    final now = TimeUtils.nowInShanghaiTimeZone();
    if (vote.endTime != null &&
        now.isAfter(TimeUtils.utcToShanghaiTimeZone(vote.endTime!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该投票已结束，无法参与投票'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => VoteDialog(vote: vote, meetingId: meetingId),
    );
  }

  // 开始投票
  void _startVote(BuildContext context, String voteId, WidgetRef ref) {
    final notifier = ref.read(
      voteNotifierProvider(voteId, meetingId: meetingId).notifier,
    );
    notifier.startVote();
  }
}
