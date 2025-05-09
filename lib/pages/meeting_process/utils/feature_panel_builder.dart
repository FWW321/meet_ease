import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../widgets/chat/chat_widget.dart';
import '../../../models/user.dart';
import '../../../providers/user_providers.dart';
import '../widgets/materials_list_widget.dart';
import '../../../widgets/notes_list_widget.dart';
import '../../../widgets/votes_list_widget.dart';
import '../meeting_process_page.dart';

/// 构建功能面板内容
Widget buildFeaturePanel(
  int index, {
  required String meetingId,
  bool isReadOnly = false,
  required String currentUserId,
  required AsyncValue<List<User>> participants,
  required WidgetRef ref,
}) {
  // 获取缓存的聊天组件（如果有）或创建新的
  final ChatWidget chatWidget = ref.read(
    Provider((ref) {
      final cache = ref.read(chatWidgetCacheProvider);
      if (cache != null) {
        return cache;
      }
      // 如果没有缓存，创建新的
      return ChatWidget(
        meetingId: meetingId,
        userId: currentUserId,
        userName: ref.watch(currentUserProvider).value?.name ?? '当前用户',
        isReadOnly: isReadOnly,
      );
    }),
  );

  // 功能组件列表
  final functionWidgets = [
    // 使用缓存的聊天组件
    chatWidget,
    MaterialsListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
    NotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
    VotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
  ];

  if (index >= 0 && index < functionWidgets.length) {
    return functionWidgets[index];
  }

  return const Center(child: Text('未知功能'));
}
