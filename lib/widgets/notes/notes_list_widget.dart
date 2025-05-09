import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/meeting_process_providers.dart';
import '../../providers/user_providers.dart';
import 'note_card_widget.dart';
import 'note_edit_page.dart';
import 'empty_notes_widget.dart';
import 'notes_filter_widget.dart';

/// 会议笔记列表组件
class NotesListWidget extends ConsumerStatefulWidget {
  final String meetingId;
  final bool isReadOnly;

  const NotesListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  ConsumerState<NotesListWidget> createState() => _NotesListWidgetState();
}

class _NotesListWidgetState extends ConsumerState<NotesListWidget> {
  NoteFilterOption _selectedFilter = NoteFilterOption.all;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      meetingNotesNotifierProvider(widget.meetingId),
    );

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
              return const EmptyNotesWidget();
            }

            // 根据筛选条件过滤笔记
            final filteredNotes = _filterNotes(notes);

            return Column(
              children: [
                // 笔记过滤选项
                NotesFilterWidget(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),

                // 笔记列表
                Expanded(
                  child:
                      filteredNotes.isEmpty
                          ? const Center(child: Text('没有符合筛选条件的笔记'))
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return NoteCardWidget(
                                note: note,
                                meetingId: widget.meetingId,
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),

        // 右下角悬浮添加按钮
        if (!widget.isReadOnly)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed:
                  () => NoteEditPage.navigateToCreate(
                    context,
                    widget.meetingId,
                    ref,
                  ),
              tooltip: '添加笔记',
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  // 根据选择的过滤条件筛选笔记
  List<dynamic> _filterNotes(List<dynamic> notes) {
    if (_selectedFilter == NoteFilterOption.all) {
      return notes;
    }

    final currentUserIdValue = ref.read(currentUserIdProvider).valueOrNull;
    if (currentUserIdValue == null) {
      return notes; // 如果无法获取当前用户ID，则返回所有笔记
    }

    switch (_selectedFilter) {
      case NoteFilterOption.mine:
        return notes
            .where((note) => note.creatorId == currentUserIdValue)
            .toList();
      case NoteFilterOption.shared:
        return notes.where((note) => note.isShared).toList();
      default:
        return notes;
    }
  }
}
