import 'dart:convert';

/// 聊天消息类型枚举
enum ChatMessageType {
  text, // 文字消息
  voice, // 语音消息
}

// 将服务器API返回的messageType字符串转换为枚举
ChatMessageType messageTypeFromString(String type) {
  switch (type.toUpperCase()) {
    case 'CHAT':
      return ChatMessageType.text;
    case 'VOICE':
      return ChatMessageType.voice;
    default:
      return ChatMessageType.text;
  }
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

  // 从API JSON响应创建ChatMessage对象
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // 打印原始JSON，帮助调试
      print('正在解析消息: $json');

      // 检查是否存在messageId，如果不存在使用id，并确保转换为字符串
      final messageId =
          json['messageId'] != null
              ? json['messageId'].toString()
              : (json['id'] != null ? json['id'].toString() : '');

      final meetingId =
          json['meetingId'] != null ? json['meetingId'].toString() : '';

      final userId =
          json['userId'] != null
              ? json['userId'].toString()
              : (json['senderId'] != null ? json['senderId'].toString() : '');

      final senderName = json['senderName']?.toString() ?? '';

      // 解析消息类型
      final messageTypeStr = json['messageType']?.toString() ?? 'CHAT';
      final messageType = messageTypeFromString(messageTypeStr);

      // 解析内容
      var content = '';
      if (json['content'] != null) {
        content = json['content'].toString();
      }

      Duration? voiceDuration;

      // 如果是语音消息且内容是JSON字符串，尝试解析语音时长
      if (messageType == ChatMessageType.voice && content.isNotEmpty) {
        try {
          final contentObj = jsonDecode(content);
          if (contentObj is Map && contentObj.containsKey('voiceDuration')) {
            final durationVal = contentObj['voiceDuration'];
            if (durationVal is int) {
              voiceDuration = Duration(seconds: durationVal);
            } else if (durationVal is String) {
              voiceDuration = Duration(seconds: int.tryParse(durationVal) ?? 0);
            }
          }
        } catch (e) {
          print('解析语音消息内容失败: $e');
          // 忽略解析错误，保持原始内容
        }
      }

      // 解析发送时间
      DateTime sendTime;
      try {
        if (json['sendTime'] != null) {
          if (json['sendTime'] is String) {
            sendTime = DateTime.parse(json['sendTime']);
          } else {
            // 如果是时间戳（毫秒或秒）
            final timestamp = json['sendTime'] is int ? json['sendTime'] : 0;
            if (timestamp > 0) {
              // 判断是毫秒还是秒级时间戳
              sendTime =
                  timestamp > 100000000000
                      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                      : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            } else {
              sendTime = DateTime.now();
            }
          }
        } else if (json['timestamp'] != null) {
          if (json['timestamp'] is String) {
            sendTime = DateTime.parse(json['timestamp']);
          } else {
            // 如果是时间戳（毫秒或秒）
            final timestamp = json['timestamp'] is int ? json['timestamp'] : 0;
            if (timestamp > 0) {
              // 判断是毫秒还是秒级时间戳
              sendTime =
                  timestamp > 100000000000
                      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                      : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            } else {
              sendTime = DateTime.now();
            }
          }
        } else {
          sendTime = DateTime.now();
        }
      } catch (e) {
        print('解析时间错误: $e，将使用当前时间');
        sendTime = DateTime.now();
      }

      // 处理已读状态（暂时没有后端API提供此信息）
      final readByUserIds = <String>[];

      return ChatMessage(
        id: messageId,
        meetingId: meetingId,
        senderId: userId,
        senderName: senderName,
        type: messageType,
        content: content,
        voiceDuration: voiceDuration,
        timestamp: sendTime,
        isRead: false,
        readByUserIds: readByUserIds,
      );
    } catch (e) {
      print('创建ChatMessage对象失败: $e，JSON: $json');
      rethrow; // 重新抛出异常以便上层处理
    }
  }

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
