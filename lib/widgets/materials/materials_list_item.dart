import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/meeting_material.dart';
import 'material_utils.dart';
import 'material_actions.dart';

/// 会议资料列表项组件
class MaterialsListItem extends ConsumerWidget {
  final String meetingId;
  final MaterialItem material;
  final bool isReadOnly;

  const MaterialsListItem({
    required this.meetingId,
    required this.material,
    this.isReadOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final fileSizeText =
        material.fileSize != null
            ? MaterialUtils.formatFileSize(material.fileSize!)
            : '未知大小';
    final typeIcon = MaterialUtils.getMaterialTypeIcon(material.type);
    final typeColor = MaterialUtils.getMaterialTypeColor(material.type);

    return FutureBuilder<bool>(
      future: MaterialUtils.isFileDownloaded(material),
      builder: (context, snapshot) {
        final bool isDownloaded = snapshot.data ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              if (isDownloaded) {
                // 如果已下载，打开文件所在文件夹
                MaterialActions.openDownloadedMaterial(context, material, ref);
              } else {
                // 如果未下载，则下载文件
                MaterialActions.downloadMaterial(
                  context,
                  material,
                  ref,
                  meetingId,
                );
              }
            },
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
                          color: typeColor.withAlpha(26), // 10% 透明度
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
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (material.uploadTime != null)
                                    Text(
                                      '${dateFormat.format(material.uploadTime!)} · ',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  Text(
                                    fileSizeText,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isReadOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isDownloaded)
                            // 如果已下载，显示"已下载"状态
                            OutlinedButton.icon(
                              onPressed:
                                  () => MaterialActions.openDownloadedMaterial(
                                    context,
                                    material,
                                    ref,
                                  ),
                              icon: const Icon(Icons.folder_open),
                              label: const Text('已下载'),
                            )
                          else
                            // 如果未下载，显示下载按钮
                            OutlinedButton.icon(
                              onPressed:
                                  () => MaterialActions.downloadMaterial(
                                    context,
                                    material,
                                    ref,
                                    meetingId,
                                  ),
                              icon: const Icon(Icons.download),
                              label: const Text('下载'),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed:
                                () => MaterialActions.confirmDeleteMaterial(
                                  context,
                                  ref,
                                  material.id,
                                  meetingId,
                                ),
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
      },
    );
  }
}
