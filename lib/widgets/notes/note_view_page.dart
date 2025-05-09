import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../../models/meeting_note.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';
import 'note_edit_page.dart';

/// 笔记查看页面 - 全屏查看笔记内容
class NoteViewPage extends ConsumerStatefulWidget {
  final String noteId;
  final String meetingId;
  final MeetingNote? initialNote; // 可选的初始笔记数据

  const NoteViewPage({
    super.key,
    required this.noteId,
    required this.meetingId,
    this.initialNote,
  });

  @override
  ConsumerState<NoteViewPage> createState() => _NoteViewPageState();

  /// 导航到笔记查看页面
  static void navigate(
    BuildContext context,
    MeetingNote note,
    String meetingId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => NoteViewPage(
              noteId: note.id,
              meetingId: meetingId,
              initialNote: note,
            ),
      ),
    );
  }
}

class _NoteViewPageState extends ConsumerState<NoteViewPage> {
  late QuillController _quillController;
  bool _isLoading = true;
  MeetingNote? _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.initialNote;

    // 初始化一个空的QuillController，稍后会用实际内容更新
    _quillController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // 设置为只读模式
    _quillController.readOnly = true;

    // 如果有初始笔记数据，立即加载内容
    if (widget.initialNote != null) {
      _loadNoteContent(widget.initialNote!);
    }

    // 不论是否有初始数据，都从服务器获取最新笔记
    _fetchNoteDetails();
  }

  // 从服务器获取最新的笔记数据
  Future<void> _fetchNoteDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用Provider获取最新的笔记数据
      final noteDetail = await ref.read(
        noteDetailProvider(widget.noteId).future,
      );

      if (noteDetail != null) {
        setState(() {
          _currentNote = noteDetail;
        });
        _loadNoteContent(noteDetail);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取笔记详情失败: $e')));
      }
    }
  }

  // 加载笔记内容到QuillController
  void _loadNoteContent(MeetingNote note) {
    try {
      // 尝试解析JSON格式的富文本内容
      if (note.content.isNotEmpty) {
        final dynamic jsonData = jsonDecode(note.content);
        if (jsonData is List) {
          // 正确的Delta JSON格式
          _quillController = QuillController(
            document: Document.fromJson(jsonData),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          // JSON不是List格式，创建新文档并添加原始文本
          final document = Document();
          _quillController = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
          _quillController.document.insert(0, note.content);
        }
      } else {
        // 内容为空，创建空文档
        _quillController = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }

      // 设置为只读模式
      _quillController.readOnly = true;

      // 通知界面更新
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // JSON解析失败，创建新文档并添加原始文本
      final document = Document();
      _quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _quillController.document.insert(0, note.content);
      _quillController.readOnly = true;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentNote?.noteName ?? '笔记详情'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑笔记',
            onPressed: () {
              if (_currentNote != null) {
                // 跳转到编辑页面，并等待返回结果
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) => NoteEditPage(
                              note: _currentNote,
                              meetingId: widget.meetingId,
                            ),
                      ),
                    )
                    .then((_) {
                      // 编辑页面返回后，重新获取笔记详情
                      _fetchNoteDetails();
                    });
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentNote == null
              ? const Center(child: Text('笔记不存在或已被删除'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 富文本内容显示
                    Expanded(
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: QuillEditor.basic(
                            controller: _quillController,
                            config: const QuillEditorConfig(
                              padding: EdgeInsets.all(16),
                              autoFocus: false,
                              showCursor: false,
                              placeholder: '笔记内容为空',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
