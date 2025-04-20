import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 聊天日期分隔线组件
class ChatDateSeparator extends StatelessWidget {
  final DateTime timestamp;

  const ChatDateSeparator({required this.timestamp, super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final date = dateFormat.format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
