import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/meeting.dart';
import '../../models/chat_message.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/chat_providers.dart';
import '../../services/service_providers.dart';
import '../../widgets/chat/chat_widget.dart';
import '../../widgets/voice_meeting_widget.dart';
import 'models/meeting_feature.dart';
import 'utils/meeting_dialogs.dart';
import 'widgets/completed_meeting_view.dart';
import 'utils/feature_panel_builder.dart';
import 'widgets/signin_list_view.dart';

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

    // 消息流订阅
    final messageSubscription = useState<dynamic>(null);

    // 处理系统消息
    void handleSystemMessage(ChatMessage message) {
      // 检查是否是系统消息
      if (message.isSystemMessage) {
        // 使用消息类型判断，而不是通过senderId和senderName
        print('收到系统消息: ${message.content}');

        // 检查是否是黑名单消息
        if (message.content.contains("action:禁止加入")) {
          // 解析消息内容
          final msgContent = message.content;
          String? msgUserId;

          // 从消息中提取用户ID - 更新正则表达式，匹配任何字符而不仅是数字
          final userIdMatch = RegExp(r'userId:([^,]+)').firstMatch(msgContent);
          if (userIdMatch != null && userIdMatch.groupCount >= 1) {
            msgUserId = userIdMatch.group(1);
          }

          print(
            '收到黑名单系统消息，被禁止加入的用户ID：$msgUserId，当前用户ID：${currentUserId.value}',
          );

          // 如果当前用户是被拉黑的用户，强制退出
          if (msgUserId != null &&
              msgUserId == currentUserId.value &&
              context.mounted) {
            print('当前用户被加入黑名单，强制退出会议');
            // 显示提示并退出
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('您已被管理员移出会议'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );

            // 延迟一点时间后退出，以便用户能看到提示
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        }
      }
    }

    // 使用useEffect建立消息流监听
    useEffect(() {
      // 当用户ID可用时建立监听
      currentUserIdAsync.whenData((userId) {
        currentUserId.value = userId;

        if (userId.isNotEmpty) {
          // 获取聊天服务
          final chatService = ref.read(chatServiceProvider);

          // 订阅消息流
          final subscription = chatService.getMessageStream(meetingId).listen((
            message,
          ) {
            // 处理接收到的消息
            handleSystemMessage(message);
          });

          // 保存订阅以便在组件卸载时取消
          messageSubscription.value = subscription;
        }
      });

      // 清理函数
      return () {
        // 取消消息流订阅
        if (messageSubscription.value != null) {
          messageSubscription.value.cancel();
          messageSubscription.value = null;

          // 关闭消息流
          try {
            final chatService = ref.read(chatServiceProvider);
            chatService.closeMessageStream();
          } catch (e) {
            print('关闭消息流时出错: $e');
          }
        }
      };
    }, [currentUserIdAsync]);

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

    // 签到状态 - 使用新的签到状态提供者
    final signInStatusAsync = ref.watch(meetingSignInStatusProvider(meetingId));

    // 功能选项列表
    final features = [
      MeetingFeature(icon: Icons.chat, label: '消息', color: Colors.teal),
      MeetingFeature(icon: Icons.folder, label: '资料', color: Colors.orange),
      MeetingFeature(icon: Icons.note, label: '笔记', color: Colors.green),
      MeetingFeature(
        icon: Icons.how_to_vote,
        label: '投票',
        color: Colors.purple,
      ),
    ];

    // 检查用户是否是创建者或管理员
    final isCreatorOrAdmin =
        currentUserId.value.isNotEmpty &&
        (meeting.isCreatorOnly(currentUserId.value) ||
            meeting.admins.contains(currentUserId.value));

    // 检查是否为私有会议
    final isPrivateMeeting = meeting.visibility == MeetingVisibility.private;

    // 是否显示签到列表按钮（只有创建者和管理员且私有会议可以查看）
    final canViewSignInList = isCreatorOrAdmin && isPrivateMeeting;

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
        // 签到列表按钮 - 只在私有会议且用户为创建者或管理员时显示
        if (canViewSignInList)
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '签到列表',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SignInListView(meetingId: meetingId),
                ),
              );
            },
          ),

        // 签到按钮 - 仅在进行中且未签到的私有会议显示
        if (meeting.status == MeetingStatus.ongoing &&
            meeting.visibility == MeetingVisibility.private)
          signInStatusAsync.when(
            data: (signInStatus) {
              // 处理不同签到状态
              if (signInStatus == '未签到') {
                return IconButton(
                  icon: const Icon(Icons.how_to_reg),
                  tooltip: '签到',
                  onPressed: () => isShowingSignInDialog.value = true,
                );
              } else if (signInStatus == '已签到') {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Chip(
                    label: const Text('已签到'),
                    backgroundColor: Colors.green.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                );
              } else {
                // 不支持签到或其他状态
                return const SizedBox.shrink();
              }
            },
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
                      () => ref.invalidate(
                        meetingSignInStatusProvider(meetingId),
                      ),
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
          onPressed: () => showMeetingInfo(context, meeting),
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
                  showEndMeetingConfirmDialog(
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
          showSignInDialog(context, ref, meetingId, () {
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
                    ? CompletedMeetingView(
                      ref: ref,
                      meeting: meeting,
                      meetingId: meetingId,
                    )
                    : VoiceMeetingWidget(
                      meetingId: meetingId,
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
                                child: buildFeaturePanel(
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
