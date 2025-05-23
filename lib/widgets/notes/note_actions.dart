import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';

/// 笔记相关操作类，提供静态方法
class NoteActions {
  /// 确认删除笔记
  static void confirmDeleteNote(
    BuildContext context,
    String noteId,
    String meetingId,
    WidgetRef ref,
  ) {
    // 首先检查当前用户是否是笔记作者
    ref.read(currentUserIdProvider.future).then((currentUserId) {
      // 获取要删除的笔记
      ref.read(noteDetailProvider(noteId).future).then((note) {
        if (!context.mounted) return;

        // 如果笔记不存在，显示错误信息
        if (note == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法获取笔记信息')));
          return;
        }

        // 检查权限
        if (note.creatorId != currentUserId) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('您没有权限删除此笔记')));
          return;
        }

        // 显示确认对话框
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除这个笔记吗？此操作不可撤销。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      // 删除笔记
                      final notifier = ref.read(
                        meetingNotesNotifierProvider(meetingId).notifier,
                      );
                      notifier.removeNote(noteId);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('删除'),
                  ),
                ],
              ),
        );
      });
    });
  }
}
