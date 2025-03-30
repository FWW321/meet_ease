import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat_message.dart';
import '../services/service_providers.dart';

/// 会议聊天消息列表提供者
final meetingMessagesProvider =
    AutoDisposeStreamProvider.family<List<ChatMessage>, String>((
      ref,
      meetingId,
    ) {
      final service = ref.watch(chatServiceProvider);

      // 获取初始消息列表
      Future<List<ChatMessage>> fetchInitialMessages() async {
        final messages = await service.getMeetingMessages(meetingId);
        return messages;
      }

      // 获取消息流
      final stream = service.getMessageStream(meetingId);

      return fetchInitialMessages().asStream().asyncExpand((initialMessages) {
        // 将初始消息列表和实时消息合并
        final messages = List<ChatMessage>.from(initialMessages);

        return stream.map((message) {
          // 添加新消息
          messages.add(message);

          // 按时间排序
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          return messages;
        });
      });
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
