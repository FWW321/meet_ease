import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/chat_providers.dart';
import '../../services/api_chat_service.dart';
import '../../services/service_providers.dart';
import '../../widgets/meeting_password_dialog.dart';
import '../meeting_process/meeting_process_page.dart';
import '../meeting_settings_page.dart';
import 'meeting_detail_ui_components.dart';
import 'meeting_detail_dialogs.dart';

class MeetingDetailPage extends ConsumerStatefulWidget {
  final String meetingId;

  const MeetingDetailPage({required this.meetingId, super.key});

  @override
  ConsumerState<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends ConsumerState<MeetingDetailPage> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDetailProvider(widget.meetingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('会议详情'),
        actions: [
          // 右上角操作菜单
          meetingAsync.when(
            data: (meeting) => _buildAppBarActions(context, meeting),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: meetingAsync.when(
        data: (meeting) => _buildMeetingDetailContent(context, meeting),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  // 构建应用栏操作按钮
  Widget _buildAppBarActions(BuildContext context, Meeting meeting) {
    // 判断是否显示菜单
    if (currentUserId != null) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'cancel' &&
              meeting.status == MeetingStatus.upcoming &&
              meeting.isCreatorOnly(currentUserId!)) {
            showCancelConfirmDialog(context, ref, currentUserId!);
          } else if (value == 'leave') {
            showLeaveRequestDialog(context, ref, meeting);
          }
        },
        itemBuilder: (context) {
          final items = <PopupMenuItem<String>>[];

          // 只有创建者可以取消即将开始的会议
          if (meeting.status == MeetingStatus.upcoming &&
              meeting.isCreatorOnly(currentUserId!)) {
            items.add(
              const PopupMenuItem(value: 'cancel', child: Text('取消会议')),
            );
          }

          // 只有私有会议可以申请请假（即将开始和进行中的会议）
          if ((meeting.status == MeetingStatus.upcoming ||
                  meeting.status == MeetingStatus.ongoing) &&
              meeting.visibility == MeetingVisibility.private) {
            items.add(const PopupMenuItem(value: 'leave', child: Text('申请请假')));
          }

          return items;
        },
      );
    }
    return const SizedBox.shrink();
  }

  // 构建会议详情内容
  Widget _buildMeetingDetailContent(BuildContext context, Meeting meeting) {
    // 检查用户是否被拉黑
    if (currentUserId != null && meeting.blacklist.contains(currentUserId)) {
      return const Center(
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
      );
    }

    // 检查用户是否可以管理会议
    final canManageMeeting =
        currentUserId != null && meeting.canUserManage(currentUserId!);

    // 检查会议是否可以设置（未结束的会议）
    final canConfigureMeeting =
        meeting.status != MeetingStatus.completed &&
        meeting.status != MeetingStatus.cancelled &&
        canManageMeeting;

    // 获取当前用户的权限
    final userPermission =
        currentUserId != null
            ? meeting.getUserPermission(currentUserId!)
            : MeetingPermission.participant;

    // 检查会议是否已取消
    final isCancelled = meeting.status == MeetingStatus.cancelled;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 会议标题
        Text(
          meeting.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // 会议描述
        if (meeting.description != null && meeting.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              meeting.description!,
              style: const TextStyle(color: Colors.grey),
            ),
          ),

        // 会议状态
        buildInfoCard([
          buildInfoItem(
            '状态',
            getMeetingStatusText(meeting.status),
            icon: Icons.event_available,
            color: getMeetingStatusColor(meeting.status),
          ),
          buildInfoItem(
            '类型',
            getMeetingTypeText(meeting.type),
            icon: Icons.category,
          ),
          buildInfoItem(
            '您的角色',
            getMeetingPermissionText(userPermission),
            icon: Icons.person,
            color: getPermissionColor(userPermission),
          ),
        ]),

        // 构建组织者和管理员列表（用于公开和可搜索会议）
        buildOrganizersAndAdminsList(context, ref, meeting),

        // 时间和地点
        buildInfoCard([
          buildInfoItem(
            '开始时间',
            formatDateTime(meeting.startTime),
            icon: Icons.access_time,
          ),
          buildInfoItem(
            '结束时间',
            formatDateTime(meeting.endTime),
            icon: Icons.access_time_filled,
          ),
          buildInfoItem('地点', meeting.location, icon: Icons.location_on),
          // 如果是可搜索会议，显示会议码
          if (meeting.visibility == MeetingVisibility.searchable)
            buildInfoItem(
              '会议码',
              meeting.id,
              icon: Icons.qr_code,
              color: Colors.orange,
            ),
        ]),

        // 仅私有会议显示参会人员列表
        buildParticipantsList(
          context,
          ref,
          meeting,
          widget.meetingId,
          currentUserId,
        ),

        // 如果会议已取消，显示取消原因
        if (isCancelled)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha(76)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      '此会议已取消',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '会议已被取消，无法进入或修改会议设置。',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // 权限管理按钮 - 只对管理员在未结束且未取消的会议中显示
        if (canConfigureMeeting && !isCancelled)
          ElevatedButton.icon(
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('权限管理'),
            onPressed: () => _navigateToSettings(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        const SizedBox(height: 16),

        // 进入会议按钮 - 已取消的会议无法进入
        if (!isCancelled)
          ElevatedButton(
            onPressed:
                meeting.status == MeetingStatus.upcoming ||
                        meeting.status == MeetingStatus.cancelled
                    ? null // 即将开始或已取消的会议禁用按钮
                    : () => _joinMeeting(context, meeting),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
            ),
            child: Text(
              meeting.status == MeetingStatus.upcoming
                  ? '会议即将开始，暂不可进入'
                  : meeting.status == MeetingStatus.completed
                  ? '查看已结束的会议'
                  : '进入会议',
            ),
          ),
      ],
    );
  }

  // 导航到权限管理页面
  void _navigateToSettings(BuildContext context) {
    if (currentUserId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MeetingSettingsPage(
              meetingId: widget.meetingId,
              currentUserId: currentUserId!,
            ),
      ),
    );
  }

  // 进入会议
  Future<void> _joinMeeting(BuildContext context, Meeting meeting) async {
    // 如果会议已取消，不允许进入
    if (meeting.status == MeetingStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会议已取消，无法进入'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('准备进入会议 - ID: ${meeting.id}, 标题: ${meeting.title}');
    print(
      '会议密码状态: ${meeting.password != null && meeting.password!.isNotEmpty ? "需要密码: ${meeting.password}" : "不需要密码"}',
    );

    // 检查会议是否需要密码
    if (meeting.password != null && meeting.password!.isNotEmpty) {
      print('会议需要密码验证');
      if (!mounted) return;

      try {
        // 显示密码验证对话框
        print('显示密码验证对话框');
        final passwordValid = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => MeetingPasswordDialog(meetingId: widget.meetingId),
        );

        print('密码验证结果类型: ${passwordValid.runtimeType}');
        print('密码验证结果值: $passwordValid');

        // 如果密码验证返回null，表示用户取消；如果返回false，表示密码错误
        if (passwordValid == null) {
          print('用户取消了密码验证');
          // 用户取消验证，直接返回
          return;
        } else if (passwordValid == false) {
          print('密码验证失败，显示错误提示');
          // 密码验证失败
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('密码验证失败，无法进入会议'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        print('密码验证通过，继续进入会议');
      } catch (e) {
        // 处理密码验证过程中的任何错误
        print('密码验证过程出错: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('密码验证过程出错: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // 密码验证成功或不需要密码，进入会议
    print('密码验证通过或不需要密码，准备进入会议');
    if (!mounted) return;

    // 如果是进行中的会议，建立WebSocket连接
    if (meeting.status == MeetingStatus.ongoing && currentUserId != null) {
      try {
        // 连接到WebSocket
        await ref.read(
          webSocketConnectProvider({
            'meetingId': widget.meetingId,
            'userId': currentUserId!,
          }).future,
        );

        // WebSocket连接成功后，将其设置给ApiChatService使用
        final chatService = ref.read(chatServiceProvider);
        if (chatService is ApiChatService) {
          chatService.useExternalWebSocket(ref, widget.meetingId);
          print('已将外部WebSocket连接设置给ApiChatService使用');
        }
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WebSocket连接失败: $e'),
            backgroundColor: Colors.orange,
          ),
        );
        // 失败但仍继续进入会议（可能使用HTTP请求作为回退方式）
      }
    }

    if (!mounted) return;

    // 打开会议处理页面，并等待页面关闭
    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MeetingProcessPage(
              meetingId: widget.meetingId,
              meeting: meeting,
            ),
      ),
    );

    // 页面关闭后，断开WebSocket连接（无论页面如何关闭）
    if (!mounted) return;

    final isConnected = ref.read(webSocketConnectedProvider);
    if (isConnected) {
      try {
        await ref.read(webSocketDisconnectProvider)();
      } catch (e) {
        print('断开WebSocket连接失败: $e');
      }
    }
  }
}
