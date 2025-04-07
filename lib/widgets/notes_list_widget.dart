import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting_note.dart';
import '../providers/meeting_process_providers.dart';

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
    final notesAsync = ref.watch(meetingNotesNotifierProvider(meetingId));

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '获取会议笔记失败\n',
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
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('暂无会议笔记'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddNoteDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('添加笔记'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 标题和按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('会议笔记', style: Theme.of(context).textTheme.titleLarge),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNoteDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('添加笔记'),
                  ),
                ],
              ),
            ),

            // 笔记过滤选项
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: true,
                    onSelected: (selected) {
                      // TODO: 实现过滤功能
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('我的笔记'),
                    selected: false,
                    onSelected: (selected) {
                      // TODO: 实现过滤功能
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('已共享'),
                    selected: false,
                    onSelected: (selected) {
                      // TODO: 实现过滤功能
                    },
                  ),
                ],
              ),
            ),

            // 笔记列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _buildNoteCard(context, note, ref);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建笔记卡片
  Widget _buildNoteCard(BuildContext context, MeetingNote note, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDateTime =
        note.updatedAt != null
            ? dateFormat.format(note.updatedAt!)
            : dateFormat.format(note.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showNoteDetailDialog(context, note, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 笔记内容预览
              Text(
                note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              // 标签
              if (note.tags != null && note.tags!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      note.tags!.map((tag) {
                        return Chip(
                          label: Text(tag),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
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
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: '编辑',
                        onPressed:
                            () => _showEditNoteDialog(context, note, ref),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除',
                        onPressed:
                            () => _confirmDeleteNote(context, note.id, ref),
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

  // 显示添加笔记对话框
  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加笔记'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: contentController,
                    maxLines: 10,
                    minLines: 5,
                    decoration: const InputDecoration(
                      labelText: '笔记内容',
                      hintText: '在这里记录会议内容...',
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
                    value: false,
                    onChanged: (value) {
                      // 这里只是UI展示，实际值会在创建时获取
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
                  // 创建新笔记
                  List<String>? tags;
                  if (tagsController.text.isNotEmpty) {
                    tags =
                        tagsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                  }

                  final note = MeetingNote(
                    id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                    meetingId: meetingId,
                    content: contentController.text,
                    creatorId: 'current_user_id', // 应从用户状态获取
                    creatorName: '当前用户', // 应从用户状态获取
                    isShared: false,
                    createdAt: DateTime.now(),
                    tags: tags,
                  );

                  // 添加到会议笔记
                  final notifier = ref.read(
                    meetingNotesNotifierProvider(meetingId).notifier,
                  );
                  notifier.addNote(note);

                  Navigator.of(context).pop();
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  // 显示笔记详情对话框
  void _showNoteDetailDialog(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${note.creatorName}的笔记'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 创建/更新时间
                  Text(
                    '创建于: ${dateFormat.format(note.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (note.updatedAt != null)
                    Text(
                      '更新于: ${dateFormat.format(note.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                  const SizedBox(height: 16),

                  // 笔记内容
                  SelectableText(note.content),

                  if (note.tags != null && note.tags!.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    // 标签
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          note.tags!.map((tag) {
                            return Chip(
                              label: Text(tag),
                              labelStyle: const TextStyle(fontSize: 12),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // 分享按钮
              TextButton.icon(
                icon: Icon(
                  note.isShared ? Icons.share_outlined : Icons.share,
                  color: note.isShared ? Colors.grey : Colors.blue,
                ),
                label: Text(note.isShared ? '取消共享' : '共享'),
                onPressed: () {
                  // 切换共享状态
                  final notifier = ref.read(
                    meetingNotesNotifierProvider(meetingId).notifier,
                  );
                  notifier.shareNote(note.id, !note.isShared);
                  Navigator.of(context).pop();
                },
              ),
              // 编辑按钮
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('编辑'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditNoteDialog(context, note, ref);
                },
              ),
              // 关闭按钮
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  // 显示编辑笔记对话框
  void _showEditNoteDialog(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
  ) {
    final contentController = TextEditingController(text: note.content);
    final tagsController = TextEditingController(
      text: note.tags != null ? note.tags!.join(', ') : '',
    );
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

  // 确认删除笔记
  void _confirmDeleteNote(BuildContext context, String noteId, WidgetRef ref) {
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
  }
}
