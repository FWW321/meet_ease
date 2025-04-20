import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat_message.dart';
import '../services/service_providers.dart';

/// WebSocket聊天消息流提供者
final webSocketMessagesProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
      final webSocketService = ref.watch(webSocketServiceProvider);

      // 确保在提供者被销毁时关闭WebSocket连接
      ref.onDispose(() {
        webSocketService.disconnect();
      });

      return webSocketService.messageStream;
    });

/// 通过WebSocket发送消息的提供者
final webSocketSendMessageProvider = Provider<Function(String)>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);

  return (String message) async {
    await webSocketService.sendMessage(message);
  };
});

/// WebSocket连接状态提供者
final webSocketConnectedProvider = StateProvider<bool>((ref) => false);

/// WebSocket连接提供者
final webSocketConnectProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
      final webSocketService = ref.watch(webSocketServiceProvider);
      final meetingId = params['meetingId']!;
      final userId = params['userId']!;

      await webSocketService.connectToChat(meetingId, userId);
      ref.read(webSocketConnectedProvider.notifier).state = true;
    });

/// WebSocket断开连接提供者
final webSocketDisconnectProvider = Provider<Future<void> Function()>((ref) {
  final webSocketService = ref.watch(webSocketServiceProvider);

  return () async {
    await webSocketService.disconnect();
    ref.read(webSocketConnectedProvider.notifier).state = false;
  };
});

/// 会议聊天消息列表提供者
final meetingMessagesProvider =
    AutoDisposeFutureProvider.family<List<ChatMessage>, String>((
      ref,
      meetingId,
    ) async {
      final service = ref.watch(chatServiceProvider);
      return await service.getMeetingMessages(meetingId);
    });

/// 发送文字消息提供者
final sendTextMessageProvider =
    AutoDisposeFutureProvider.family<ChatMessage, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final service = ref.read(chatServiceProvider);
      final meetingId = params['meetingId'] as String;
      final senderId = params['senderId'] as String;
      final senderName = params['senderName'] as String;
      final content = params['content'] as String;
      final senderAvatar = params['senderAvatar'] as String?;

      return service.sendTextMessage(
        meetingId,
        senderId,
        senderName,
        content,
        senderAvatar: senderAvatar,
      );
    });

/// 发送语音消息提供者
final sendVoiceMessageProvider =
    AutoDisposeFutureProvider.family<ChatMessage, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final service = ref.read(chatServiceProvider);
      final meetingId = params['meetingId'] as String;
      final senderId = params['senderId'] as String;
      final senderName = params['senderName'] as String;
      final voiceUrl = params['voiceUrl'] as String;
      final voiceDuration = params['voiceDuration'] as Duration;
      final senderAvatar = params['senderAvatar'] as String?;

      return service.sendVoiceMessage(
        meetingId,
        senderId,
        senderName,
        voiceUrl,
        voiceDuration,
        senderAvatar: senderAvatar,
      );
    });

/// 标记消息为已读提供者
final markMessageAsReadProvider =
    AutoDisposeFutureProvider.family<void, Map<String, String>>((
      ref,
      params,
    ) async {
      final service = ref.read(chatServiceProvider);
      final messageId = params['messageId'] as String;
      final userId = params['userId'] as String;

      return service.markMessageAsRead(messageId, userId);
    });
