import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../../models/meeting_note.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';

/// 笔记编辑页面 - 用于创建和编辑笔记
class NoteEditPage extends StatefulWidget {
  final MeetingNote? note; // 可为空，表示创建新笔记
  final String meetingId;
  final bool isNewNote; // 是否为新建笔记

  const NoteEditPage({
    super.key,
    this.note,
    required this.meetingId,
    this.isNewNote = false,
  });

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();

  /// 导航到编辑笔记页面
  static void navigate(
    BuildContext context,
    MeetingNote note,
    WidgetRef ref,
    String meetingId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditPage(note: note, meetingId: meetingId),
      ),
    );
  }

  /// 导航到创建笔记页面
  static void navigateToCreate(
    BuildContext context,
    String meetingId,
    WidgetRef ref,
  ) async {
    // 获取当前用户信息
    final userId = await ref.read(currentUserIdProvider.future);
    final userName = await ref.read(userNameProvider(userId).future);

    // 创建空笔记对象
    final newNote = MeetingNote(
      id: '', // ID由服务器生成
      meetingId: meetingId,
      content: '',
      creatorId: userId,
      creatorName: userName,
      isShared: false,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => NoteEditPage(
              note: newNote,
              meetingId: meetingId,
              isNewNote: true,
            ),
      ),
    );
  }
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController nameController;
  late bool isShared;
  late QuillController quillController;
  late FocusNode titleFocusNode;
  late FocusNode contentFocusNode;
  // 表单验证key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.note?.noteName ?? '');
    isShared = widget.note?.isShared ?? false;
    titleFocusNode = FocusNode();
    contentFocusNode = FocusNode();

    // 初始化QuillController，处理可能的JSON解析错误
    try {
      // 尝试解析JSON格式的富文本内容
      if (widget.note != null && widget.note!.content.isNotEmpty) {
        final dynamic jsonData = jsonDecode(widget.note!.content);
        if (jsonData is List) {
          // 正确的Delta JSON格式
          quillController = QuillController(
            document: Document.fromJson(jsonData),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          // JSON不是List格式，创建新文档并添加原始文本
          final document = Document();
          quillController = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
          quillController.document.insert(0, widget.note!.content);
        }
      } else {
        // 内容为空，创建空文档
        quillController = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      // 确保编辑器不是只读的
      quillController.readOnly = false;
    } catch (e) {
      // JSON解析失败，创建新文档并添加原始文本
      final document = Document();
      quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
      if (widget.note != null) {
        quillController.document.insert(0, widget.note!.content);
      }
      quillController.readOnly = false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    quillController.dispose();
    titleFocusNode.dispose();
    contentFocusNode.dispose();
    super.dispose();
  }

  void _saveNote(BuildContext context, WidgetRef ref) {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 先取消当前输入框焦点，确保内容已保存
      FocusScope.of(context).unfocus();

      // 获取富文本内容的JSON格式
      final contentJson = jsonEncode(
        quillController.document.toDelta().toJson(),
      );

      if (widget.isNewNote) {
        // 创建新笔记
        final newNote = widget.note!.copyWith(
          content: contentJson,
          noteName: nameController.text,
          isShared: isShared,
          tags: null, // 不使用标签
          createdAt: DateTime.now(),
        );

        // 保存新笔记
        final notifier = ref.read(
          meetingNotesNotifierProvider(widget.meetingId).notifier,
        );
        notifier.addNote(newNote);
      } else {
        // 更新笔记
        final updatedNote = widget.note!.copyWith(
          content: contentJson,
          noteName: nameController.text,
          isShared: isShared,
          tags: null, // 不使用标签
          updatedAt: DateTime.now(),
        );

        // 保存更新
        final notifier = ref.read(
          meetingNotesNotifierProvider(widget.meetingId).notifier,
        );
        notifier.updateNote(updatedNote);
      }

      Navigator.of(context).pop();
    } catch (e) {
      // 保存失败时显示错误提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存笔记失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取主题颜色
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 检测是否为小屏幕设备
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewNote ? '创建笔记' : '编辑笔记'),
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        foregroundColor: colorScheme.primary,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return TextButton.icon(
                onPressed: () => _saveNote(context, ref),
                icon: const Icon(Icons.save),
                label: const Text('保存'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 笔记名称输入
                    Text(
                      '笔记标题',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      focusNode: titleFocusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '请输入笔记标题',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '笔记标题不能为空';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 笔记内容标签
                    Text(
                      '笔记内容',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 使用精简版富文本工具栏
                    if (isSmallScreen)
                      // 小屏幕版本 - 紧凑型工具栏
                      Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        // 使用SingleChildScrollView包裹工具栏使其可以滚动
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              // 基础格式按钮
                              QuillToolbarToggleStyleButton(
                                attribute: Attribute.bold,
                                controller: quillController,
                                options:
                                    const QuillToolbarToggleStyleButtonOptions(
                                      iconData: Icons.format_bold,
                                      tooltip: '粗体',
                                    ),
                              ),
                              QuillToolbarToggleStyleButton(
                                attribute: Attribute.italic,
                                controller: quillController,
                                options:
                                    const QuillToolbarToggleStyleButtonOptions(
                                      iconData: Icons.format_italic,
                                      tooltip: '斜体',
                                    ),
                              ),
                              QuillToolbarToggleStyleButton(
                                attribute: Attribute.underline,
                                controller: quillController,
                                options:
                                    const QuillToolbarToggleStyleButtonOptions(
                                      iconData: Icons.format_underline,
                                      tooltip: '下划线',
                                    ),
                              ),

                              const VerticalDivider(
                                indent: 8,
                                endIndent: 8,
                                width: 16,
                              ),

                              // 列表按钮
                              QuillToolbarToggleStyleButton(
                                attribute: Attribute.ol,
                                controller: quillController,
                                options:
                                    const QuillToolbarToggleStyleButtonOptions(
                                      iconData: Icons.format_list_numbered,
                                      tooltip: '有序列表',
                                    ),
                              ),
                              QuillToolbarToggleStyleButton(
                                attribute: Attribute.ul,
                                controller: quillController,
                                options:
                                    const QuillToolbarToggleStyleButtonOptions(
                                      iconData: Icons.format_list_bulleted,
                                      tooltip: '无序列表',
                                    ),
                              ),

                              const VerticalDivider(
                                indent: 8,
                                endIndent: 8,
                                width: 16,
                              ),

                              // 缩进按钮
                              QuillToolbarIndentButton(
                                controller: quillController,
                                isIncrease: false,
                                options: const QuillToolbarIndentButtonOptions(
                                  tooltip: '减少缩进',
                                ),
                              ),
                              QuillToolbarIndentButton(
                                controller: quillController,
                                isIncrease: true,
                                options: const QuillToolbarIndentButtonOptions(
                                  tooltip: '增加缩进',
                                ),
                              ),

                              const VerticalDivider(
                                indent: 8,
                                endIndent: 8,
                                width: 16,
                              ),

                              // 颜色按钮
                              QuillToolbarColorButton(
                                controller: quillController,
                                isBackground: false,
                                options: const QuillToolbarColorButtonOptions(
                                  tooltip: '文字颜色',
                                ),
                              ),

                              // 标题下拉菜单
                              QuillToolbarSelectHeaderStyleDropdownButton(
                                controller: quillController,
                                options:
                                    const QuillToolbarSelectHeaderStyleDropdownButtonOptions(),
                              ),

                              // 清除格式按钮
                              QuillToolbarClearFormatButton(
                                controller: quillController,
                                options:
                                    const QuillToolbarClearFormatButtonOptions(
                                      tooltip: '清除格式',
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // 大屏幕版本 - 标准工具栏
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: QuillSimpleToolbar(
                          controller: quillController,
                          config: const QuillSimpleToolbarConfig(
                            showAlignmentButtons: true,
                            showFontSize: true,
                            showBoldButton: true,
                            showItalicButton: true,
                            showUnderLineButton: true,
                            showStrikeThrough: true,
                            showColorButton: true,
                            showBackgroundColorButton: true,
                            showListBullets: true,
                            showListNumbers: true,
                            showIndent: true,
                            showHeaderStyle: true,
                            showClearFormat: true,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // 使用QuillEditor - 在页面中给予更大的空间
                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          // 确保编辑器获取焦点
                          contentFocusNode.requestFocus();
                        },
                        child: QuillEditor.basic(
                          controller: quillController,
                          focusNode: contentFocusNode,
                          config: const QuillEditorConfig(
                            placeholder: '在这里编辑笔记内容...',
                            padding: EdgeInsets.all(16),
                            autoFocus: false,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 共享开关
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SwitchListTile(
                        title: const Text('与团队共享'),
                        subtitle: const Text('其他会议成员可以看到这个笔记'),
                        value: isShared,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setState(() {
                            isShared = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
