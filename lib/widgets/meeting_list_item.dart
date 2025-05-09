import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting.dart';
import '../providers/user_providers.dart';

class MeetingListItem extends ConsumerWidget {
  final Meeting meeting;
  final VoidCallback onTap;
  final String? matchScore;
  final bool showParticipationInfo;

  const MeetingListItem({
    required this.meeting,
    required this.onTap,
    this.matchScore,
    this.showParticipationInfo = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MM-dd HH:mm');
    final statusColor = getMeetingStatusColor(meeting.status);
    final statusText = getMeetingStatusText(meeting.status);
    final typeText = getMeetingTypeText(meeting.type);
    final visibilityText = getMeetingVisibilityText(meeting.visibility);

    // 获取组织者用户名
    final userNameAsync = ref.watch(userNameProvider(meeting.organizerId));

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

    // 获取可见性图标和颜色
    IconData visibilityIcon;
    Color visibilityColor;
    switch (meeting.visibility) {
      case MeetingVisibility.public:
        visibilityIcon = Icons.public;
        visibilityColor = Colors.green;
        break;
      case MeetingVisibility.private:
        visibilityIcon = Icons.lock;
        visibilityColor = Colors.red;
        break;
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
                      color: statusColor.withAlpha(25),
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

              // 会议类型、可见性和组织者
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      const SizedBox(width: 8),
                      // 会议可见性
                      Icon(visibilityIcon, size: 16, color: visibilityColor),
                      const SizedBox(width: 4),
                      Text(
                        visibilityText,
                        style: TextStyle(
                          fontSize: 12,
                          color: visibilityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      // 动态显示组织者姓名，使用Expanded防止溢出
                      Expanded(
                        child: userNameAsync.when(
                          data:
                              (name) => Text(
                                name,
                                style: const TextStyle(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          loading:
                              () => const SizedBox(
                                width: 40,
                                height: 12,
                                child: LinearProgressIndicator(),
                              ),
                          error:
                              (_, __) => Text(
                                meeting.organizerName,
                                style: const TextStyle(color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        ),
                      ),
                      if (meeting.isSignedIn) ...[
                        const SizedBox(width: 8),
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

                  // 显示匹配度（移到单独一行）
                  if (matchScore != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.recommend,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '匹配度: $matchScore',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // 显示参会信息（如果有）
              if (showParticipationInfo &&
                  meeting.participationInfo != null) ...[
                const Divider(height: 24),

                // 签到状态 - 只为私有会议显示
                if (meeting.visibility == MeetingVisibility.private &&
                        meeting
                            .participationInfo!['signInStatus']
                            ?.isNotEmpty ??
                    false) ...[
                  Row(
                    children: [
                      Icon(
                        meeting.participationInfo!['signInStatus'] == '已签到'
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color:
                            meeting.participationInfo!['signInStatus'] == '已签到'
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '签到状态: ${meeting.participationInfo!['signInStatus']}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              meeting.participationInfo!['signInStatus'] ==
                                      '已签到'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // 参会时间
                if (meeting.participationInfo!['joinTime']?.isNotEmpty ??
                    false) ...[
                  Row(
                    children: [
                      const Icon(Icons.login, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '加入: ${_formatParticipationTime(meeting.participationInfo!['joinTime'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // 离开时间
                if (meeting.participationInfo!['leaveTime']?.isNotEmpty ??
                    false) ...[
                  Row(
                    children: [
                      const Icon(Icons.logout, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '离开: ${_formatParticipationTime(meeting.participationInfo!['leaveTime'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // 参会时长
                if (meeting.participationInfo!['durationDisplay']?.isNotEmpty ??
                    false) ...[
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '时长: ${meeting.participationInfo!['durationDisplay']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 格式化参会时间
  String _formatParticipationTime(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return timeStr;
    }
  }
}
