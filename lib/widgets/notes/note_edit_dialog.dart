import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_note.dart';
import '../../providers/meeting_process_providers.dart';

/// 笔记编辑对话框
class NoteEditDialog {
  /// 显示编辑笔记对话框
  static void show(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
    String meetingId,
  ) {
    final contentController = TextEditingController(text: note.content);
    final tagsController = TextEditingController(
      text: note.tags != null ? note.tags!.join(', ') : '',
    );
    final nameController = TextEditingController(text: note.noteName ?? '');
    bool isShared = note.isShared;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('编辑笔记'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 笔记名称输入
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '笔记名称',
                            hintText: '请输入笔记标题',
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: contentController,
                          maxLines: 10,
                          minLines: 5,
                          decoration: const InputDecoration(
                            labelText: '笔记内容',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: '标签 (用逗号分隔)',
                            hintText: '例如: 任务,讨论,决定',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('与团队共享'),
                          subtitle: const Text('其他会议成员可以看到这个笔记'),
                          value: isShared,
                          onChanged: (value) {
                            setState(() {
                              isShared = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // 解析标签
                        List<String>? tags;
                        if (tagsController.text.isNotEmpty) {
                          tags =
                              tagsController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                        }

                        // 更新笔记
                        final updatedNote = note.copyWith(
                          content: contentController.text,
                          noteName: nameController.text,
                          isShared: isShared,
                          tags: tags,
                          updatedAt: DateTime.now(),
                        );

                        // 保存更新
                        final notifier = ref.read(
                          meetingNotesNotifierProvider(meetingId).notifier,
                        );
                        notifier.updateNote(updatedNote);

                        Navigator.of(context).pop();
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
          ),
    );
  }
}
