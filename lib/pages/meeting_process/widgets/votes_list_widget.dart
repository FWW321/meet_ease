import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../widgets/votes_list_widget.dart' as original;

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
    // 使用原始会议投票列表组件
    return original.VotesListWidget(
      meetingId: meetingId,
      isReadOnly: isReadOnly,
    );
  }
}
