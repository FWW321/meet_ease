import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'vote/vote_list_widget.dart' as vote;

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
    // 使用新的投票列表组件
    return vote.VotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly);
  }
}
