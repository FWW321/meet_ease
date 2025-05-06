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
      appBar: AppBar(
        title: const Text('签到列表'),
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
            return const Center(child: Text('暂无参会人员数据'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 下拉刷新数据
              ref.invalidate(meetingParticipantsProvider(meetingId));
            },
            child: ListView.builder(
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                return _buildUserListItem(context, user);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  // 构建用户列表项
  Widget _buildUserListItem(BuildContext context, User user) {
    // 确定状态颜色
    Color statusColor;
    String statusText;
    IconData statusIcon;

    // 如果请假状态为"请假"，显示请假状态
    if (user.leaveStatus == '请假') {
      statusColor = Colors.orange;
      statusText = '已请假';
      statusIcon = Icons.event_busy;
    } else {
      // 否则显示签到状态
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

    // 添加角色标签
    Widget? roleTag;
    if (user.role == MeetingPermission.creator) {
      roleTag = _buildRoleTag('创建者', Colors.orange);
    } else if (user.role == MeetingPermission.admin) {
      roleTag = _buildRoleTag('管理员', Colors.blue);
    }

    // 构建请假状态标签（仅当leave_status为请假驳回或请假审核中时显示）
    Widget? leaveTag;
    if (user.leaveStatus == '请假驳回' || user.leaveStatus == '请假审核中') {
      Color leaveColor;
      String leaveText = user.leaveStatus!;

      if (user.leaveStatus == '请假审核中') {
        leaveColor = Colors.blue;
      } else if (user.leaveStatus == '请假驳回') {
        leaveColor = Colors.red;
      } else {
        leaveColor = Colors.grey;
      }

      leaveTag = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: leaveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: leaveColor),
        ),
        child: Text(
          leaveText,
          style: TextStyle(fontSize: 10, color: leaveColor),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Row(
          children: [
            Text(user.name),
            if (roleTag != null) ...[const SizedBox(width: 8), roleTag],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(statusText, style: TextStyle(color: statusColor)),
            if (leaveTag != null) ...[const SizedBox(height: 4), leaveTag],
          ],
        ),
      ),
    );
  }

  // 构建角色标签
  Widget _buildRoleTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
