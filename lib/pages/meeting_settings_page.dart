import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';
import 'meeting_settings/meeting_info_tab.dart';
import 'meeting_settings/admins_tab.dart';
import 'meeting_settings/blacklist_tab.dart';
import 'meeting_settings/leaves_tab.dart';

/// 会议设置页面 - 仅会议创建者和管理员可访问
class MeetingSettingsPage extends HookConsumerWidget {
  final String meetingId;
  final String currentUserId;

  const MeetingSettingsPage({
    required this.meetingId,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取会议详情
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));

    // 当前选中的标签索引
    final selectedTabIndex = useState(0);

    // 标签列表 - 动态构建
    List<String> getTabs(Meeting meeting) {
      final baseTabs = ['会议信息', '管理员', '黑名单'];

      // 只有私有会议才添加请假标签页
      if (meeting.visibility == MeetingVisibility.private) {
        return [...baseTabs, '请假申请'];
      }

      return baseTabs;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('会议设置'), centerTitle: true),
      body: meetingAsync.when(
        data: (meeting) {
          // 检查权限
          if (!meeting.canUserManage(currentUserId)) {
            return const Center(child: Text('您没有权限访问此页面'));
          }

          // 检查会议状态 - 只允许在即将开始或进行中的会议中修改设置
          if (meeting.status == MeetingStatus.completed) {
            return Center(
              child: Text('无法修改${getMeetingStatusText(meeting.status)}的会议设置'),
            );
          }

          // 对已取消的会议显示特别的提示
          if (meeting.status == MeetingStatus.cancelled) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '会议已被取消',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '无法修改已取消的会议设置',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('返回'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }

          // 获取会议类型对应的标签
          final tabs = getTabs(meeting);

          // 确保选中的标签索引不超出范围
          if (selectedTabIndex.value >= tabs.length) {
            selectedTabIndex.value = 0;
          }

          return Column(
            children: [
              // 标签选择器
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (index) => Expanded(
                      child: GestureDetector(
                        onTap: () => selectedTabIndex.value = index,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    selectedTabIndex.value == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                          ),
                          child: Text(
                            tabs[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  selectedTabIndex.value == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                              fontWeight:
                                  selectedTabIndex.value == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 内容区域
              Expanded(
                child: IndexedStack(
                  index: selectedTabIndex.value,
                  children: [
                    MeetingInfoTab(
                      meeting: meeting,
                      currentUserId: currentUserId,
                    ),
                    AdminsTab(meeting: meeting, currentUserId: currentUserId),
                    BlacklistTab(
                      meeting: meeting,
                      currentUserId: currentUserId,
                    ),
                    // 只在私有会议中显示请假标签页
                    if (meeting.visibility == MeetingVisibility.private)
                      LeavesTab(meeting: meeting, currentUserId: currentUserId),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}
