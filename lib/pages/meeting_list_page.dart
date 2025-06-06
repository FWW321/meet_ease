import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/meeting_providers.dart';
import '../widgets/meeting_list_item.dart';
import '../constants/app_constants.dart';

class MeetingListPage extends HookConsumerWidget {
  const MeetingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有会议列表
    final meetingsAsync = ref.watch(meetingListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('会议列表')),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '获取会议列表失败\n',
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
        data: (meetings) {
          if (meetings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无会议', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return MeetingListItem(
                meeting: meeting,
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      AppConstants.meetingDetailRoute,
                      arguments: meeting.id,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 导航到创建会议页面
          final result = await Navigator.pushNamed(
            context,
            AppConstants.createMeetingRoute,
          );

          // 如果创建成功，刷新会议列表
          if (result == true) {
            ref.invalidate(meetingListProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
