import 'package:flutter/material.dart';

/// 笔记过滤选项状态
enum NoteFilterOption { all, mine, shared }

/// 笔记过滤选项组件
class NotesFilterWidget extends StatelessWidget {
  final NoteFilterOption selectedFilter;
  final Function(NoteFilterOption) onFilterChanged;

  const NotesFilterWidget({
    required this.selectedFilter,
    required this.onFilterChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('全部'),
            selected: selectedFilter == NoteFilterOption.all,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(NoteFilterOption.all);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('我的笔记'),
            selected: selectedFilter == NoteFilterOption.mine,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(NoteFilterOption.mine);
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('已共享'),
            selected: selectedFilter == NoteFilterOption.shared,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(NoteFilterOption.shared);
              }
            },
          ),
        ],
      ),
    );
  }
}
