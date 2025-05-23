import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat_message.dart';
import '../services/service_providers.dart';
import 'package:flutter/foundation.dart';

/// WebSocket聊天消息流提供者
final webSocketMessagesProvider = StreamProvider.autoDispose<ChatMessage>((
  ref,
) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessageStream('').handleError((error, stackTrace) {
    debugPrint('WebSocket消息流错误: $error');
    return Stream.empty();
  });
});

/// 通过WebSocket发送消息的提供者
final webSocketSendMessageProvider = Provider<Function(String)>((ref) {
  final chatService = ref.watch(chatServiceProvider);

  return (String content) async {
    try {
      await chatService.sendTextMessage(content);
    } catch (e) {
      debugPrint('发送消息失败: $e');
      rethrow;
    }
  };
});

/// WebSocket连接状态提供者
final webSocketConnectedProvider = StreamProvider.autoDispose<bool>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.connectionStateStream;
});

/// WebSocket连接提供者
final webSocketConnectProvider =
    FutureProvider.family<void, Map<String, String>>((ref, params) async {
      final chatService = ref.watch(chatServiceProvider);
      final meetingId = params['meetingId']!;
      final userId = params['userId']!;

      try {
        await chatService.connectToChat(meetingId, userId);
      } catch (e) {
        debugPrint('WebSocket连接失败: $e');
        rethrow;
      }
    });

/// WebSocket断开连接提供者
final webSocketDisconnectProvider = Provider<Future<void> Function()>((ref) {
  final chatService = ref.watch(chatServiceProvider);

  return () async {
    try {
      await chatService.disconnect();
    } catch (e) {
      debugPrint('WebSocket断开连接失败: $e');
      rethrow;
    }
  };
});

/// 会议聊天消息列表提供者
final meetingMessagesProvider =
    AutoDisposeFutureProvider.family<List<ChatMessage>, String>((
      ref,
      meetingId,
    ) async {
      final service = ref.watch(chatServiceProvider);
      try {
        return await service.getMeetingMessages(meetingId);
      } catch (e) {
        debugPrint('获取会议消息失败: $e');
        rethrow;
      }
    });

/// 发送文字消息提供者
final sendTextMessageProvider = Provider<Function(String)>((ref) {
  final service = ref.read(chatServiceProvider);

  return (String content) async {
    try {
      await service.sendTextMessage(content);
    } catch (e) {
      debugPrint('发送文字消息失败: $e');
      rethrow;
    }
  };
});
