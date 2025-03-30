/// 聊天消息类型枚举
enum ChatMessageType {
  text, // 文字消息
  voice, // 语音消息
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String meetingId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final ChatMessageType type;
  final String content; // 文字内容或语音URL
  final Duration? voiceDuration; // 语音持续时间（仅对语音消息有效）
  final DateTime timestamp;
  final bool isRead;
  final List<String> readByUserIds;

  const ChatMessage({
    required this.id,
    required this.meetingId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.content,
    this.voiceDuration,
    required this.timestamp,
    this.isRead = false,
    this.readByUserIds = const [],
  });

  // 复制并修改对象的方法
  ChatMessage copyWith({
    String? id,
    String? meetingId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    ChatMessageType? type,
    String? content,
    Duration? voiceDuration,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readByUserIds,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readByUserIds: readByUserIds ?? this.readByUserIds,
    );
  }

  // 判断是否为文字消息
  bool get isTextMessage => type == ChatMessageType.text;

  // 判断是否为语音消息
  bool get isVoiceMessage => type == ChatMessageType.voice;
}
