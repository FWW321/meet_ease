import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:async';
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
import 'package:http/http.dart' as http;
import '../../utils/http_utils.dart';
import '../../constants/app_constants.dart';

// 全局聊天组件缓存提供者
final chatWidgetCacheProvider = StateProvider<ChatWidget?>((ref) => null);

/// 会议过程管理页面 - 以实时语音为主要内容的界面
class MeetingProcessPage extends HookConsumerWidget {
  final String meetingId;

  const MeetingProcessPage({required this.meetingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 移除在build中直接调用invalidate
    // ref.invalidate(meetingDetailProvider(meetingId));
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));

    // 获取当前用户ID
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    // 使用useState保存当前用户ID，避免重复请求
    final currentUserId = useState<String>('');

    // 添加用户角色状态变量
    final userRoleState = useState<MeetingPermission>(
      MeetingPermission.participant,
    );
    final hasLoadedRole = useState(false);

    // 保存当前用户名
    final currentUserName = useState<String>('');

    // 消息流订阅
    final messageSubscription = useState<dynamic>(null);

    // 获取聊天服务
    final chatService = ref.read(chatServiceProvider);

    // 添加一个useEffect来处理会议数据刷新
    useEffect(() {
      // 使用微任务确保不在构建过程中刷新数据
      Future.microtask(() {
        // 强制刷新会议详情
        ref.invalidate(meetingDetailProvider(meetingId));
      });
      return null;
    }, const []); // 空依赖数组确保只执行一次

    // 处理断开连接的函数
    Future<void> handleDisconnect() async {
      try {
        // 取消消息流订阅
        if (messageSubscription.value != null) {
          await messageSubscription.value.cancel();
          messageSubscription.value = null;
        }

        // 断开WebSocket连接
        await chatService.disconnect();
        debugPrint('WebSocket连接已断开');
      } catch (e) {
        debugPrint('断开WebSocket连接失败: $e');
      }
    }

    // 处理退出页面的函数
    Future<void> handleExit() async {
      await handleDisconnect();
      if (context.mounted) {
        // 退出时强制刷新会议详情
        ref.invalidate(meetingDetailProvider(meetingId));
        Navigator.of(context).pop(true); // 传递true表示需要刷新
      }
    }

    // 根据异步数据构建UI
    return meetingAsync.when(
      loading:
          () => Scaffold(
            appBar: AppBar(
              title: const Text('会议加载中'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(
              title: const Text('加载失败'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      data: (meeting) {
        // 强制添加调试信息，查看会议数据
        debugPrint('======会议数据调试信息======');
        debugPrint('会议ID: ${meeting.id}');
        debugPrint('会议状态: ${meeting.status}');
        debugPrint('会议创建者ID: ${meeting.organizerId}');
        debugPrint('管理员列表类型: ${meeting.admins.runtimeType}');
        debugPrint('管理员列表内容: ${meeting.admins}');
        debugPrint('管理员列表长度: ${meeting.admins.length}');
        if (meeting.admins.isNotEmpty) {
          debugPrint('第一个管理员: ${meeting.admins.first}');
        }
        debugPrint('========================');

        // 以下是原有的逻辑，使用获取到的 meeting 数据
        // 是否为已结束的会议
        final isCompletedMeeting = meeting.status == MeetingStatus.completed;

        // 是否显示签到对话框
        final isShowingSignInDialog = useState(false);

        // 当前选中的功能选项
        final selectedFeatureIndex = useState(-1);

        // 缓存预创建的聊天组件实例
        final chatWidgetCache = useState<ChatWidget?>(null);

        // 获取参会人员列表
        final participantsAsync = ref.watch(
          meetingParticipantsProvider(meetingId),
        );

        // 处理系统消息
        void handleSystemMessage(ChatMessage message) {
          if (!message.isSystemMessage) return;

          final parts = message.content.split(', ');
          String? userId;
          String? username;
          String? action;

          for (final part in parts) {
            if (part.startsWith('userId:')) {
              userId = part.substring('userId:'.length).trim();
            } else if (part.startsWith('username:')) {
              username = part.substring('username:'.length).trim();
            } else if (part.startsWith('action:')) {
              action = part.substring('action:'.length).trim();
            }
          }

          if (userId == null || username == null || action == null) return;

          // 处理会议结束消息
          if (action == '结束会议') {
            // 显示会议已结束的提示
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('会议已结束'),
                  backgroundColor: Colors.orange,
                ),
              );
            }

            // 强制退出会议
            handleExit();
            return;
          }

          // 处理其他系统消息
          switch (action) {
            case '加入会议':
              // 更新参会者列表
              break;
            case '离开会议':
              // 更新参会者列表
              break;
            case '开启麦克风':
            case '关闭麦克风':
              // 更新参会者麦克风状态
              break;
          }
        }

        // 修改useEffect的清理函数
        useEffect(() {
          // 当用户ID可用时建立监听
          currentUserIdAsync.whenData((userId) async {
            currentUserId.value = userId;

            if (userId.isNotEmpty) {
              try {
                // 获取用户名
                final userName = await ref.read(
                  userNameProvider(userId).future,
                );
                currentUserName.value = userName;

                // 获取聊天服务
                await chatService.connectToChat(meetingId, userId);
                debugPrint('$meetingId, $userId, websocket连接已建立');

                // 订阅消息流
                final subscription = chatService
                    .getMessageStream(meetingId)
                    .listen((message) {
                      // 处理接收到的消息
                      handleSystemMessage(message);
                    });

                // 保存订阅以便在组件卸载时取消
                messageSubscription.value = subscription;
              } catch (e) {
                debugPrint('WebSocket连接或消息发送失败: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('连接失败: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          });

          // 清理函数
          return () {
            handleDisconnect();
          };
        }, [currentUserIdAsync]);

        // 修改预加载聊天消息的 useEffect
        useEffect(() {
          // 使用微任务确保不阻塞UI
          Future.microtask(() async {
            try {
              // 预加载聊天消息数据
              await ref.read(meetingMessagesProvider(meetingId).future);
              // 预加载表情数据
              await ref.read(emojisProvider.future);
              // 初始化其他可能需要预加载的数据
            } catch (e) {
              debugPrint('预加载数据失败: $e');
            }
          });
          return null;
        }, const []); // 空依赖数组确保只执行一次

        // 确保用户ID在页面加载时立即获取
        useEffect(() {
          if (currentUserIdAsync.hasValue && currentUserIdAsync.value != null) {
            currentUserId.value = currentUserIdAsync.value!;
            debugPrint('用户ID已设置: ${currentUserId.value}');
          }
          return null;
        }, [currentUserIdAsync]);

        // 添加获取用户角色的useEffect
        useEffect(() {
          if (currentUserId.value.isNotEmpty && !hasLoadedRole.value) {
            // 只获取一次角色信息
            debugPrint('开始获取用户角色信息...');

            // 创建一个函数来获取角色
            Future<void> loadUserRole() async {
              try {
                // 直接调用API获取最新会议参与者数据
                final response = await http.get(
                  Uri.parse(
                    '${AppConstants.apiBaseUrl}/meeting/$meetingId/participants',
                  ),
                  headers: HttpUtils.createHeaders(),
                );

                if (response.statusCode == 200) {
                  final responseData = HttpUtils.decodeResponse(response);

                  if (responseData['code'] == 200 &&
                      responseData['data'] != null) {
                    final participants = responseData['data'] as List<dynamic>;

                    // 查找当前用户的角色
                    for (final participant in participants) {
                      // 将API返回的用户ID转换为字符串进行比较
                      final participantId = participant['user_id'].toString();
                      final role =
                          participant['role'] as String? ?? 'PARTICIPANT';

                      if (participantId == currentUserId.value) {
                        debugPrint('找到当前用户，角色: $role');

                        // 根据API返回的角色映射到枚举
                        MeetingPermission permission;
                        switch (role) {
                          case 'HOST':
                            permission = MeetingPermission.creator;
                            break;
                          case 'ADMIN':
                            permission = MeetingPermission.admin;
                            break;
                          case 'PARTICIPANT':
                            permission = MeetingPermission.participant;
                            break;
                          default:
                            permission = MeetingPermission.participant;
                        }

                        // 更新角色状态
                        userRoleState.value = permission;
                        hasLoadedRole.value = true;
                        debugPrint(
                          '用户角色已保存: ${getMeetingPermissionText(permission)}',
                        );
                        return;
                      }
                    }

                    // 如果没找到，尝试从meeting对象中获取
                    final meeting = await ref.read(
                      meetingDetailProvider(meetingId).future,
                    );
                    if (meeting.organizerId == currentUserId.value) {
                      userRoleState.value = MeetingPermission.creator;
                    } else if (meeting.admins.contains(currentUserId.value)) {
                      userRoleState.value = MeetingPermission.admin;
                    } else if (meeting.blacklist.contains(
                      currentUserId.value,
                    )) {
                      userRoleState.value = MeetingPermission.blocked;
                    }

                    hasLoadedRole.value = true;
                    debugPrint(
                      '从meeting对象获取用户角色: ${getMeetingPermissionText(userRoleState.value)}',
                    );
                  }
                }
              } catch (e) {
                debugPrint('获取用户角色时出错: $e');
              }
            }

            // 执行获取角色的函数
            loadUserRole();
          }

          return null;
        }, [currentUserId.value]);

        // 修改获取当前用户ID的useEffect
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
              // 使用Future.microtask延迟更新全局缓存，避免在构建过程中修改provider
              Future.microtask(() {
                if (context.mounted) {
                  ref.read(chatWidgetCacheProvider.notifier).state = widget;
                }
              });
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
                  const Icon(
                    Icons.cancel_outlined,
                    size: 64,
                    color: Colors.red,
                  ),
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
        final signInStatusAsync = ref.watch(
          meetingSignInStatusProvider(meetingId),
        );

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
        final isPrivateMeeting =
            meeting.visibility == MeetingVisibility.private;

        // 是否显示签到列表按钮（只有创建者和管理员且私有会议可以查看）
        final canViewSignInList = isCreatorOrAdmin && isPrivateMeeting;

        // 构建底部导航栏
        Widget buildBottomNavBar() {
          // 获取未读消息计数
          final unreadCount = ref.watch(ChatWidget.unreadCountProvider);

          return BottomNavigationBar(
            currentIndex:
                selectedFeatureIndex.value < 0 ||
                        selectedFeatureIndex.value >= features.length
                    ? 0 // 默认选中第一项
                    : selectedFeatureIndex.value,
            onTap: (index) {
              // 如果点击的是聊天选项，重置未读消息计数
              if (index == 0) {
                ChatWidget.resetUnreadCount(ref);
              }
              selectedFeatureIndex.value =
                  selectedFeatureIndex.value == index ? -1 : index;
            },
            type: BottomNavigationBarType.fixed,
            items:
                features.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;

                  // 为聊天选项添加红点
                  if (index == 0 && unreadCount > 0) {
                    return BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(feature.icon),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade200.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(
                                minWidth: unreadCount > 99 ? 24 : 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      label: feature.label,
                    );
                  }

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
                      builder:
                          (context) => SignInListView(meetingId: meetingId),
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
                child: Builder(
                  builder: (context) {
                    // 使用本地状态变量获取角色
                    final userPermission = userRoleState.value;

                    // 根据不同权限设置不同颜色
                    Color bgColor;
                    Color textColor;

                    switch (userPermission) {
                      case MeetingPermission.creator:
                        bgColor = Colors.orange.shade100;
                        textColor = Colors.orange.shade800;
                        break;
                      case MeetingPermission.admin:
                        bgColor = Colors.blue.shade100;
                        textColor = Colors.blue.shade800;
                        break;
                      case MeetingPermission.blocked:
                        bgColor = Colors.red.shade100;
                        textColor = Colors.red.shade800;
                        break;
                      default:
                        bgColor = Colors.green.shade100;
                        textColor = Colors.green.shade800;
                    }

                    return Chip(
                      label: Text(getMeetingPermissionText(userPermission)),
                      backgroundColor: bgColor,
                      labelStyle: TextStyle(color: textColor, fontSize: 12),
                    );
                  },
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
                        child: Text(
                          '结束会议',
                          style: TextStyle(color: Colors.red),
                        ),
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
                    await handleExit();
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
          appBar: AppBar(
            title: Text(meeting.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: handleExit,
            ),
            actions: buildActions(),
          ),
          body: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              await handleExit();
            },
            child: Stack(
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
                                ref.watch(currentUserProvider).value?.name ??
                                '当前用户',
                            // 传递用户角色信息 - 使用本地存储的角色状态
                            isAdminOrCreator:
                                userRoleState.value ==
                                    MeetingPermission.creator ||
                                userRoleState.value == MeetingPermission.admin,
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
                                        color: features[selectedFeatureIndex
                                                .value]
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
                                            features[selectedFeatureIndex.value]
                                                .icon,
                                            color:
                                                features[selectedFeatureIndex
                                                        .value]
                                                    .color,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            features[selectedFeatureIndex.value]
                                                .label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  features[selectedFeatureIndex
                                                          .value]
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
                                                () =>
                                                    selectedFeatureIndex.value =
                                                        -1,
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
          ),
        );
      },
    );
  }
}
