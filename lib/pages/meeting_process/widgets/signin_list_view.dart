import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../models/user.dart';
import '../../../models/meeting.dart';
import '../../../providers/meeting_providers.dart';

/// 会议签到列表视图
class SignInListView extends HookConsumerWidget {
  final String meetingId;

  const SignInListView({required this.meetingId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用useState记录是否已经加载过数据
    final hasInitialized = useState(false);

    // 在构建时（而不是useEffect中）刷新数据
    if (!hasInitialized.value) {
      // 标记为已初始化
      hasInitialized.value = true;
      // 在下一帧执行刷新，避免在构建过程中修改状态
      Future.microtask(
        () => ref.invalidate(meetingParticipantsProvider(meetingId)),
      );
    }

    // 获取参会人员列表
    final participantsAsync = ref.watch(meetingParticipantsProvider(meetingId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          '签到列表',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 添加手动刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新数据',
            onPressed: () {
              // 手动刷新数据
              ref.invalidate(meetingParticipantsProvider(meetingId));
            },
          ),
        ],
      ),
      body: participantsAsync.when(
        data: (participants) {
          if (participants.isEmpty) {
            return _buildEmptyState(context);
          }

          // 计算签到情况统计
          final totalCount = participants.length;
          final signedCount =
              participants
                  .where(
                    (u) => u.signInStatus == '已签到' || u.leaveStatus == '请假',
                  )
                  .length;
          final notSignedCount = totalCount - signedCount;

          // 按签到状态分组
          final signedUsers =
              participants
                  .where(
                    (u) => u.signInStatus == '已签到' && u.leaveStatus != '请假',
                  )
                  .toList();
          final leaveUsers =
              participants.where((u) => u.leaveStatus == '请假').toList();
          final notSignedUsers =
              participants
                  .where(
                    (u) => u.signInStatus != '已签到' && u.leaveStatus != '请假',
                  )
                  .toList();

          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async {
              // 下拉刷新数据
              ref.invalidate(meetingParticipantsProvider(meetingId));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 顶部统计信息卡片
                SliverToBoxAdapter(
                  child: _buildStatisticsCard(
                    context,
                    totalCount,
                    signedCount,
                    notSignedCount,
                  ),
                ),

                // 已签到人员列表
                if (signedUsers.isNotEmpty) ...[
                  _buildGroupHeader(
                    context,
                    '已签到人员',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildUserListItem(context, signedUsers[index]),
                      childCount: signedUsers.length,
                    ),
                  ),
                ],

                // 已请假人员列表
                if (leaveUsers.isNotEmpty) ...[
                  _buildGroupHeader(
                    context,
                    '已请假人员',
                    Icons.event_busy,
                    Colors.blue,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildUserListItem(context, leaveUsers[index]),
                      childCount: leaveUsers.length,
                    ),
                  ),
                ],

                // 未签到人员列表
                if (notSignedUsers.isNotEmpty) ...[
                  _buildGroupHeader(context, '未签到人员', Icons.cancel, Colors.red),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildUserListItem(context, notSignedUsers[index]),
                      childCount: notSignedUsers.length,
                    ),
                  ),
                ],

                // 底部填充
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  // 构建空数据状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无参会人员数据',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('数据加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  // 构建统计信息卡片
  Widget _buildStatisticsCard(
    BuildContext context,
    int total,
    int signed,
    int notSigned,
  ) {
    final signRate =
        total > 0 ? (signed / total * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    '总人数',
                    total.toString(),
                    Icons.people,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildStatItem(
                    context,
                    '已签到',
                    signed.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatItem(
                    context,
                    '未签到',
                    notSigned.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ],
              ),
              const Divider(height: 32),
              // 签到率进度条
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('签到率', style: Theme.of(context).textTheme.bodyLarge),
                      Text(
                        '$signRate%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? signed / total : 0,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // 构建分组标题
  SliverToBoxAdapter _buildGroupHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建用户列表项
  Widget _buildUserListItem(BuildContext context, User user) {
    // 确定状态颜色和信息
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // 优先显示请假状态
    if (user.leaveStatus == '请假') {
      statusColor = Colors.blue;
      statusText = '已请假';
      statusIcon = Icons.event_busy;
    } else if (user.leaveStatus == '请假驳回') {
      statusColor = Colors.red;
      statusText = '请假驳回';
      statusIcon = Icons.not_interested;
    } else if (user.leaveStatus == '请假审核中') {
      statusColor = Colors.blue;
      statusText = '请假审核中';
      statusIcon = Icons.pending;
    } else {
      // 显示签到状态
      if (user.signInStatus == '已签到') {
        statusColor = Colors.green;
        statusText = '已签到';
        statusIcon = Icons.check_circle;
      } else {
        statusColor = Colors.red;
        statusText = '未签到';
        statusIcon = Icons.cancel;
      }
    }

    // 构建角色标签
    Widget? roleTag;
    if (user.role == MeetingPermission.creator) {
      roleTag = _buildRoleTag('创建者', Colors.orange);
    } else if (user.role == MeetingPermission.admin) {
      roleTag = _buildRoleTag('管理员', Colors.blue);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Icon(statusIcon, color: statusColor),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (roleTag != null) ...[const SizedBox(width: 8), roleTag],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建角色标签
  Widget _buildRoleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
