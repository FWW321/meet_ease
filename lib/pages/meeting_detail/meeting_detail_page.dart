import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../providers/meeting_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/meeting_password_dialog.dart';
import '../meeting_process/meeting_process_page.dart';
import '../meeting_settings_page.dart';
import 'meeting_detail_ui_components.dart';
import 'meeting_detail_dialogs.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';
import '../../utils/http_utils.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 每次页面依赖变化时刷新数据
    // 1. 刷新会议详情数据
    ref.invalidate(meetingDetailProvider(widget.meetingId));

    // 2. 刷新黑名单状态(如果用户ID不为空)
    if (currentUserId != null && currentUserId!.isNotEmpty) {
      ref.invalidate(
        isUserInBlacklistProvider(widget.meetingId, currentUserId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDetailProvider(widget.meetingId));
    final theme = Theme.of(context);

    // 当用户ID存在时，每次打开页面时都强制刷新黑名单状态
    if (currentUserId != null) {
      // 取消这里的预加载，以避免使用可能过时的缓存
      // 我们已经在initState和didChangeDependencies中处理刷新
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('会议详情'),
        elevation: 0,
        centerTitle: true,
        actions: [
          meetingAsync.when(
            data: (meeting) => _buildAppBarActions(context, meeting),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: meetingAsync.when(
        data: (meeting) => _buildMeetingDetailContent(context, meeting),
        loading:
            () => const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(),
              ),
            ),
        error:
            (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // 构建应用栏操作按钮
  Widget _buildAppBarActions(BuildContext context, Meeting meeting) {
    // 判断是否显示菜单
    if (currentUserId != null) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
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
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('取消会议'),
                  ],
                ),
              ),
            );
          }

          // 只有私有会议可以申请请假（即将开始和进行中的会议）
          if ((meeting.status == MeetingStatus.upcoming ||
                  meeting.status == MeetingStatus.ongoing) &&
              meeting.visibility == MeetingVisibility.private) {
            items.add(
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text('申请请假'),
                  ],
                ),
              ),
            );
          }

          return items;
        },
      );
    }
    return const SizedBox.shrink();
  }

  // 构建会议详情内容
  Widget _buildMeetingDetailContent(BuildContext context, Meeting meeting) {
    final theme = Theme.of(context);

    // 检查当前用户是否登录
    if (currentUserId == null) {
      // 未登录用户直接显示会议详情
      return _buildMeetingDetailUI(context, meeting, theme);
    }

    // 监听黑名单状态，但避免重复刷新
    return Consumer(
      builder: (context, ref, child) {
        // 添加一个刷新key，确保每次构建都重新请求
        final refreshKey = DateTime.now().millisecondsSinceEpoch;

        // 使用watch而不是read，以便Riverpod能够管理缓存和状态
        final blacklistStatus = ref.watch(
          isUserInBlacklistProvider(meeting.id, currentUserId!),
        );

        debugPrint('刷新黑名单状态检查[$refreshKey]');

        return blacklistStatus.when(
          data: (isInBlacklist) {
            debugPrint('获取到黑名单检查结果[$refreshKey]: $isInBlacklist');
            if (isInBlacklist) {
              // 用户在黑名单中，显示被封禁消息
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '您无法加入此会议',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '您没有权限访问此会议内容',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 用户不在黑名单中，显示会议详情
            return _buildMeetingDetailUI(context, meeting, theme);
          },
          loading:
              () => const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(),
                ),
              ),
          error: (error, stack) {
            // 发生错误时，继续显示会议详情
            debugPrint('检查黑名单状态失败: $error');
            return _buildMeetingDetailUI(context, meeting, theme);
          },
        );
      },
    );
  }

  // 构建会议详情UI
  Widget _buildMeetingDetailUI(
    BuildContext context,
    Meeting meeting,
    ThemeData theme,
  ) {
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 会议状态徽章
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getMeetingStatusColor(
                          meeting.status,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMeetingStatusIcon(meeting.status),
                            size: 16,
                            color: getMeetingStatusColor(meeting.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            getMeetingStatusText(meeting.status),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: getMeetingStatusColor(meeting.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 会议类型标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        getMeetingTypeText(meeting.type),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 会议标题
                Text(
                  meeting.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 会议描述
                if (meeting.description != null &&
                    meeting.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      meeting.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 用户权限卡片
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withAlpha(51)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: getPermissionColor(
                              userPermission,
                            ).withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPermissionIcon(userPermission),
                            color: getPermissionColor(userPermission),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '您的角色',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getMeetingPermissionText(userPermission),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: getPermissionColor(userPermission),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 时间和地点卡片
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withAlpha(51)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '时间与地点',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 开始时间
                    Row(
                      children: [
                        const Icon(Icons.event, color: Colors.blue, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '开始时间',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatDateTime(meeting.startTime),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 11),
                      child: SizedBox(
                        height: 24,
                        child: VerticalDivider(thickness: 1),
                      ),
                    ),

                    // 结束时间
                    Row(
                      children: [
                        const Icon(
                          Icons.event_busy,
                          color: Colors.orange,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '结束时间',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              formatDateTime(meeting.endTime),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // 地点
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '地点',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                meeting.location,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 组织者和管理员列表
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildOrganizersAndAdminsList(context, ref, meeting),
          ),
        ),

        // 参会人员列表
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildParticipantsList(
              context,
              ref,
              meeting,
              widget.meetingId,
              currentUserId,
            ),
          ),
        ),

        // 如果会议已取消，显示取消原因
        if (isCancelled)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withAlpha(77)),
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
                      const SizedBox(width: 12),
                      Text(
                        '此会议已取消',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '会议已被取消，无法进入或修改会议设置。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 底部按钮
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 权限管理按钮 - 只对管理员在未结束且未取消的会议中显示
                if (canConfigureMeeting && !isCancelled)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('权限管理'),
                      onPressed: () => _navigateToSettings(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                // 进入会议按钮 - 已取消的会议无法进入
                if (!isCancelled)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          meeting.status == MeetingStatus.upcoming ||
                                  meeting.status == MeetingStatus.cancelled
                              ? null // 即将开始或已取消的会议禁用按钮
                              : () => _joinMeeting(context, meeting),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                      child: Text(
                        meeting.status == MeetingStatus.upcoming
                            ? '会议即将开始，暂不可进入'
                            : meeting.status == MeetingStatus.completed
                            ? '查看已结束的会议'
                            : '进入会议',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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

  // 获取会议状态图标
  IconData _getMeetingStatusIcon(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.upcoming:
        return Icons.upcoming;
      case MeetingStatus.ongoing:
        return Icons.meeting_room;
      case MeetingStatus.completed:
        return Icons.check_circle;
      case MeetingStatus.cancelled:
        return Icons.cancel;
    }
  }

  // 获取权限图标
  IconData _getPermissionIcon(MeetingPermission permission) {
    switch (permission) {
      case MeetingPermission.creator:
        return Icons.star;
      case MeetingPermission.admin:
        return Icons.admin_panel_settings;
      case MeetingPermission.participant:
        return Icons.person;
      case MeetingPermission.blocked:
        return Icons.block;
    }
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

    // 检查用户是否在黑名单中（直接调用API，完全避免缓存）
    if (currentUserId != null) {
      try {
        // 生成一个时间戳作为请求标识
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // 创建一个直接的HTTP请求而不使用provider缓存
        final uri = Uri.parse(
          '${AppConstants.apiBaseUrl}/blacklist/check',
        ).replace(
          queryParameters: {
            'meetingId': meeting.id,
            'userId': currentUserId!,
            '_t': timestamp.toString(), // 添加时间戳防止缓存
          },
        );

        final response = await http.get(
          uri,
          headers: HttpUtils.createHeaders(),
        );

        if (response.statusCode == 200) {
          final responseData = HttpUtils.decodeResponse(response);

          if (responseData['code'] == 200) {
            final isInBlacklist = responseData['data'] as bool;
            debugPrint('进入会议前直接检查黑名单状态[$timestamp]: $isInBlacklist');

            if (isInBlacklist) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('您已被列入黑名单，无法进入此会议'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }
        }
      } catch (e) {
        // 检查失败时记录错误，但允许用户继续
        debugPrint('直接检查黑名单状态失败: $e');
      }
    }

    debugPrint('准备进入会议 - ID: ${meeting.id}, 标题: ${meeting.title}');
    debugPrint(
      '会议密码状态: ${meeting.password != null && meeting.password!.isNotEmpty ? "需要密码: ${meeting.password}" : "不需要密码"}',
    );

    // 检查会议是否需要密码
    if (meeting.password != null && meeting.password!.isNotEmpty) {
      debugPrint('会议需要密码验证');
      if (!context.mounted) return;

      try {
        // 显示密码验证对话框
        debugPrint('显示密码验证对话框');
        final passwordValid = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => MeetingPasswordDialog(meetingId: widget.meetingId),
        );

        debugPrint('密码验证结果类型: ${passwordValid.runtimeType}');
        debugPrint('密码验证结果值: $passwordValid');

        // 如果密码验证返回null，表示用户取消；如果返回false，表示密码错误
        if (passwordValid == null) {
          debugPrint('用户取消了密码验证');
          // 用户取消验证，直接返回
          return;
        } else if (passwordValid == false) {
          debugPrint('密码验证失败，显示错误提示');
          // 密码验证失败
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密码验证失败，无法进入会议'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        debugPrint('密码验证通过，继续进入会议');
      } catch (e) {
        // 处理密码验证过程中的任何错误
        debugPrint('密码验证过程出错: $e');
        if (context.mounted) {
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
    debugPrint('密码验证通过或不需要密码，准备进入会议');
    if (!context.mounted) return;

    // 导航到会议进程页面并等待结果
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MeetingProcessPage(meetingId: widget.meetingId),
      ),
    );

    // 如果返回结果为true，表示需要刷新会议详情
    if (result == true) {
      ref.invalidate(meetingDetailProvider(widget.meetingId));
    }
  }
}
