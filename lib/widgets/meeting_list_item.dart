import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';

class MeetingListItem extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const MeetingListItem({
    required this.meeting,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM-dd HH:mm');
    final statusColor = getMeetingStatusColor(meeting.status);
    final statusText = getMeetingStatusText(meeting.status);
    final typeText = getMeetingTypeText(meeting.type);

    // 计算时间显示
    final now = DateTime.now();
    final startTime = meeting.startTime;
    final endTime = meeting.endTime;

    String timeDisplay;
    if (startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day) {
      // 今天的会议
      timeDisplay =
          '今天 ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    } else if (startTime.difference(now).inDays < 1 &&
        startTime.day == now.day + 1) {
      // 明天的会议
      timeDisplay =
          '明天 ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    } else {
      // 其他日期
      timeDisplay =
          '${dateFormat.format(startTime)} - ${dateFormat.format(endTime)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 会议标题和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meeting.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 时间
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(timeDisplay, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),

              // 地点
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.location,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 会议类型和组织者
              Row(
                children: [
                  Text(
                    typeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    meeting.organizerName,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (meeting.isSignedIn) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '已签到',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
