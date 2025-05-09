import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../models/meeting_note.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/meeting_process_service.dart';

/// 添加笔记对话框
class NoteAddDialog {
  /// 显示添加笔记对话框
  static void show(BuildContext context, WidgetRef ref, String meetingId) {
    final contentController = TextEditingController();
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
                                          null, // 不使用标签
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
                                    tags: null, // 不使用标签
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
}
