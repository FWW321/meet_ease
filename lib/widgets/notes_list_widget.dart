import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'notes/index.dart' as notes;

/// 会议笔记列表组件
class NotesListWidget extends ConsumerWidget {
  final String meetingId;
  final bool isReadOnly;

  const NotesListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用重构后的笔记列表组件
    return notes.NotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly);
  }
}
