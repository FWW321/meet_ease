import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting_agenda.dart';
import '../providers/meeting_process_providers.dart';

/// 会议议程列表组件
class AgendaListWidget extends HookConsumerWidget {
  final String meetingId;

  const AgendaListWidget({required this.meetingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从provider中获取议程
    final agendaAsync = ref.watch(meetingAgendaProvider(meetingId));

    return agendaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '获取会议议程失败\n',
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
      data: (agenda) {
        if (agenda.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('暂无会议议程'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddAgendaItemDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('添加议程项'),
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
                  Text('会议议程', style: Theme.of(context).textTheme.titleLarge),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAgendaItemDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('添加议程项'),
                  ),
                ],
              ),
            ),

            // 议程列表
            Expanded(
              child: ListView.builder(
                itemCount: agenda.items.length,
                itemBuilder: (context, index) {
                  final item = agenda.items[index];
                  return _buildAgendaItem(context, item, ref);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 构建议程项卡片
  Widget _buildAgendaItem(
    BuildContext context,
    AgendaItem item,
    WidgetRef ref,
  ) {
    final statusColor = getAgendaItemStatusColor(item.status);
    final statusText = getAgendaItemStatusText(item.status);
    final timeFormat = DateFormat('HH:mm');

    // 确保监听议程项以便在状态变化时更新UI
    ref.watch(agendaItemStatusNotifierProvider(item.id, meetingId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 标题
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 状态标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),

            // 描述
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // 时间信息
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 负责人和预计时长
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.speakerName != null &&
                          item.speakerName!.isNotEmpty)
                        Text(
                          '负责人: ${item.speakerName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        '预计时长: ${item.duration.inMinutes}分钟',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),

                  // 开始结束时间
                  if (item.startTime != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '开始时间: ${timeFormat.format(item.startTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.endTime != null)
                          Text(
                            '结束时间: ${timeFormat.format(item.endTime!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.status == AgendaItemStatus.pending)
                    _buildActionButton(
                      '开始',
                      Colors.green,
                      () => _updateAgendaItemStatus(
                        ref,
                        item.id,
                        AgendaItemStatus.inProgress,
                      ),
                    ),
                  if (item.status == AgendaItemStatus.inProgress) ...[
                    _buildActionButton(
                      '完成',
                      Colors.blue,
                      () => _updateAgendaItemStatus(
                        ref,
                        item.id,
                        AgendaItemStatus.completed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      '跳过',
                      Colors.orange,
                      () => _updateAgendaItemStatus(
                        ref,
                        item.id,
                        AgendaItemStatus.skipped,
                      ),
                    ),
                  ],
                  if (item.status == AgendaItemStatus.skipped)
                    _buildActionButton(
                      '重新开始',
                      Colors.blue,
                      () => _updateAgendaItemStatus(
                        ref,
                        item.id,
                        AgendaItemStatus.inProgress,
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed:
                        () => _showEditAgendaItemDialog(context, ref, item),
                    tooltip: '编辑议程项',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed:
                        () => _confirmDeleteAgendaItem(context, ref, item.id),
                    tooltip: '删除议程项',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建操作按钮
  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(text),
    );
  }

  // 更新议程项状态
  void _updateAgendaItemStatus(
    WidgetRef ref,
    String itemId,
    AgendaItemStatus status,
  ) async {
    final notifier = ref.read(
      agendaItemStatusNotifierProvider(itemId, meetingId).notifier,
    );
    await notifier.updateStatus(status);
  }

  // 显示添加议程项对话框
  void _showAddAgendaItemDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final speakerController = TextEditingController();
    int durationMinutes = 15;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('添加议程项'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '例如：项目进度回顾',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '描述 (可选)',
                      hintText: '例如：回顾上周项目进度，分析延期原因',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: speakerController,
                    decoration: const InputDecoration(
                      labelText: '负责人 (可选)',
                      hintText: '例如：张三',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('预计时长 (分钟)：'),
                      Expanded(
                        child: Slider(
                          value: durationMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: durationMinutes.toString(),
                          onChanged: (value) {
                            durationMinutes = value.round();
                            // 需要setState刷新UI
                          },
                        ),
                      ),
                      Text(durationMinutes.toString()),
                    ],
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
                  // TODO: 创建新议程项并保存
                  Navigator.of(context).pop();
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  // 显示编辑议程项对话框
  void _showEditAgendaItemDialog(
    BuildContext context,
    WidgetRef ref,
    AgendaItem item,
  ) {
    // 实现与添加类似，但需要预填充现有数据
  }

  // 确认删除议程项
  void _confirmDeleteAgendaItem(
    BuildContext context,
    WidgetRef ref,
    String itemId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个议程项吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 删除议程项
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }
}

// 根据状态获取颜色
Color getAgendaItemStatusColor(AgendaItemStatus status) {
  switch (status) {
    case AgendaItemStatus.pending:
      return Colors.grey;
    case AgendaItemStatus.inProgress:
      return Colors.blue;
    case AgendaItemStatus.completed:
      return Colors.green;
    case AgendaItemStatus.skipped:
      return Colors.orange;
  }
}

// 根据状态获取文本
String getAgendaItemStatusText(AgendaItemStatus status) {
  switch (status) {
    case AgendaItemStatus.pending:
      return '待开始';
    case AgendaItemStatus.inProgress:
      return '进行中';
    case AgendaItemStatus.completed:
      return '已完成';
    case AgendaItemStatus.skipped:
      return '已跳过';
  }
}
