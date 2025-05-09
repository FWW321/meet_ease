import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 开始时间选择
        InkWell(
          onTap: () => _selectDateTime(context, startDateNotifier, true),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '开始时间',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
            child: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(startDateNotifier.value),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 结束时间选择
        InkWell(
          onTap: () => _selectDateTime(context, endDateNotifier, false),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '结束时间',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
            ),
            child: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(endDateNotifier.value),
            ),
          ),
        ),

        // 时间验证错误提示
        if (endDateNotifier.value.isBefore(startDateNotifier.value) ||
            endDateNotifier.value.isAtSameMomentAs(startDateNotifier.value))
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0),
            child: Text(
              '结束时间必须晚于开始时间',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // 检查会议时长是否合理
        if (endDateNotifier.value
                .difference(startDateNotifier.value)
                .inMinutes <
            15)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0),
            child: Text(
              '会议时长至少需要15分钟',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        if (endDateNotifier.value.difference(startDateNotifier.value).inHours >
            24)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0),
            child: Text(
              '会议时长不建议超过24小时',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // 选择日期和时间
  Future<void> _selectDateTime(
    BuildContext context,
    ValueNotifier<DateTime> dateTimeNotifier,
    bool isStartTime,
  ) async {
    final DateTime initialDate = dateTimeNotifier.value;

    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          isStartTime
              ? DateTime.now() // 开始时间不早于当前时间
              : startDateNotifier.value, // 结束时间不早于开始时间
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    if (!context.mounted) return;

    // 选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;
    if (!context.mounted) return;

    // 组合日期和时间
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // 对于结束时间，确保它不早于开始时间
    if (!isStartTime && newDateTime.isBefore(startDateNotifier.value)) {
      // 如果用户选择的结束时间早于开始时间，则显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('结束时间不能早于开始时间'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    dateTimeNotifier.value = newDateTime;
  }
}
