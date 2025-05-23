import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/meeting_process_providers.dart';
import 'materials_list_item.dart';
import 'add_material_dialog.dart';

/// 会议资料列表组件
class MaterialsListWidget extends ConsumerWidget {
  final String meetingId;
  final bool isReadOnly;

  const MaterialsListWidget({
    required this.meetingId,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(
      meetingMaterialsNotifierProvider(meetingId),
    );

    return Stack(
      children: [
        materialsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: SelectableText.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '获取会议资料失败\n',
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
          data: (materials) {
            if (materials.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(102),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无会议资料',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: materials.items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final material = materials.items[index];
                return MaterialsListItem(
                  material: material,
                  meetingId: meetingId,
                  isReadOnly: isReadOnly,
                );
              },
            );
          },
        ),

        // 右下角悬浮添加按钮
        if (!isReadOnly)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddMaterialDialog(context, ref),
              tooltip: '添加资料',
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  // 显示添加资料对话框
  void _showAddMaterialDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddMaterialDialog(meetingId: meetingId),
    );
  }
}
