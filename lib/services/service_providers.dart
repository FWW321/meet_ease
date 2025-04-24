import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'chat_service.dart';
import 'api_chat_service.dart';
import 'meeting_process_service.dart';
import 'speech_request_service.dart';
import 'webrtc_service.dart';
import 'user_service.dart';
import 'api_user_service.dart';
import 'websocket_service.dart';

// 重新导出表情服务提供者
export 'emoji_service.dart';

// API基础URL提供者（同时用于HTTP和WebSocket）
final apiBaseUrlProvider = Provider<String>((ref) {
  return 'ws://fwwhub.fun:8080/websocket';
});

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
  // 创建WebRTC服务实例
  final webRTCService = MockWebRTCService();

  // 获取聊天服务并注入
  final chatService = ref.read(chatServiceProvider);
  webRTCService.setChatService(chatService);

  // 注入Ref对象，以便于获取当前用户信息
  webRTCService.setRef(ref);

  return webRTCService;
});

// WebSocket服务提供者
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return WebSocketService(baseUrl: baseUrl);
});
