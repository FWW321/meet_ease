import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../providers/webrtc_providers.dart';
import '../widgets/agenda_list_widget.dart';
import '../widgets/materials_list_widget.dart';
import '../widgets/notes_list_widget.dart';
import '../widgets/votes_list_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/voice_meeting_widget.dart';
import '../services/webrtc_service.dart';
import '../pages/meeting_settings_page.dart';

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

    // 检查会议是否已取消
    final isCancelledMeeting = meeting.status == MeetingStatus.cancelled;

    // 如果会议已取消，显示无法进入提示并返回
    if (isCancelledMeeting) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('无法进入会议'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_outlined, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '会议已被取消',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '此会议已被取消，无法进入',
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
        ),
      );
    }

    // 获取当前用户ID
    final currentUserId = ref.watch(currentUserIdProvider);

    // 检查当前用户是否在黑名单中
    final isBlocked = meeting.blacklist.contains(currentUserId);

    // 如果用户在黑名单中，显示拒绝访问提示
    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('无法加入会议'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                '您无法加入此会议',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('您没有权限访问此会议内容', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // 签到状态
    final signInStatusAsync = ref.watch(meetingSignInProvider(meetingId));

    // 是否显示签到对话框
    final isShowingSignInDialog = useState(false);

    // 当前选中的功能选项
    final selectedFeatureIndex = useState(-1);

    // 获取参会人员列表
    final participantsAsync = ref.watch(meetingParticipantsProvider(meetingId));

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

        // 显示用户权限徽章
        if (!isCompletedMeeting)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(
                getMeetingPermissionText(
                  meeting.getUserPermission(currentUserId),
                ),
              ),
              backgroundColor: Colors.blue.shade100,
              labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
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

            // 进行中的会议才显示邀请参会者
            if (!isCompletedMeeting) {
              menuItems.add(
                const PopupMenuItem(value: 'invite', child: Text('邀请参会者')),
              );

              // 创建者可以结束进行中的会议
              if (meeting.isCreatorOnly(currentUserId) &&
                  meeting.status == MeetingStatus.ongoing) {
                menuItems.add(
                  const PopupMenuItem(
                    value: 'end_meeting',
                    child: Text('结束会议', style: TextStyle(color: Colors.red)),
                  ),
                );
              }
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
              case 'invite':
                // 实现邀请参会者功能
                break;
              case 'end_meeting':
                _showEndMeetingConfirmDialog(context, ref, currentUserId);
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
                      userId: currentUserId,
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
                                  currentUserId: currentUserId,
                                  participants: participantsAsync,
                                  ref: ref,
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
                        (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Text(
                            '加载失败',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 会议历史记录入口提示
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_toggle_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '此会议已结束',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您可以通过底部功能栏查看会议记录',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('发送会议纪要至邮箱'),
                  onPressed: () {
                    // 实现发送会议纪要功能
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建功能面板内容
  Widget _buildFeaturePanel(
    int index, {
    bool isReadOnly = false,
    required String currentUserId,
    required AsyncValue<List<User>> participants,
    required WidgetRef ref,
  }) {
    // 功能列表
    final functionWidgets = [
      ChatWidget(
        meetingId: meetingId,
        isReadOnly: isReadOnly,
        userId: currentUserId,
        userName: '当前用户', // 替换为实际用户名
      ),
      AgendaListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
      MaterialsListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
      NotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
      VotesListWidget(meetingId: meetingId, isReadOnly: isReadOnly),
    ];

    if (index >= 0 && index < functionWidgets.length) {
      return functionWidgets[index];
    }

    return const Center(child: Text('未知功能'));
  }

  // 构建参会人员面板
  Widget _buildParticipantsPanel(
    AsyncValue<List<User>> participantsAsync,
    String currentUserId,
    WidgetRef ref,
  ) {
    // 获取WebRTC参会人员列表，保持与主页面显示的参会人员一致
    final rtcParticipantsAsync = ref.watch(webRTCParticipantsProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 会议参与者列表（User类型）
          Expanded(
            child: participantsAsync.when(
              data:
                  (participants) => ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final user = participants[index];
                      // 确定用户角色
                      String? roleLabel;
                      Color? roleColor;

                      if (user.id == meeting.organizerId) {
                        roleLabel = '创建者';
                        roleColor = Colors.orange;
                      } else if (meeting.admins.contains(user.id)) {
                        roleLabel = '管理员';
                        roleColor = Colors.blue;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing:
                            roleLabel != null
                                ? _buildRoleChip(roleLabel, roleColor!)
                                : null,
                      );
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(child: Text('无法加载参会者: $error')),
            ),
          ),

          const Divider(),

          // 实时连接状态的参会人员列表（MeetingParticipant类型）
          const Text(
            '实时连接状态',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: rtcParticipantsAsync.when(
              data: (participants) {
                if (participants.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无实时连接的参会人员',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final participant = participants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            participant.isMe
                                ? Colors.blue
                                : Colors.grey.shade300,
                        child: Text(
                          participant.name.isNotEmpty
                              ? participant.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color:
                                participant.isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            participant.name,
                            style: TextStyle(
                              fontWeight:
                                  participant.isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          if (participant.isMe)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                '(我)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 麦克风状态
                          Icon(
                            participant.isMuted ? Icons.mic_off : Icons.mic,
                            color:
                                participant.isMuted ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),

                          // 发言指示器
                          if (participant.isSpeaking)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.record_voice_over,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '发言中',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('无法加载实时参会者: $error')),
            ),
          ),

          // 仅会议管理员显示的权限管理按钮
          if (meeting.canUserManage(currentUserId) &&
              meeting.status != MeetingStatus.completed)
            Builder(
              builder:
                  (context) => Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('权限管理'),
                      onPressed:
                          () => _navigateToSettings(context, currentUserId),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }

  // 导航到权限管理页面
  void _navigateToSettings(BuildContext context, String currentUserId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MeetingSettingsPage(
              meetingId: meetingId,
              currentUserId: currentUserId,
            ),
      ),
    );
  }

  // 构建角色标签
  Widget _buildRoleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
                _buildInfoRow('标题', meeting.title),
                _buildInfoRow(
                  '开始时间',
                  meeting.startTime.toString().substring(0, 16),
                ),
                _buildInfoRow(
                  '结束时间',
                  meeting.endTime.toString().substring(0, 16),
                ),
                _buildInfoRow('地点', meeting.location),
                _buildInfoRow('状态', getMeetingStatusText(meeting.status)),
                _buildInfoRow('类型', getMeetingTypeText(meeting.type)),
                _buildInfoRow('组织者', meeting.organizerName),
                if (meeting.description != null)
                  _buildInfoRow('描述', meeting.description!),
                _buildInfoRow('参与人数', meeting.participantCount.toString()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
    VoidCallback onComplete,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('会议签到'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('确认签到本次会议吗？'),
                const SizedBox(height: 16),
                Text(
                  meeting.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '开始时间：${meeting.startTime.toString().substring(0, 16)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onComplete();
                },
                child: const Text('取消'),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final signInAsyncValue = ref.watch(
                    meetingSignInProvider(meetingId),
                  );
                  final isLoading = signInAsyncValue.isLoading;

                  return TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              await ref
                                  .read(
                                    meetingSignInProvider(meetingId).notifier,
                                  )
                                  .signIn();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                onComplete();
                              }
                            },
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('确认签到'),
                  );
                },
              ),
            ],
          ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // 显示结束会议确认对话框
  void _showEndMeetingConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('结束会议'),
            content: const Text('确认要结束此会议吗？此操作不可撤销，所有参会者将收到会议已结束的通知。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // 显示加载指示器
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // 调用结束会议服务
                    final meetingService = ref.read(meetingServiceProvider);
                    await meetingService.endMeeting(meetingId, currentUserId);

                    // 刷新会议详情
                    ref.invalidate(meetingDetailProvider(meetingId));

                    if (context.mounted) {
                      // 关闭加载指示器
                      Navigator.of(context).pop();

                      // 显示成功提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('会议已成功结束'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // 返回会议列表
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // 关闭加载指示器
                      Navigator.of(context).pop();

                      // 显示错误提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('结束会议失败: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('确定结束'),
              ),
            ],
          ),
    );
  }
}

/// 会议功能选项模型
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
