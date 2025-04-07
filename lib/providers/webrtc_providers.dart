import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/webrtc_service.dart';
import '../services/service_providers.dart';
import 'package:flutter/foundation.dart';

/// WebRTC参会人员提供者
final webRTCParticipantsProvider =
    StreamProvider.autoDispose<List<MeetingParticipant>>((ref) {
      final webRTCService = ref.watch(webRTCServiceProvider);
      return webRTCService.getParticipantsStream();
    });

/// WebRTC连接状态提供者
final webRTCConnectionStatusProvider = Provider.autoDispose<bool>((ref) {
  final webRTCService = ref.watch(webRTCServiceProvider);
  return webRTCService.isConnected;
});

/// WebRTC麦克风状态提供者
final webRTCMicrophoneStatusProvider = StateProvider.autoDispose<bool>((ref) {
  final webRTCService = ref.watch(webRTCServiceProvider);
  return !webRTCService.isMuted;
});

/// WebRTC加入会议操作提供者
final joinMeetingProvider = FutureProvider.autoDispose
    .family<void, Map<String, String>>((ref, params) async {
      final webRTCService = ref.read(webRTCServiceProvider);
      final meetingId = params['meetingId']!;
      final userId = params['userId']!;
      final userName = params['userName']!;

      await webRTCService.initialize();
      await webRTCService.joinMeeting(meetingId, userId, userName);
    });

/// WebRTC离开会议操作提供者
final leaveMeetingProvider = FutureProvider.autoDispose<void>((ref) async {
  final webRTCService = ref.read(webRTCServiceProvider);
  await webRTCService.leaveMeeting();
});

/// WebRTC切换麦克风状态操作提供者
final toggleMicrophoneProvider = FutureProvider.autoDispose.family<void, bool>((
  ref,
  enabled,
) async {
  final webRTCService = ref.read(webRTCServiceProvider);

  // 记录当前请求的麦克风状态
  debugPrint('toggleMicrophoneProvider - 设置麦克风为: ${enabled ? "开启" : "禁用"}');

  // 调用服务切换麦克风
  await webRTCService.toggleMicrophone(enabled);

  // 更新麦克风状态提供者
  ref.read(webRTCMicrophoneStatusProvider.notifier).state = enabled;
});
