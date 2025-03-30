import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting_material.dart' as models;
import '../providers/meeting_process_providers.dart';

/// 会议资料列表组件
class MaterialsListWidget extends HookConsumerWidget {
  final String meetingId;

  const MaterialsListWidget({required this.meetingId, super.key});

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
                  return _buildMaterialItem(context, material, ref);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建资料项卡片
  Widget _buildMaterialItem(
    BuildContext context,
    models.MaterialItem material,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final fileSizeText =
        material.fileSize != null
            ? _formatFileSize(material.fileSize!)
            : '未知大小';
    final typeIcon = _getMaterialTypeIcon(material.type);
    final typeColor = _getMaterialTypeColor(material.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _openMaterial(context, material),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 资料类型图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(typeIcon, color: typeColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 资料信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (material.description != null &&
                            material.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              material.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              if (material.uploaderName != null)
                                Text(
                                  '${material.uploaderName} · ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (material.uploadTime != null)
                                Text(
                                  '${dateFormat.format(material.uploadTime!)} · ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                fileSizeText,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openMaterial(context, material),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('打开'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _downloadMaterial(context, material),
                      icon: const Icon(Icons.download),
                      label: const Text('下载'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () =>
                              _confirmDeleteMaterial(context, ref, material.id),
                      tooltip: '删除资料',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示添加资料对话框
  void _showAddMaterialDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    models.MaterialType selectedType = models.MaterialType.document;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加资料'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '例如：项目进度报告',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '描述 (可选)',
                      hintText: '例如：详细的项目进度统计报告',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<models.MaterialType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: '资料类型'),
                    items: [
                      DropdownMenuItem(
                        value: models.MaterialType.document,
                        child: Row(
                          children: [
                            Icon(
                              _getMaterialTypeIcon(
                                models.MaterialType.document,
                              ),
                              color: _getMaterialTypeColor(
                                models.MaterialType.document,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('文档'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: models.MaterialType.image,
                        child: Row(
                          children: [
                            Icon(
                              _getMaterialTypeIcon(models.MaterialType.image),
                              color: _getMaterialTypeColor(
                                models.MaterialType.image,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('图片'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: models.MaterialType.video,
                        child: Row(
                          children: [
                            Icon(
                              _getMaterialTypeIcon(models.MaterialType.video),
                              color: _getMaterialTypeColor(
                                models.MaterialType.video,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('视频'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: models.MaterialType.presentation,
                        child: Row(
                          children: [
                            Icon(
                              _getMaterialTypeIcon(
                                models.MaterialType.presentation,
                              ),
                              color: _getMaterialTypeColor(
                                models.MaterialType.presentation,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('演示文稿'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: models.MaterialType.other,
                        child: Row(
                          children: [
                            Icon(
                              _getMaterialTypeIcon(models.MaterialType.other),
                              color: _getMaterialTypeColor(
                                models.MaterialType.other,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('其他'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedType = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 实现选择文件的功能
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('选择文件'),
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
                  // TODO: 添加资料到会议并上传文件
                  final newMaterial = models.MaterialItem(
                    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text,
                    description:
                        descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                    type: selectedType,
                    url: 'https://example.com/materials/temp.file',
                    thumbnailUrl:
                        selectedType == models.MaterialType.image ||
                                selectedType == models.MaterialType.video
                            ? 'https://example.com/thumbnails/temp.jpg'
                            : null,
                    fileSize: 1024 * 1024, // 示例大小：1MB
                    uploaderId: 'current_user_id', // 应从用户状态获取
                    uploaderName: '当前用户', // 应从用户状态获取
                    uploadTime: DateTime.now(),
                  );

                  // 添加资料
                  final notifier = ref.read(
                    meetingMaterialsNotifierProvider(meetingId).notifier,
                  );
                  notifier.addMaterial(newMaterial);

                  Navigator.of(context).pop();
                },
                child: const Text('上传'),
              ),
            ],
          ),
    );
  }

  // 确认删除资料
  void _confirmDeleteMaterial(
    BuildContext context,
    WidgetRef ref,
    String materialId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个资料吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final notifier = ref.read(
                    meetingMaterialsNotifierProvider(meetingId).notifier,
                  );
                  notifier.removeMaterial(materialId);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  // 打开资料
  void _openMaterial(BuildContext context, models.MaterialItem material) {
    // TODO: 实现打开资料的功能，可以使用url_launcher包
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('正在打开: ${material.title}')));
  }

  // 下载资料
  void _downloadMaterial(BuildContext context, models.MaterialItem material) {
    // TODO: 实现下载资料的功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('正在下载: ${material.title}')));
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // 获取资料类型图标
  IconData _getMaterialTypeIcon(models.MaterialType type) {
    switch (type) {
      case models.MaterialType.document:
        return Icons.insert_drive_file;
      case models.MaterialType.image:
        return Icons.image;
      case models.MaterialType.video:
        return Icons.videocam;
      case models.MaterialType.presentation:
        return Icons.slideshow;
      case models.MaterialType.other:
        return Icons.attachment;
    }
  }

  // 获取资料类型颜色
  Color _getMaterialTypeColor(models.MaterialType type) {
    switch (type) {
      case models.MaterialType.document:
        return Colors.blue;
      case models.MaterialType.image:
        return Colors.green;
      case models.MaterialType.video:
        return Colors.red;
      case models.MaterialType.presentation:
        return Colors.orange;
      case models.MaterialType.other:
        return Colors.grey;
    }
  }
}
