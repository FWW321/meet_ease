import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_note.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';
import 'note_edit_dialog.dart';

/// 笔记详情对话框
class NoteDetailDialog {
  /// 显示笔记详情对话框
  static void show(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
    String meetingId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Consumer(
            builder: (context, ref, child) {
              // 使用noteDetailProvider获取最新的笔记详情
              final noteDetailAsync = ref.watch(noteDetailProvider(note.id));

              // 获取当前用户ID以检查权限
              final currentUserIdAsync = ref.watch(currentUserIdProvider);

              return noteDetailAsync.when(
                loading:
                    () => const AlertDialog(
                      content: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (err, stack) => AlertDialog(
                      title: const Text('获取笔记详情失败'),
                      content: Text('$err'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('关闭'),
                        ),
                      ],
                    ),
                data: (noteDetail) {
                  // 使用新获取的详情，如果为null则使用列表中的笔记
                  final currentNote = noteDetail ?? note;
                  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

                  return AlertDialog(
                    title:
                        currentNote.noteName != null &&
                                currentNote.noteName!.isNotEmpty
                            ? Text(currentNote.noteName!)
                            : Text('${currentNote.creatorName}的笔记'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 创建/更新时间
                          Text(
                            '创建于: ${dateFormat.format(currentNote.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (currentNote.updatedAt != null)
                            Text(
                              '更新于: ${dateFormat.format(currentNote.updatedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            '作者: ${currentNote.creatorName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),

                          const SizedBox(height: 16),

                          // 笔记内容
                          SelectableText(currentNote.content),
                        ],
                      ),
                    ),
                    actions: [
                      // 根据当前用户是否为笔记创建者显示不同的操作按钮
                      currentUserIdAsync.when(
                        loading:
                            () => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        error:
                            (_, __) => Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('关闭'),
                                ),
                              ],
                            ),
                        data: (currentUserId) {
                          final isCreator =
                              currentNote.creatorId == currentUserId;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isCreator) ...[
                                // 分享按钮
                                TextButton.icon(
                                  icon: Icon(
                                    currentNote.isShared
                                        ? Icons.share_outlined
                                        : Icons.share,
                                    color:
                                        currentNote.isShared
                                            ? Colors.grey
                                            : Colors.blue,
                                  ),
                                  label: Text(
                                    currentNote.isShared ? '取消共享' : '共享',
                                  ),
                                  onPressed: () {
                                    // 切换共享状态
                                    final notifier = ref.read(
                                      meetingNotesNotifierProvider(
                                        meetingId,
                                      ).notifier,
                                    );
                                    notifier.shareNote(
                                      currentNote.id,
                                      !currentNote.isShared,
                                    );
                                    Navigator.of(context).pop();
                                  },
                                ),
                                // 编辑按钮
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('编辑'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    NoteEditDialog.show(
                                      context,
                                      currentNote,
                                      ref,
                                      meetingId,
                                    );
                                  },
                                ),
                              ],
                              // 关闭按钮
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('关闭'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
    );
  }
}
