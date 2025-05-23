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

    // 获取主题
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题和关闭按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '添加笔记',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurface.withAlpha(179),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 内容区域
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 笔记名称输入
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: '笔记名称',
                                    hintText: '请输入笔记标题',
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.title,
                                      color: colorScheme.primary,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 笔记内容输入
                                Text(
                                  '笔记内容',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withAlpha(179),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: contentController,
                                    maxLines: 8,
                                    minLines: 5,
                                    style: textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: '在这里记录会议内容...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // 文件选择部分
                                Row(
                                  children: [
                                    Text(
                                      '附件:',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(
                                          179,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withAlpha(30),
                                            width: 0.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                try {
                                                  // 打开文件选择器
                                                  FilePickerResult? result =
                                                      await FilePicker.platform
                                                          .pickFiles(
                                                            type:
                                                                FileType.custom,
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
                                                      result
                                                              .files
                                                              .single
                                                              .path !=
                                                          null) {
                                                    if (!context.mounted)
                                                      return;
                                                    setState(() {
                                                      selectedFile = File(
                                                        result
                                                            .files
                                                            .single
                                                            .path!,
                                                      );
                                                      selectedFileName =
                                                          result
                                                              .files
                                                              .single
                                                              .name;
                                                    });
                                                  }
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '选择文件时出错: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.attach_file,
                                                      size: 14,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '选择文件',
                                                      style: textTheme.bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                colorScheme
                                                                    .primary,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (selectedFileName != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 1,
                                                height: 16,
                                                color: colorScheme.outline
                                                    .withAlpha(30),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                _getFileIcon(selectedFileName!),
                                                color: colorScheme.primary,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  selectedFileName!,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme
                                                                .onSurface,
                                                        fontSize: 12,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedFile = null;
                                                    selectedFileName = null;
                                                  });
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: colorScheme.error,
                                                  ),
                                                ),
                                              ),
                                            ] else
                                              Expanded(
                                                child: Text(
                                                  '支持: txt, pdf, doc, docx, md, xlsx, pptx',
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .onSurface
                                                            .withAlpha(179),
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 共享选项
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    title: Text(
                                      '与团队共享',
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(
                                          179,
                                        ),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '其他会议成员可以看到这个笔记',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withAlpha(
                                          179,
                                        ),
                                      ),
                                    ),
                                    value: isShared,
                                    onChanged: (value) {
                                      setState(() {
                                        isShared = value;
                                      });
                                    },
                                    activeColor: colorScheme.primary,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 底部按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                '取消',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            userIdAsync.when(
                              loading:
                                  () => const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              error:
                                  (_, __) => ElevatedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.error,
                                      foregroundColor: colorScheme.onError,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('出错了'),
                                  ),
                              data:
                                  (userId) => ElevatedButton(
                                    onPressed: () async {
                                      if (contentController.text.isEmpty &&
                                          selectedFile == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: colorScheme.error,
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('请输入笔记内容或选择文件'),
                                              ],
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      // 获取用户名
                                      final userName = await ref.read(
                                        userNameProvider(userId).future,
                                      );

                                      try {
                                        // 显示加载状态
                                        if (!context.mounted) return;
                                        final scaffoldMessenger =
                                            ScaffoldMessenger.of(context);
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            colorScheme
                                                                .onSurface,
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
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );

                                        final notifier = ref.read(
                                          meetingNotesNotifierProvider(
                                            meetingId,
                                          ).notifier,
                                        );

                                        if (selectedFile != null) {
                                          // 使用文件上传
                                          final meetingProcessService = ref
                                              .read(
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
                                        if (!context.mounted) return;
                                        Navigator.of(context).pop();

                                        // 显示成功消息
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green[300],
                                                ),
                                                const SizedBox(width: 16),
                                                selectedFile != null
                                                    ? const Text('文件上传成功')
                                                    : const Text('笔记已保存'),
                                              ],
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.green
                                                .withAlpha(26),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        // 隐藏之前的SnackBar
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).hideCurrentSnackBar();

                                        // 显示错误消息
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.error,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    selectedFile != null
                                                        ? '上传文件失败: $e'
                                                        : '保存笔记失败: $e',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.red
                                                .withAlpha(26),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            duration: const Duration(
                                              seconds: 5,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('保存'),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  /// 根据文件名获取适当的图标
  static IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
      case 'md':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }
}
