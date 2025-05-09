import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/meeting_note.dart';
import '../providers/meeting_process_providers.dart';
import '../providers/user_providers.dart';
import '../services/meeting_process_service.dart';

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

    return Stack(
      children: [
        notesAsync.when(
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
                    Icon(
                      Icons.note_alt_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无会议笔记',
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

            return Column(
              children: [
                // 笔记过滤选项
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
        ),

        // 右下角悬浮添加按钮
        if (!isReadOnly)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddNoteDialog(context, ref),
              tooltip: '添加笔记',
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  // 构建笔记卡片
  Widget _buildNoteCard(BuildContext context, MeetingNote note, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final formattedDateTime =
        note.updatedAt != null
            ? dateFormat.format(note.updatedAt!)
            : dateFormat.format(note.createdAt);

    // 检查笔记创建者是否为当前用户
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showNoteDetailDialog(context, note, ref),
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
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
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
                            return Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: '删除',
                                  onPressed:
                                      () => _confirmDeleteNote(
                                        context,
                                        note.id,
                                        ref,
                                      ),
                                ),
                              ],
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

  // 显示添加笔记对话框
  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    final nameController = TextEditingController();
    bool isShared = false;
    File? selectedFile;
    String? selectedFileName;

    // 使用当前用户ID提供者获取当前用户ID
    final userIdAsync = ref.watch(currentUserIdProvider);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('添加笔记'),
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

                        // 笔记内容输入
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

                        // 文件选择按钮
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  // 打开文件选择器
                                  FilePickerResult? result = await FilePicker
                                      .platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          'txt',
                                          'pdf',
                                          'doc',
                                          'docx',
                                          'md',
                                          'xlsx',
                                          'pptx',
                                        ],
                                      );

                                  if (result != null &&
                                      result.files.single.path != null) {
                                    setState(() {
                                      selectedFile = File(
                                        result.files.single.path!,
                                      );
                                      selectedFileName =
                                          result.files.single.name;
                                    });
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('选择文件时出错: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.attach_file),
                              label: const Text('选择文件'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child:
                                  selectedFileName != null
                                      ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedFileName!,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            '支持: txt, pdf, doc, docx, md, xlsx, pptx',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            '未选择文件',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '支持: txt, pdf, doc, docx, md, xlsx, pptx',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                            if (selectedFileName != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    selectedFile = null;
                                    selectedFileName = null;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 标签输入
                        TextField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: '标签 (用逗号分隔)',
                            hintText: '例如: 任务,讨论,决定',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 共享选项
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
                    userIdAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error:
                          (_, __) => ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('出错了'),
                          ),
                      data:
                          (userId) => ElevatedButton(
                            onPressed: () async {
                              if (contentController.text.isEmpty &&
                                  selectedFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入笔记内容或选择文件')),
                                );
                                return;
                              }

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

                              // 获取用户名
                              final userName = await ref.read(
                                userNameProvider(userId).future,
                              );

                              try {
                                // 显示加载状态
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        selectedFile != null
                                            ? const Text('正在上传文件...')
                                            : const Text('正在保存笔记...'),
                                      ],
                                    ),
                                    duration: const Duration(
                                      seconds: 30,
                                    ), // 较长的持续时间，操作完成后会自动关闭
                                  ),
                                );

                                final notifier = ref.read(
                                  meetingNotesNotifierProvider(
                                    meetingId,
                                  ).notifier,
                                );

                                if (selectedFile != null) {
                                  // 使用文件上传
                                  final meetingProcessService = ref.read(
                                    meetingProcessServiceProvider,
                                  );
                                  if (meetingProcessService
                                      is ApiMeetingProcessService) {
                                    // 获取API服务实例
                                    await meetingProcessService
                                        .addMeetingNoteByFile(
                                          meetingId,
                                          userId,
                                          userName,
                                          selectedFile!,
                                          isShared,
                                          tags,
                                          nameController.text,
                                        );

                                    // 刷新笔记列表
                                    await notifier.refreshNotes();
                                  } else {
                                    throw Exception('不支持文件上传功能');
                                  }
                                } else {
                                  // 创建笔记对象
                                  final note = MeetingNote(
                                    id:
                                        'temp_${DateTime.now().millisecondsSinceEpoch}', // 临时ID，服务器会返回真实ID
                                    meetingId: meetingId,
                                    content: contentController.text,
                                    noteName: nameController.text,
                                    creatorId: userId,
                                    creatorName: userName,
                                    isShared: isShared,
                                    createdAt: DateTime.now(),
                                    tags: tags,
                                  );

                                  // 普通笔记添加
                                  await notifier.addNote(note);
                                }

                                // 关闭之前的SnackBar
                                scaffoldMessenger.hideCurrentSnackBar();

                                // 关闭对话框
                                Navigator.of(context).pop();

                                // 显示成功消息
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 16),
                                        selectedFile != null
                                            ? const Text('文件上传成功')
                                            : const Text('笔记已保存'),
                                      ],
                                    ),
                                  ),
                                );
                              } catch (e) {
                                // 隐藏之前的SnackBar
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();

                                // 显示错误消息
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            selectedFile != null
                                                ? '上传文件失败: $e'
                                                : '保存笔记失败: $e',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[100],
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                            child: const Text('保存'),
                          ),
                    ),
                  ],
                ),
          ),
    );
  }

  // 显示笔记详情对话框
  void _showNoteDetailDialog(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
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

                          if (currentNote.tags != null &&
                              currentNote.tags!.isNotEmpty) ...[
                            const SizedBox(height: 16),

                            // 标签
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  currentNote.tags!.map((tag) {
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
                                    _showEditNoteDialog(
                                      context,
                                      currentNote,
                                      ref,
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

  // 确认删除笔记
  void _confirmDeleteNote(BuildContext context, String noteId, WidgetRef ref) {
    // 首先检查当前用户是否是笔记作者
    ref.read(currentUserIdProvider.future).then((currentUserId) {
      // 获取要删除的笔记
      ref.read(noteDetailProvider(noteId).future).then((note) {
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
