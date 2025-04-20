import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'chat_service.dart';
import 'api_chat_service.dart';
import 'meeting_process_service.dart';
import 'speech_request_service.dart';
import 'webrtc_service.dart';
import 'user_service.dart';
import 'api_user_service.dart';

// 用户服务提供者
final userServiceProvider = Provider<UserService>((ref) {
  return ApiUserService();
});

// 会议过程服务提供者
final meetingProcessServiceProvider = Provider<MeetingProcessService>((ref) {
  return MockMeetingProcessService();
});

// 发言申请服务提供者
final speechRequestServiceProvider = Provider<SpeechRequestService>((ref) {
  return MockSpeechRequestService();
});

// 聊天服务提供者
final chatServiceProvider = Provider<ChatService>((ref) {
  return ApiChatService();
});

// WebRTC服务提供者
final webRTCServiceProvider = Provider<WebRTCService>((ref) {
  return MockWebRTCService();
});
