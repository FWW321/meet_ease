import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';
import '../widgets/agenda_list_widget.dart';
import '../widgets/materials_list_widget.dart';
import '../widgets/notes_list_widget.dart';
import '../widgets/votes_list_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/voice_meeting_widget.dart';

/// 会议过程管理页面 - 以实时语音为主要内容的界面
class MeetingProcessPage extends HookConsumerWidget {
  final String meetingId;
  final Meeting meeting;

  const MeetingProcessPage({
    required this.meetingId,
    required this.meeting,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 屏幕尺寸
    final screenSize = MediaQuery.of(context).size;

    // 是否为大屏设备
    final isLargeScreen = screenSize.width > 1000;

    // 是否为已结束的会议
    final isCompletedMeeting = meeting.status == MeetingStatus.completed;

    // 签到状态
    final signInStatusAsync = ref.watch(meetingSignInProvider(meetingId));

    // 是否显示签到对话框
    final isShowingSignInDialog = useState(false);

    // 当前选中的功能选项
    final selectedFeatureIndex = useState(-1);

    // 功能选项列表
    final features = [
      _MeetingFeature(icon: Icons.chat, label: '消息', color: Colors.teal),
      _MeetingFeature(icon: Icons.list_alt, label: '议程', color: Colors.blue),
      _MeetingFeature(icon: Icons.folder, label: '资料', color: Colors.orange),
      _MeetingFeature(icon: Icons.note, label: '笔记', color: Colors.green),
      _MeetingFeature(
        icon: Icons.how_to_vote,
        label: '投票',
        color: Colors.purple,
      ),
    ];

    // 构建底部导航栏
    Widget buildBottomNavBar() {
      return BottomNavigationBar(
        currentIndex:
            selectedFeatureIndex.value < 0 ||
                    selectedFeatureIndex.value >= features.length
                ? 0 // 默认选中第一项
                : selectedFeatureIndex.value,
        onTap:
            (index) =>
                selectedFeatureIndex.value =
                    selectedFeatureIndex.value == index ? -1 : index, // 切换选中状态
        type: BottomNavigationBarType.fixed,
        items:
            features.map((feature) {
              return BottomNavigationBarItem(
                icon: Icon(feature.icon),
                label: feature.label,
              );
            }).toList(),
      );
    }

    // 构建顶部操作按钮
    List<Widget> buildActions() {
      return [
        // 签到按钮 - 仅在进行中且未签到的会议显示
        if (meeting.status == MeetingStatus.ongoing)
          signInStatusAsync.when(
            data:
                (isSignedIn) =>
                    !isSignedIn
                        ? IconButton(
                          icon: const Icon(Icons.how_to_reg),
                          tooltip: '签到',
                          onPressed: () => isShowingSignInDialog.value = true,
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Chip(
                            label: const Text('已签到'),
                            backgroundColor: Colors.green.shade100,
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
            loading:
                () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            error:
                (_, __) => IconButton(
                  icon: const Icon(Icons.error_outline),
                  color: Colors.red,
                  tooltip: '签到状态获取失败',
                  onPressed:
                      () => ref.invalidate(meetingSignInProvider(meetingId)),
                ),
          ),

        // 会议状态指示器
        if (isCompletedMeeting)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: const Text('已结束'),
              backgroundColor: Colors.grey.shade200,
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

        // 会议信息按钮
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: '会议信息',
          onPressed: () => _showMeetingInfo(context),
        ),

        // 更多选项按钮
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) {
            final menuItems = <PopupMenuItem<String>>[];

            // 进行中的会议才显示会议设置和邀请参会者
            if (!isCompletedMeeting) {
              menuItems.add(
                const PopupMenuItem(value: 'settings', child: Text('会议设置')),
              );
              menuItems.add(
                const PopupMenuItem(value: 'invite', child: Text('邀请参会者')),
              );
            }

            // 添加退出会议选项
            menuItems.add(
              const PopupMenuItem(value: 'exit', child: Text('退出会议')),
            );

            return menuItems;
          },
          onSelected: (value) {
            // 处理菜单项选择
            switch (value) {
              case 'settings':
                // 实现会议设置功能
                break;
              case 'invite':
                // 实现邀请参会者功能
                break;
              case 'exit':
                Navigator.of(context).pop();
                break;
            }
          },
        ),
      ];
    }

    // 显示签到对话框
    if (isShowingSignInDialog.value) {
      // 使用Future.microtask确保在构建完成后显示对话框
      Future.microtask(
        () => _showSignInDialog(context, ref, () {
          isShowingSignInDialog.value = false;
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(meeting.title), actions: buildActions()),
      body: Stack(
        children: [
          // 主体内容 - 实时语音通话或历史记录
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                isCompletedMeeting
                    ? _buildCompletedMeetingView(ref)
                    : VoiceMeetingWidget(
                      meetingId: meetingId,
                      userId: 'currentUserId', // 替换为实际用户ID
                      userName: '当前用户', // 替换为实际用户名
                    ),
          ),

          // 底部功能抽屉
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // 功能内容面板 - 可收起
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height:
                      selectedFeatureIndex.value >= 0
                          ? MediaQuery.of(context).size.height * 0.5
                          : 0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child:
                      selectedFeatureIndex.value >= 0
                          ? Column(
                            children: [
                              // 功能标题栏
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: features[selectedFeatureIndex.value]
                                      .color
                                      .withOpacity(0.1),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: features[selectedFeatureIndex
                                              .value]
                                          .color
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      features[selectedFeatureIndex.value].icon,
                                      color:
                                          features[selectedFeatureIndex.value]
                                              .color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      features[selectedFeatureIndex.value]
                                          .label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            features[selectedFeatureIndex.value]
                                                .color,
                                      ),
                                    ),
                                    if (isCompletedMeeting) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        '(只读)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed:
                                          () => selectedFeatureIndex.value = -1,
                                      tooltip: '关闭',
                                    ),
                                  ],
                                ),
                              ),

                              // 功能内容
                              Expanded(
                                child: _buildFeaturePanel(
                                  selectedFeatureIndex.value,
                                  isReadOnly: isCompletedMeeting,
                                ),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                ),

                // 底部导航栏
                buildBottomNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建已结束会议的主视图
  Widget _buildCompletedMeetingView(WidgetRef ref) {
    // 获取签到状态
    final signInStatusAsync = ref.watch(meetingSignInProvider(meetingId));

    return Column(
      children: [
        // 会议状态和签到信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    '会议已结束',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '会议结束时间：${meeting.endTime.toString().substring(0, 16)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // 签到状态
              Row(
                children: [
                  const Text('签到状态：', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                  signInStatusAsync.when(
                    data:
                        (isSignedIn) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSignedIn
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSignedIn
                                      ? Colors.green
                                      : Colors.red.shade300,
                            ),
                          ),
                          child: Text(
                            isSignedIn ? '已签到' : '未签到',
                            style: TextStyle(
                              color:
                                  isSignedIn
                                      ? Colors.green
                                      : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    loading:
                        () => const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    error:
                        (_, __) => const Text(
                          '未知',
                          style: TextStyle(color: Colors.grey),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 使用VoiceMeetingWidget的只读模式，但不显示实时通话相关UI
        Expanded(
          child: VoiceMeetingWidget(
            meetingId: meetingId,
            userId: 'currentUserId',
            userName: '当前用户',
            isReadOnly: true,
          ),
        ),
      ],
    );
  }

  // 根据选择的索引构建相应的功能面板
  Widget _buildFeaturePanel(int index, {bool isReadOnly = false}) {
    switch (index) {
      case 0:
        return ChatWidget(
          meetingId: meetingId,
          userId: 'currentUserId', // 替换为实际用户ID
          userName: '当前用户', // 替换为实际用户名
          isReadOnly: isReadOnly, // 已结束会议聊天只读
        );
      case 1:
        return AgendaListWidget(meetingId: meetingId, isReadOnly: isReadOnly);
      case 2:
        return MaterialsListWidget(
          meetingId: meetingId,
          isReadOnly: isReadOnly,
        );
      case 3:
        return NotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly);
      case 4:
        return VotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly);
      default:
        return const Center(child: Text('请选择功能'));
    }
  }

  // 显示会议信息对话框
  void _showMeetingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('会议信息'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('标题: ${meeting.title}'),
                const SizedBox(height: 8),
                Text('开始时间: ${meeting.startTime}'),
                const SizedBox(height: 8),
                Text('结束时间: ${meeting.endTime}'),
                const SizedBox(height: 8),
                Text('组织者: ${meeting.organizerName}'),
                const SizedBox(height: 8),
                Text('参会人数: ${meeting.participantCount}人'),
                if (meeting.description != null &&
                    meeting.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('会议描述: ${meeting.description}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  // 显示签到对话框
  void _showSignInDialog(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onClose,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('会议签到'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('确认签到参加本次会议吗？'),
                const SizedBox(height: 12),
                const Text(
                  '签到后将被记录为已参加本次会议',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClose();
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  _signIn(context, ref);
                  Navigator.pop(context);
                  onClose();
                },
                child: const Text('确认签到'),
              ),
            ],
          ),
    );
  }

  // 签到方法
  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(meetingSignInProvider(meetingId).notifier).signIn();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('签到成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('签到失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// 会议功能项数据类
class _MeetingFeature {
  final IconData icon;
  final String label;
  final Color color;

  const _MeetingFeature({
    required this.icon,
    required this.label,
    required this.color,
  });
}
