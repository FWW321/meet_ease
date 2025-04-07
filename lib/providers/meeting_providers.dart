import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../services/meeting_service.dart';

part 'meeting_providers.g.dart';

/// 会议服务提供者 - 用于获取会议服务实例
final meetingServiceProvider = Provider<MeetingService>((ref) {
  // 目前返回模拟服务，后续可替换为真实API服务
  return MockMeetingService();
});

/// 会议列表提供者
@riverpod
Future<List<Meeting>> meetingList(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.getMeetings();
}

/// 会议详情提供者
@riverpod
Future<Meeting> meetingDetail(Ref ref, String meetingId) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.getMeetingById(meetingId);
}

/// 我的会议提供者 (已签到)
@riverpod
Future<List<Meeting>> myMeetings(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.getMyMeetings();
}

/// 搜索会议提供者
@riverpod
Future<List<Meeting>> searchMeetings(Ref ref, String query) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.searchMeetings(query);
}

/// 会议参与者提供者
@riverpod
Future<List<User>> meetingParticipants(Ref ref, String meetingId) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.getMeetingParticipants(meetingId);
}

/// 会议签到提供者
@riverpod
class MeetingSignIn extends _$MeetingSignIn {
  @override
  FutureOr<bool> build(String meetingId) async {
    // 获取当前会议的签到状态
    final meetingService = ref.watch(meetingServiceProvider);
    final meeting = await meetingService.getMeetingById(meetingId);
    return meeting.isSignedIn;
  }

  // 签到方法
  Future<void> signIn() async {
    state = const AsyncValue.loading();

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final result = await meetingService.signInMeeting(meetingId);

      // 签到成功后，更新状态并刷新其他相关提供者
      state = AsyncValue.data(result);

      // 刷新相关提供者
      ref.invalidate(meetingDetailProvider(meetingId));
      ref.invalidate(myMeetingsProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
