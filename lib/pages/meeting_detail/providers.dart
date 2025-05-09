import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/meeting.dart';
import '../../models/user.dart';
import '../../providers/meeting_providers.dart';

/// 当前会议提供者 - 用于在组件之间传递当前会议ID
final currentMeetingIdProvider = StateProvider<String>((ref) => '');

/// 会议管理员提供者 - 获取会议的管理员列表
final meetingManagersProvider = FutureProvider.family<List<User>, String>((
  ref,
  meetingId,
) async {
  if (meetingId.isEmpty) return [];

  // 使用现有的会议参与者提供者，过滤出管理员角色的用户
  final participants = await ref.watch(
    meetingParticipantsProvider(meetingId).future,
  );
  return participants
      .where(
        (user) =>
            user.role == MeetingPermission.admin ||
            user.role == MeetingPermission.creator,
      )
      .toList();
});

/// 会议权限提供者 - 检查用户在会议中的权限
final meetingPermissionProvider = FutureProvider.family<
  MeetingPermission,
  Map<String, String>
>((ref, params) async {
  final userId = params['userId'];
  final meetingId = params['meetingId'];

  if (userId == null ||
      meetingId == null ||
      userId.isEmpty ||
      meetingId.isEmpty) {
    return MeetingPermission.participant;
  }

  // 使用现有会议详情提供者
  final meetingAsync = await ref.watch(meetingDetailProvider(meetingId).future);
  return meetingAsync.getUserPermission(userId);
});
