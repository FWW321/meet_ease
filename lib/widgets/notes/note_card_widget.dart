import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import '../../models/meeting_note.dart';
import '../../providers/user_providers.dart';
import 'note_detail_dialog.dart';
import 'note_actions.dart';
import 'note_view_page.dart';

/// 笔记卡片组件
class NoteCardWidget extends ConsumerWidget {
  final MeetingNote note;
  final String meetingId;

  const NoteCardWidget({
    required this.note,
    required this.meetingId,
    super.key,
  });

  /// 从笔记内容中提取纯文本预览
  String _getContentPreview(String content) {
    try {
      // 尝试解析JSON格式富文本
      final dynamic jsonData = jsonDecode(content);

      if (jsonData is List) {
        // 创建临时Document对象提取纯文本
        final document = Document.fromJson(jsonData);
        return document.toPlainText().trim();
      }

      // 如果不是有效的Delta JSON，直接返回原始内容
      return content;
    } catch (e) {
      // 解析失败，返回原始内容
      return content;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDateTime =
        note.updatedAt != null
            ? dateFormat.format(note.updatedAt!)
            : dateFormat.format(note.createdAt);

    // 提取笔记内容的纯文本预览
    final contentPreview = _getContentPreview(note.content);

    // 检查笔记创建者是否为当前用户
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => NoteViewPage.navigate(context, note, meetingId),
        onLongPress: () => NoteDetailDialog.show(context, note, ref, meetingId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 笔记标题
              if (note.noteName != null && note.noteName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note.noteName!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // 笔记内容预览
              Text(
                contentPreview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 作者和时间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '作者: ${note.creatorName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${note.updatedAt != null ? "更新于: " : "创建于: "}$formattedDateTime',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // 共享状态和操作按钮
                  Row(
                    children: [
                      if (note.isShared)
                        Tooltip(
                          message: '已共享',
                          child: Chip(
                            avatar: const Icon(
                              Icons.share,
                              size: 16,
                              color: Colors.blue,
                            ),
                            label: const Text('已共享'),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                            backgroundColor: Colors.blue.withAlpha(26),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),

                      // 仅当当前用户是创建者时才显示删除按钮
                      currentUserIdAsync.when(
                        data: (currentUserId) {
                          final isCreator = note.creatorId == currentUserId;
                          if (isCreator) {
                            return IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: '删除',
                              onPressed:
                                  () => NoteActions.confirmDeleteNote(
                                    context,
                                    note.id,
                                    meetingId,
                                    ref,
                                  ),
                            );
                          } else {
                            return Container(); // 不是创建者，不显示编辑和删除按钮
                          }
                        },
                        loading:
                            () => const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        error: (_, __) => Container(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
