import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';

/// 会议时间选择组件
class MeetingTimeSelector extends StatelessWidget {
  final ValueNotifier<DateTime> startDateNotifier;
  final ValueNotifier<DateTime> endDateNotifier;

  const MeetingTimeSelector({
    super.key,
    required this.startDateNotifier,
    required this.endDateNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算预估会议时长
    final duration = endDateNotifier.value.difference(startDateNotifier.value);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText =
        hours > 0
            ? '$hours小时${minutes > 0 ? ' $minutes分钟' : ''}'
            : '$minutes分钟';

    // 判断会议时间是否合理
    final bool isValidDuration = duration.inMinutes >= 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 开始时间选择
        InkWell(
          onTap: () => _selectDateTime(context, startDateNotifier, true),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '开始时间 *',
              prefixIcon: Icon(Icons.event, color: theme.colorScheme.primary),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(startDateNotifier.value),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),

        // 结束时间选择
        InkWell(
          onTap: () => _selectDateTime(context, endDateNotifier, false),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '结束时间 *',
              prefixIcon: Icon(
                Icons.event_busy,
                color: theme.colorScheme.primary,
              ),
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(endDateNotifier.value),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),

        // 会议时长显示
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            border: Border.all(
              color:
                  isValidDuration
                      ? theme.colorScheme.outline.withAlpha(26)
                      : theme.colorScheme.error.withAlpha(128),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isValidDuration ? Icons.timelapse : Icons.warning_amber_rounded,
                size: 18,
                color:
                    isValidDuration
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Text(
                  isValidDuration ? '预计会议时长: $durationText' : '会议时长太短，至少需要15分钟',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isValidDuration
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 选择日期和时间
  Future<void> _selectDateTime(
    BuildContext context,
    ValueNotifier<DateTime> dateNotifier,
    bool isStartTime,
  ) async {
    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateNotifier.value,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStartTime ? '选择开始日期' : '选择结束日期',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (pickedDate == null || !context.mounted) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateNotifier.value),
      helpText: isStartTime ? '选择开始时间' : '选择结束时间',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (pickedTime == null || !context.mounted) return;

    // 更新日期时间
    final DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // 如果是结束时间，确保不早于开始时间
    if (!isStartTime && newDateTime.isBefore(startDateNotifier.value)) {
      // 设置结束时间为开始时间后1小时
      dateNotifier.value = startDateNotifier.value.add(
        const Duration(hours: 1),
      );
      return;
    }

    // 如果是开始时间，确保不晚于结束时间
    if (isStartTime && newDateTime.isAfter(endDateNotifier.value)) {
      // 同时更新结束时间，保持至少1小时会议时长
      dateNotifier.value = newDateTime;
      endDateNotifier.value = newDateTime.add(const Duration(hours: 1));
      return;
    }

    dateNotifier.value = newDateTime;
  }
}
