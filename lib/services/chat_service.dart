import 'dart:async';
import '../models/chat_message.dart';

/// 聊天服务接口
abstract class ChatService {
  /// 获取会议的聊天消息
  Future<List<ChatMessage>> getMeetingMessages(String meetingId);

  /// 发送文字消息
  Future<ChatMessage> sendTextMessage(
    String meetingId,
    String senderId,
    String senderName,
    String content, {
    String? senderAvatar,
  });

  /// 发送语音消息
  Future<ChatMessage> sendVoiceMessage(
    String meetingId,
    String senderId,
    String senderName,
    String voiceUrl,
    Duration voiceDuration, {
    String? senderAvatar,
  });

  /// 标记消息为已读
  Future<void> markMessageAsRead(String messageId, String userId);

  /// 获取实时消息流
  Stream<ChatMessage> getMessageStream(String meetingId);

  /// 关闭消息流
  void closeMessageStream();
}

/// 模拟聊天服务实现
class MockChatService implements ChatService {
  // 模拟数据 - 聊天消息
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1001',
      meetingId: '1',
      senderId: 'user1',
      senderName: '张三',
      type: ChatMessageType.text,
      content: '大家好，会议现在开始。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: true,
      readByUserIds: ['user1', 'user2', 'user3', 'user4'],
    ),
    ChatMessage(
      id: '1002',
      meetingId: '1',
      senderId: 'user2',
      senderName: '李四',
      type: ChatMessageType.text,
      content: '好的，我已准备好项目进度报告。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
      isRead: true,
      readByUserIds: ['user1', 'user2', 'user3'],
    ),
    ChatMessage(
      id: '1003',
      meetingId: '1',
      senderId: 'user3',
      senderName: '王五',
      type: ChatMessageType.voice,
      content: 'https://example.com/voice/message1.mp3',
      voiceDuration: const Duration(seconds: 8),
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: true,
      readByUserIds: ['user1', 'user2', 'user3'],
    ),
    ChatMessage(
      id: '1004',
      meetingId: '1',
      senderId: 'user1',
      senderName: '张三',
      type: ChatMessageType.text,
      content: '请李四开始介绍项目进度。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isRead: true,
      readByUserIds: ['user1', 'user2', 'user3', 'user4'],
    ),
    ChatMessage(
      id: '1005',
      meetingId: '1',
      senderId: 'user4',
      senderName: '赵六',
      type: ChatMessageType.text,
      content: '我遇到了一个问题，能帮我看看吗？',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      readByUserIds: ['user1', 'user4'],
    ),
  ];

  // 消息控制器
  final _messageController = StreamController<ChatMessage>.broadcast();

  @override
  Future<List<ChatMessage>> getMeetingMessages(String meetingId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _messages.where((message) => message.meetingId == meetingId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  @override
  Future<ChatMessage> sendTextMessage(
    String meetingId,
    String senderId,
    String senderName,
    String content, {
    String? senderAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meetingId: meetingId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: ChatMessageType.text,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
      readByUserIds: [senderId],
    );

    _messages.add(message);
    _messageController.add(message);
    return message;
  }

  @override
  Future<ChatMessage> sendVoiceMessage(
    String meetingId,
    String senderId,
    String senderName,
    String voiceUrl,
    Duration voiceDuration, {
    String? senderAvatar,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meetingId: meetingId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: ChatMessageType.voice,
      content: voiceUrl,
      voiceDuration: voiceDuration,
      timestamp: DateTime.now(),
      isRead: false,
      readByUserIds: [senderId],
    );

    _messages.add(message);
    _messageController.add(message);
    return message;
  }

  @override
  Future<void> markMessageAsRead(String messageId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }

    final message = _messages[index];
    if (message.readByUserIds.contains(userId)) {
      return;
    }

    final readByUserIds = List<String>.from(message.readByUserIds)..add(userId);
    final updatedMessage = message.copyWith(
      isRead: true,
      readByUserIds: readByUserIds,
    );

    _messages[index] = updatedMessage;
  }

  @override
  Stream<ChatMessage> getMessageStream(String meetingId) {
    return _messageController.stream.where(
      (message) => message.meetingId == meetingId,
    );
  }

  @override
  void closeMessageStream() {
    _messageController.close();
  }
}
