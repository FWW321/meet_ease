import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/webrtc_providers.dart';
import '../providers/user_providers.dart';
import '../services/webrtc_service.dart';
import '../services/service_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../providers/chat_providers.dart';
import '../providers/meeting_process_providers.dart' as meeting_providers;
import '../providers/meeting_providers.dart';

/// 语音会议组件
class VoiceMeetingWidget extends HookConsumerWidget {
  final String meetingId;
  final String userName;
  final bool isReadOnly;
  final bool isAdminOrCreator; // 添加是否是管理员或创建者的属性

  const VoiceMeetingWidget({
    required this.meetingId,
    required this.userName,
    this.isReadOnly = false,
    this.isAdminOrCreator = false, // 默认值为false
    super.key,
  });

  // 检查并申请麦克风权限
  Future<bool> _checkAndRequestMicrophonePermission(
    BuildContext context,
  ) async {
    // 检查麦克风权限状态
    PermissionStatus micStatus = await Permission.microphone.status;

    // 如果已经拥有权限，直接返回true
    if (micStatus.isGranted) return true;

    // 如果权限已被永久拒绝，引导用户前往设置页面
    if (micStatus.isPermanentlyDenied) {
      if (!context.mounted) return false;
      return await _showPermissionSettingsDialog(context, '麦克风');
    }

    // 请求麦克风权限
    micStatus = await Permission.microphone.request();

    // 返回权限状态
    return micStatus.isGranted;
  }

  // 显示权限设置对话框
  Future<bool> _showPermissionSettingsDialog(
    BuildContext context,
    String permissionName,
  ) async {
    if (!context.mounted) return false;

    final bool? goToSettings = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('需要权限'),
            content: Text('使用语音会议需要$permissionName权限，请在设置中开启'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('前往设置'),
              ),
            ],
          ),
    );

    if (goToSettings == true) {
      await openAppSettings();
      // 返回false，因为我们不知道用户是否在设置中授予了权限
      // 用户需要再次尝试启用麦克风
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取当前用户ID
    final userIdAsync = ref.watch(currentUserIdProvider);

    // 是否已加入会议
    final isJoined = useState(false);

    // 获取聊天服务
    final chatService = ref.watch(chatServiceProvider);

    // 监听WebSocket连接状态
    final isWebSocketConnected = useState(false);

    // 参会人员列表
    final participantsAsync = ref.watch(webRTCParticipantsProvider);

    // 麦克风状态 - 从参会人员列表中获取当前用户的麦克风状态
    final isMicEnabled = participantsAsync.when(
      data: (participants) {
        // 获取当前用户ID
        final userId = userIdAsync.value ?? '';

        // 寻找当前用户
        final currentUser = participants.firstWhere(
          (p) => p.isMe || p.id == userId,
          orElse:
              () => MeetingParticipant(id: userId, name: userName, isMe: true),
        );
        // 返回麦克风状态（未静音 = 麦克风开启）
        return !currentUser.isMuted;
      },
      loading: () => ref.watch(webRTCMicrophoneStatusProvider), // 加载时使用全局状态
      error: (_, __) => ref.watch(webRTCMicrophoneStatusProvider), // 出错时使用全局状态
    );

    // 主题数据
    final theme = Theme.of(context);

    // 辅助函数 - 获取是否静音
    bool isMuted(AsyncValue<List<MeetingParticipant>> participantsState) {
      return participantsState.when(
        data: (participants) {
          // 获取当前用户ID
          final userId = userIdAsync.value ?? '';

          // 寻找当前用户
          final currentUser = participants.firstWhere(
            (p) => p.isMe || p.id == userId,
            orElse:
                () =>
                    MeetingParticipant(id: userId, name: userName, isMe: true),
          );
          return currentUser.isMuted;
        },
        loading: () => !ref.watch(webRTCMicrophoneStatusProvider), // 加载时使用全局状态
        error:
            (_, __) => !ref.watch(webRTCMicrophoneStatusProvider), // 出错时使用全局状态
      );
    }

    // 切换麦克风状态
    Future<void> toggleMicrophone() async {
      // 获取当前麦克风状态，并切换到相反状态
      final currentMuted = isMuted(participantsAsync);
      final shouldEnable = currentMuted; // 如果当前是静音，则应该启用

      // 调试信息
      debugPrint('当前麦克风状态: ${currentMuted ? "静音" : "开启"}');
      debugPrint('切换麦克风到: ${shouldEnable ? "开启" : "静音"}');

      // 如果要开启麦克风，需要检查麦克风权限
      if (shouldEnable) {
        final hasPermission = await _checkAndRequestMicrophonePermission(
          context,
        );
        if (!hasPermission) {
          // 没有麦克风权限，无法开启麦克风
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('无法开启麦克风：权限被拒绝')));
          }
          return;
        }
      }

      ref
          .read(toggleMicrophoneProvider(shouldEnable).future)
          .then((_) {
            // 操作成功
            debugPrint('麦克风状态已切换');
          })
          .catchError((error) {
            // 操作失败
            debugPrint('麦克风切换失败: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('麦克风切换失败: $error')));
            }
          });
    }

    // 已结束会议显示模式
    if (isReadOnly) {
      return Column(
        children: [
          // 会议记录标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, color: Colors.grey),
                const SizedBox(width: 12),

                const Text(
                  '会议语音记录',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 参会人员列表标题
          Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 8),
              Text('参会人员', style: theme.textTheme.titleMedium),
            ],
          ),

          const SizedBox(height: 16),

          // 参会人员列表
          Expanded(
            child: participantsAsync.when(
              data:
                  (participants) => _buildParticipantsList(
                    participants,
                    context,
                    userIdAsync.value ?? '',
                    showSpeakingStatus: false,
                    showMicStatus: false,
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) =>
                      Center(child: Text('无法加载参会人员记录: ${error.toString()}')),
            ),
          ),
        ],
      );
    }

    // 显示加载指示器，直到获取到用户ID
    if (userIdAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 处理错误情况
    if (userIdAsync.hasError) {
      return Center(child: Text('获取用户信息失败: ${userIdAsync.error}'));
    }

    // 确保用户ID可用
    final userId = userIdAsync.value ?? '';
    if (userId.isEmpty) {
      return const Center(child: Text('用户未登录或无法获取用户ID'));
    }

    // 加入会议（仅执行一次）- 只有非只读模式才执行
    useEffect(() {
      // 如果已加入，不重复加入
      if (isJoined.value) return null;

      // 加入会议
      ref
          .read(
            joinMeetingProvider({
              'meetingId': meetingId,
              'userId': userId,
              'userName': userName,
            }).future,
          )
          .then((_) {
            isJoined.value = true;
          })
          .catchError((error) {
            debugPrint('加入会议失败: $error');
          });

      // 离开会议时清理资源
      return () async {
        // 使用 webSocketDisconnectProvider 断开连接
        await ref.read(webSocketDisconnectProvider)();

        // 离开 WebRTC 会议
        await ref.read(leaveMeetingProvider.future);
      };
    }, [userId, chatService]); // 添加 chatService 作为依赖

    // 监听WebSocket连接状态
    useEffect(() {
      // 监听连接状态流
      final subscription = chatService.connectionStateStream.listen((
        connected,
      ) {
        isWebSocketConnected.value = connected;
        if (connected) {
          debugPrint('更新UI: WebSocket已连接，显示"会议已连接"');
        } else {
          debugPrint('更新UI: WebSocket已断开，显示"正在连接会议..."');
        }
      });

      return () {
        subscription.cancel();
      };
    }, [chatService, meetingId, userIdAsync.value]);

    // 获取当前用户信息
    final currentUserAsync = participantsAsync.when(
      data: (participants) {
        final currentUser = participants.firstWhere(
          (p) => p.isMe || p.id == userId,
          orElse:
              () => MeetingParticipant(id: userId, name: userName, isMe: true),
        );
        return currentUser;
      },
      loading: () => MeetingParticipant(id: userId, name: userName, isMe: true),
      error:
          (_, __) => MeetingParticipant(id: userId, name: userName, isMe: true),
    );

    // 获取参会人员数量
    final participantCount = useState(0);

    // 使用Effect更新参会人员数量
    useEffect(() {
      participantsAsync.whenData((participants) {
        final count =
            participants.where((p) => !p.isMe && p.id != userId).length;
        participantCount.value = count;
      });
      return null;
    }, [participantsAsync]);

    // 检查当前用户是否为管理员或创建者
    final isAdmin =
        isAdminOrCreator ||
        currentUserAsync.isAdmin ||
        currentUserAsync.isCreator;

    // 进行中会议的界面
    return Column(
      children: [
        // 会议状态栏
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 会议状态图标
              Icon(
                isWebSocketConnected.value ? Icons.mic : Icons.mic_off,
                color: isWebSocketConnected.value ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),

              // 会议状态文本
              Expanded(
                child: Text(
                  isWebSocketConnected.value ? '会议已连接' : '正在连接会议...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        isWebSocketConnected.value ? Colors.green : Colors.grey,
                  ),
                ),
              ),

              // 麦克风控制按钮 - 放在后面
              IconButton(
                icon: Icon(
                  isMicEnabled ? Icons.mic : Icons.mic_off,
                  color: isMicEnabled ? Colors.blue : Colors.red,
                ),
                onPressed: isJoined.value ? () => toggleMicrophone() : null,
                tooltip: isMicEnabled ? '关闭麦克风' : '开启麦克风',
              ),
            ],
          ),
        ),

        // 当前用户信息卡
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha(77)),
          ),
          child: Row(
            children: [
              // 用户头像
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),

              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('(我)', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isMicEnabled ? Icons.mic : Icons.mic_off,
                          size: 16,
                          color: isMicEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isMicEnabled ? '麦克风已开启' : '麦克风已静音',
                          style: TextStyle(
                            fontSize: 14,
                            color: isMicEnabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 角色标签
              if (currentUserAsync.isCreator)
                _buildRoleTag('创建者', Colors.orange),
              if (currentUserAsync.isAdmin && !currentUserAsync.isCreator)
                _buildRoleTag('管理员', Colors.blue),
            ],
          ),
        ),

        // 参会人员列表标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                Text('其他参会人员', style: theme.textTheme.titleMedium),
              ],
            ),

            // 参会人数统计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${participantCount.value} 人',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 参会人员列表
        Expanded(
          child: participantsAsync.when(
            data:
                (participants) =>
                    _buildParticipantsList(participants, context, userId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => Center(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '获取参会人员失败\n',
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
        ),
      ],
    );
  }

  // 构建参会人员列表
  Widget _buildParticipantsList(
    List<MeetingParticipant> participants,
    BuildContext context,
    String currentUserId, {
    bool showSpeakingStatus = true,
    bool showMicStatus = true,
  }) {
    // 过滤掉当前用户自己
    final filteredParticipants =
        participants.where((p) => !p.isMe && p.id != currentUserId).toList();

    // 简要日志，避免过多输出
    debugPrint('参会人员列表更新: ${filteredParticipants.length} 人');

    if (filteredParticipants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无其他参会人员', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredParticipants.length,
      itemBuilder: (context, index) {
        final participant = filteredParticipants[index];
        return _buildParticipantItem(
          participant,
          context,
          showSpeakingStatus: showSpeakingStatus,
          showMicStatus: showMicStatus,
        );
      },
    );
  }

  // 修改参会者项的构建方法，根据连接状态显示不同的图标
  Widget _buildParticipantItem(
    MeetingParticipant participant,
    BuildContext context, {
    bool showSpeakingStatus = true,
    bool showMicStatus = true,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        // 在Consumer内部获取WebRTC服务实例
        final webrtcService = ref.read(webRTCServiceProvider);
        // 检查与此参会者的连接状态
        final isPeerConnected = webrtcService.isPeerConnected(participant.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(
              participant.name.isNotEmpty
                  ? participant.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          title: Text(participant.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 角色标签
              if (participant.isCreator) _buildRoleTag('创建者', Colors.orange),
              if (participant.isAdmin && !participant.isCreator)
                _buildRoleTag('管理员', Colors.blue),
              const SizedBox(width: 4),

              // 麦克风状态图标 - 根据连接状态显示不同图标
              if (showMicStatus)
                isPeerConnected
                    ? Icon(
                      participant.isMuted ? Icons.mic_off : Icons.mic,
                      color: participant.isMuted ? Colors.red : Colors.green,
                      size: 20,
                    )
                    : SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // 构建角色标签
  Widget _buildRoleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
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
}
