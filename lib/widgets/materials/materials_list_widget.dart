import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting_material.dart';
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

    return materialsAsync.when(
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
                const Text('暂无会议资料'),
                const SizedBox(height: 16),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    onPressed: () => _showAddMaterialDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('添加资料'),
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
                  Text('会议资料', style: Theme.of(context).textTheme.titleLarge),
                  if (!isReadOnly)
                    ElevatedButton.icon(
                      onPressed: () => _showAddMaterialDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('添加资料'),
                    ),
                ],
              ),
            ),

            // 资料列表
            Expanded(
              child: ListView.builder(
                itemCount: materials.items.length,
                itemBuilder: (context, index) {
                  final material = materials.items[index];
                  return MaterialsListItem(
                    material: material,
                    meetingId: meetingId,
                    isReadOnly: isReadOnly,
                  );
                },
              ),
            ),
          ],
        );
      },
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
