import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';
import 'meeting_process_page.dart';

class MeetingDetailPage extends ConsumerWidget {
  final String meetingId;

  const MeetingDetailPage({required this.meetingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取会议详情
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));
    // 获取签到状态
    final signInStatusAsync = ref.watch(meetingSignInProvider(meetingId));

    return Scaffold(
      appBar: AppBar(title: const Text('会议详情')),
      body: meetingAsync.when(
        data:
            (meeting) =>
                _buildMeetingDetail(context, meeting, signInStatusAsync, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '获取会议详情失败\n',
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
      ),
    );
  }

  // 构建会议详情内容
  Widget _buildMeetingDetail(
    BuildContext context,
    Meeting meeting,
    AsyncValue<bool> signInStatusAsync,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final statusColor = getMeetingStatusColor(meeting.status);
    final statusText = getMeetingStatusText(meeting.status);
    final typeText = getMeetingTypeText(meeting.type);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 会议标题
          Text(meeting.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // 会议状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Text(statusText, style: TextStyle(color: statusColor)),
          ),
          const SizedBox(height: 24),

          // 会议基本信息
          _buildInfoItem(context, '开始时间', dateFormat.format(meeting.startTime)),
          _buildInfoItem(context, '结束时间', dateFormat.format(meeting.endTime)),
          _buildInfoItem(context, '会议地点', meeting.location),
          _buildInfoItem(context, '会议类型', typeText),
          _buildInfoItem(context, '组织者', meeting.organizerName),
          _buildInfoItem(context, '参会人数', '${meeting.participantCount}人'),
          if (meeting.description != null && meeting.description!.isNotEmpty)
            _buildInfoItem(context, '会议描述', meeting.description!),
          const SizedBox(height: 32),

          // 签到按钮和会议过程管理按钮
          Center(
            child: Column(
              children: [
                // 会议过程管理按钮 - 仅对进行中或已结束的会议显示
                if (meeting.status == MeetingStatus.ongoing ||
                    meeting.status == MeetingStatus.completed)
                  ElevatedButton.icon(
                    onPressed:
                        () => _navigateToMeetingProcess(context, meeting),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 45),
                      backgroundColor:
                          meeting.status == MeetingStatus.ongoing
                              ? Colors.blue
                              : Colors.grey,
                    ),
                    icon: const Icon(Icons.meeting_room),
                    label: Text(
                      meeting.status == MeetingStatus.ongoing
                          ? '进入会议'
                          : '查看会议记录',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label：',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // 导航到会议过程管理页面
  void _navigateToMeetingProcess(BuildContext context, Meeting meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MeetingProcessPage(meetingId: meetingId, meeting: meeting),
      ),
    );
  }
}
