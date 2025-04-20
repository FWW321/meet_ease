import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../providers/chat_providers.dart';
import '../services/service_providers.dart';
import '../widgets/agenda_list_widget.dart';
import '../widgets/materials_list_widget.dart';
import '../widgets/notes_list_widget.dart';
import '../widgets/votes_list_widget.dart';
import '../widgets/chat/chat_widget.dart';
import '../widgets/voice_meeting_widget.dart';

// 全局聊天组件缓存提供者
final chatWidgetCacheProvider = StateProvider<ChatWidget?>((ref) => null);

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
    // 获取当前用户ID
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    // 使用useState保存当前用户ID，避免重复请求
    final currentUserId = useState<String>('');

    // 提前预加载聊天消息，避免点击聊天标签时出现加载延迟
    useEffect(() {
      // 使用微任务确保不阻塞UI
      Future.microtask(() async {
        // 预加载聊天消息数据
        await ref.read(meetingMessagesProvider(meetingId).future);
        // 预加载表情数据
        await ref.read(emojisProvider.future);
        // 初始化其他可能需要预加载的数据
      });
      return null;
    }, const []); // 空依赖数组确保只执行一次

    // 是否为已结束的会议
    final isCompletedMeeting = meeting.status == MeetingStatus.completed;

    // 是否显示签到对话框
    final isShowingSignInDialog = useState(false);

    // 当前选中的功能选项
    final selectedFeatureIndex = useState(-1);

    // 缓存预创建的聊天组件实例
    final chatWidgetCache = useState<ChatWidget?>(null);

    // 获取参会人员列表
    final participantsAsync = ref.watch(meetingParticipantsProvider(meetingId));

    // 使用useEffect获取当前用户ID
    useEffect(() {
      currentUserIdAsync.whenData((userId) {
        currentUserId.value = userId;
        // 用户ID获取后，预创建聊天组件
        if (userId.isNotEmpty && chatWidgetCache.value == null) {
          final widget = ChatWidget(
            meetingId: meetingId,
            userId: userId,
            userName: ref.read(currentUserProvider).value?.name ?? '当前用户',
            isReadOnly: isCompletedMeeting,
          );
          chatWidgetCache.value = widget;
          // 更新全局缓存
          ref.read(chatWidgetCacheProvider.notifier).state = widget;
        }
      });
      return null;
    }, [currentUserIdAsync]);

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

    // 检查当前用户是否在黑名单中
    final isBlocked =
        currentUserId.value.isNotEmpty &&
        meeting.blacklist.contains(currentUserId.value);

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
        if (!isCompletedMeeting && currentUserId.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(
                getMeetingPermissionText(
                  meeting.getUserPermission(currentUserId.value),
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
          onPressed: () => _showMeetingInfo(context, meeting),
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
              if (currentUserId.value.isNotEmpty &&
                  meeting.isCreatorOnly(currentUserId.value) &&
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
          onSelected: (value) async {
            // 处理菜单项选择
            switch (value) {
              case 'invite':
                // 实现邀请参会者功能
                break;
              case 'end_meeting':
                if (currentUserId.value.isNotEmpty) {
                  _showEndMeetingConfirmDialog(
                    context,
                    ref,
                    currentUserId.value,
                    meetingId,
                  );
                }
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
      Future.microtask(() {
        if (context.mounted) {
          _showSignInDialog(context, ref, meetingId, () {
            isShowingSignInDialog.value = false;
          });
        }
      });
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
                    ? _buildCompletedMeetingView(ref, meeting, meetingId)
                    : VoiceMeetingWidget(
                      meetingId: meetingId,
                      userId: currentUserId.value,
                      userName:
                          ref.watch(currentUserProvider).value?.name ?? '当前用户',
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
                        color: Colors.black.withAlpha(25),
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
                                      .withAlpha(25),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: features[selectedFeatureIndex
                                              .value]
                                          .color
                                          .withAlpha(76),
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
                                  meetingId: meetingId,
                                  isReadOnly: isCompletedMeeting,
                                  currentUserId: currentUserId.value,
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
}

// 构建已结束会议的主视图
Widget _buildCompletedMeetingView(
  WidgetRef ref,
  Meeting meeting,
  String meetingId,
) {
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
                                isSignedIn ? Colors.green : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          isSignedIn ? '已签到' : '未签到',
                          style: TextStyle(
                            color:
                                isSignedIn ? Colors.green : Colors.red.shade700,
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
  required String meetingId,
  bool isReadOnly = false,
  required String currentUserId,
  required AsyncValue<List<User>> participants,
  required WidgetRef ref,
}) {
  // 获取缓存的聊天组件（如果有）或创建新的
  final ChatWidget chatWidget = ref.read(
    Provider((ref) {
      final cache = ref.read(chatWidgetCacheProvider);
      if (cache != null) {
        return cache;
      }
      // 如果没有缓存，创建新的
      return ChatWidget(
        meetingId: meetingId,
        userId: currentUserId,
        userName: ref.watch(currentUserProvider).value?.name ?? '当前用户',
        isReadOnly: isReadOnly,
      );
    }),
  );

  // 功能组件列表
  final functionWidgets = [
    // 使用缓存的聊天组件
    chatWidget,
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

// 显示会议信息对话框
void _showMeetingInfo(BuildContext context, Meeting meeting) {
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
  String meetingId,
  VoidCallback onComplete,
) {
  final meeting = ref.read(meetingDetailProvider(meetingId)).value;

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
                meeting?.title ?? '当前会议',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (meeting != null)
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
                                .read(meetingSignInProvider(meetingId).notifier)
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
  String meetingId,
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
