import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_vote.dart';
import '../../providers/meeting_process_providers.dart';
import '../../utils/time_utils.dart';
import 'vote_card_widget.dart';
import 'vote_create_dialog.dart';

/// 会议投票列表组件
class VotesListWidget extends ConsumerWidget {
  final String meetingId;
  final bool isReadOnly;

  const VotesListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votesAsync = ref.watch(meetingVotesProvider(meetingId));

    return Stack(
      children: [
        votesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '获取会议投票失败\n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      TextSpan(text: error.toString()),
                    ],
                  ),
                ),
              ),
          data: (votes) {
            if (votes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.how_to_vote_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无投票',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 将投票按状态分组
            final now = TimeUtils.nowInShanghaiTimeZone();
            final groupedVotes =
                votes.map((vote) {
                  // 根据截止时间自动确定状态
                  if (vote.status == VoteStatus.active &&
                      vote.endTime != null &&
                      now.isAfter(
                        TimeUtils.utcToShanghaiTimeZone(vote.endTime!),
                      )) {
                    // 如果当前时间超过了截止时间，则自动视为已结束
                    return vote.copyWith(status: VoteStatus.closed);
                  }
                  return vote;
                }).toList();

            final activeVotes =
                groupedVotes
                    .where((v) => v.status == VoteStatus.active)
                    .toList();
            final pendingVotes =
                groupedVotes
                    .where((v) => v.status == VoteStatus.pending)
                    .toList();
            final closedVotes =
                groupedVotes
                    .where((v) => v.status == VoteStatus.closed)
                    .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 进行中的投票
                if (activeVotes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '进行中的投票',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.blue),
                    ),
                  ),
                  ...activeVotes.map(
                    (vote) => VoteCardWidget(vote: vote, meetingId: meetingId),
                  ),
                  const SizedBox(height: 24),
                ],

                // 待开始的投票
                if (pendingVotes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '待开始的投票',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.orange),
                    ),
                  ),
                  ...pendingVotes.map(
                    (vote) => VoteCardWidget(vote: vote, meetingId: meetingId),
                  ),
                  const SizedBox(height: 24),
                ],

                // 已结束的投票
                if (closedVotes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '已结束的投票',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  ...closedVotes.map(
                    (vote) => VoteCardWidget(vote: vote, meetingId: meetingId),
                  ),
                ],
              ],
            );
          },
        ),

        // 右下角悬浮添加按钮
        if (!isReadOnly)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed:
                  () => showDialog(
                    context: context,
                    builder:
                        (context) => VoteCreateDialog(meetingId: meetingId),
                  ),
              tooltip: '创建投票',
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}
