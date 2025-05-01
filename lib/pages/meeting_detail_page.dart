import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/meeting.dart';
import '../providers/meeting_providers.dart';
import '../providers/user_providers.dart';
import '../providers/chat_providers.dart';
import '../services/api_chat_service.dart';
import '../services/service_providers.dart';
import '../widgets/meeting_password_dialog.dart';
import 'meeting_process/meeting_process_page.dart';
import 'meeting_settings_page.dart';

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

    // 添加日志输出会议详情
    meetingAsync.whenData((meeting) {
      print('会议详情加载完成 - ID: ${meeting.id}');
      print('会议标题: ${meeting.title}');
      print('会议密码: ${meeting.password != null ? meeting.password : "无密码"}');
      print('会议状态: ${meeting.status}');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('会议详情'),
        actions: [
          // 右上角操作菜单
          meetingAsync.when(
            data: (meeting) {
              // 只有创建者可以看到更多操作按钮
              if (currentUserId != null &&
                  meeting.isCreatorOnly(currentUserId!)) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'cancel' &&
                        meeting.status == MeetingStatus.upcoming) {
                      _showCancelConfirmDialog(context, ref, currentUserId!);
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuItem<String>>[];

                    // 只有即将开始的会议可以取消
                    if (meeting.status == MeetingStatus.upcoming) {
                      items.add(
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('取消会议'),
                        ),
                      );
                    }

                    return items;
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: meetingAsync.when(
        data: (meeting) {
          // 检查用户是否被拉黑
          if (currentUserId != null &&
              meeting.blacklist.contains(currentUserId)) {
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
              if (meeting.description != null &&
                  meeting.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    meeting.description!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              // 会议状态
              _buildInfoCard([
                _buildInfoItem(
                  '状态',
                  getMeetingStatusText(meeting.status),
                  icon: Icons.event_available,
                  color: getMeetingStatusColor(meeting.status),
                ),
                _buildInfoItem(
                  '类型',
                  getMeetingTypeText(meeting.type),
                  icon: Icons.category,
                ),
                _buildInfoItem(
                  '您的角色',
                  getMeetingPermissionText(userPermission),
                  icon: Icons.person,
                  color: _getPermissionColor(userPermission),
                ),
              ]),

              // 构建组织者和管理员列表（用于公开和可搜索会议）
              _buildOrganizersAndAdminsList(context, meeting),

              // 时间和地点
              _buildInfoCard([
                _buildInfoItem(
                  '开始时间',
                  _formatDateTime(meeting.startTime),
                  icon: Icons.access_time,
                ),
                _buildInfoItem(
                  '结束时间',
                  _formatDateTime(meeting.endTime),
                  icon: Icons.access_time_filled,
                ),
                _buildInfoItem('地点', meeting.location, icon: Icons.location_on),
                // 如果是可搜索会议，显示会议码
                if (meeting.visibility == MeetingVisibility.searchable)
                  _buildInfoItem(
                    '会议码',
                    meeting.id,
                    icon: Icons.qr_code,
                    color: Colors.orange,
                  ),
              ]),

              // 仅私有会议显示参会人员列表
              _buildParticipantsList(context, meeting),

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
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
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

  // 构建会议参与者列表
  Widget _buildParticipantsList(BuildContext context, Meeting meeting) {
    // 如果不是私有会议，直接返回空组件，不显示参会人员列表
    if (meeting.visibility != MeetingVisibility.private) {
      return const SizedBox.shrink();
    }

    final participantsAsync = ref.watch(
      meetingParticipantsProvider(widget.meetingId),
    );
    final canManageMeeting =
        currentUserId != null && meeting.canUserManage(currentUserId!);

    // 为私有会议设置标题和描述
    const titleText = '允许参加的人员';
    const descriptionText = '只有被邀请的人员才能参加此私有会议';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  titleText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // 私有会议用户是管理员时，显示管理按钮
                if (canManageMeeting)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('管理'),
                    onPressed: () {
                      // TODO: 实现添加/删除参会人员的功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('管理参会人员功能即将上线')),
                      );
                    },
                  ),
              ],
            ),
            // 显示描述文字
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                descriptionText,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            participantsAsync.when(
              data: (participants) {
                if (participants.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return Column(
                  children:
                      participants.map((user) {
                        // 确定用户角色标签
                        Widget? roleTag;
                        if (user.id == meeting.organizerId) {
                          roleTag = _buildRoleTag('创建者', Colors.orange);
                        } else if (meeting.admins.contains(user.id)) {
                          roleTag = _buildRoleTag('管理员', Colors.blue);
                        }

                        // 使用用户名提供者来获取最新用户名
                        return Consumer(
                          builder: (context, ref, child) {
                            final userNameAsync = ref.watch(
                              userNameProvider(user.id),
                            );

                            return userNameAsync.when(
                              data: (userName) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(51),
                                    child: Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(userName),
                                  subtitle:
                                      user.email.isNotEmpty
                                          ? Text(user.email)
                                          : null,
                                  trailing: roleTag,
                                );
                              },
                              loading:
                                  () => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor.withAlpha(51),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    title: Text(user.name),
                                    subtitle:
                                        user.email.isNotEmpty
                                            ? Text(user.email)
                                            : null,
                                    trailing: roleTag,
                                  ),
                              error:
                                  (_, __) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor.withAlpha(51),
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
                                    subtitle:
                                        user.email.isNotEmpty
                                            ? Text(user.email)
                                            : null,
                                    trailing: roleTag,
                                  ),
                            );
                          },
                        );
                      }).toList(),
                );
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (error, _) => Center(child: Text('加载参会人员失败: $error')),
            ),
          ],
        ),
      ),
    );
  }

  // 构建组织者和管理员列表（用于公开和可搜索会议）
  Widget _buildOrganizersAndAdminsList(BuildContext context, Meeting meeting) {
    // 如果是私有会议，不显示此组件（私有会议显示完整参会人员列表）
    if (meeting.visibility == MeetingVisibility.private) {
      return const SizedBox.shrink();
    }

    String descriptionText;
    if (meeting.visibility == MeetingVisibility.public) {
      descriptionText = '这是一个公开会议，任何人都可以参加';
    } else {
      descriptionText = '这是一个可搜索会议，知道会议ID的人都可以参加';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '组织者和管理员',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                descriptionText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),

            // 显示组织者信息
            Consumer(
              builder: (context, ref, child) {
                final organizerNameAsync = ref.watch(
                  userNameProvider(meeting.organizerId),
                );

                return organizerNameAsync.when(
                  data:
                      (name) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withAlpha(51),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                        title: Text(name),
                        subtitle: const Text('会议创建者'),
                        trailing: _buildRoleTag('创建者', Colors.orange),
                      ),
                  loading:
                      () => const ListTile(
                        leading: CircleAvatar(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        title: Text('加载中...'),
                        subtitle: Text('会议创建者'),
                      ),
                  error:
                      (_, __) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.error,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(meeting.organizerName),
                        subtitle: const Text('会议创建者（加载失败）'),
                      ),
                );
              },
            ),

            // 显示管理员列表
            Consumer(
              builder: (context, ref, child) {
                final managersAsync = ref.watch(
                  meetingManagersProvider(widget.meetingId),
                );

                return managersAsync.when(
                  data: (managers) {
                    if (managers.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            '管理员',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...managers
                            .map(
                              (manager) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withAlpha(51),
                                  child: Text(
                                    manager.name.isNotEmpty
                                        ? manager.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                                title: Text(manager.name),
                                trailing: _buildRoleTag('管理员', Colors.blue),
                                dense: true,
                              ),
                            )
                            .toList(),
                      ],
                    );
                  },
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  error:
                      (error, _) => Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          '加载管理员列表失败: $error',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建角色标签
  Widget _buildRoleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
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

  // 构建信息卡片
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color ?? Colors.grey[700]),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 获取权限对应的颜色
  Color _getPermissionColor(MeetingPermission permission) {
    switch (permission) {
      case MeetingPermission.creator:
        return Colors.orange;
      case MeetingPermission.admin:
        return Colors.blue;
      case MeetingPermission.participant:
        return Colors.green;
      case MeetingPermission.blocked:
        return Colors.red;
    }
  }

  // 显示取消会议确认对话框
  void _showCancelConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String creatorId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('取消会议'),
            content: const Text('确定要取消此会议吗？此操作不可撤销，所有参会者将收到会议取消的通知。'),
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
                    // 调用取消会议服务
                    final meetingService = ref.read(meetingServiceProvider);
                    await meetingService.cancelMeeting(
                      widget.meetingId,
                      creatorId,
                    );

                    // 刷新会议详情
                    ref.invalidate(meetingDetailProvider(widget.meetingId));

                    if (context.mounted) {
                      // 关闭加载指示器
                      Navigator.of(context).pop();

                      // 显示成功提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('会议已成功取消'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // 关闭加载指示器
                      Navigator.of(context).pop();

                      // 显示错误提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('取消会议失败: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('确定取消'),
              ),
            ],
          ),
    );
  }
}
