import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 聊天消息类型枚举
enum ChatMessageType {
  text, // 文字消息
  voice, // 语音消息
  system, // 系统消息
}

// 将服务器API返回的messageType字符串转换为枚举
ChatMessageType messageTypeFromString(String type) {
  switch (type.toUpperCase()) {
    case 'CHAT':
      return ChatMessageType.text;
    case 'VOICE':
      return ChatMessageType.voice;
    case 'SYSTEM':
      return ChatMessageType.system;
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
  });

  // 从API JSON响应创建ChatMessage对象
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      // 检查是否存在messageId，如果不存在使用id，并确保转换为字符串
      final messageId =
          json['messageId'] != null
              ? json['messageId'].toString()
              : (json['id'] != null ? json['id'].toString() : '');

      final meetingId =
          json['meetingId'] != null ? json['meetingId'].toString() : '';

      // 解析发送者信息
      final userId = json['userId']?.toString() ?? '';
      final senderName = json['senderName']?.toString() ?? '';
      final senderAvatar = json['senderAvatar']?.toString();

      // 解析消息类型
      final messageType = messageTypeFromString(
        json['messageType']?.toString() ?? 'CHAT',
      );

      // 解析消息内容
      String content = '';
      Duration? voiceDuration;

      if (messageType == ChatMessageType.voice) {
        try {
          final voiceContent = jsonDecode(json['content'] ?? '{}');
          content = voiceContent['voiceUrl']?.toString() ?? '';
          final duration = voiceContent['voiceDuration'];
          if (duration != null) {
            voiceDuration = Duration(seconds: duration is int ? duration : 0);
          }
        } catch (e) {
          debugPrint('解析语音消息内容失败: $e');
          content = json['content']?.toString() ?? '';
        }
      } else {
        content = json['content']?.toString() ?? '';
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
        debugPrint('解析时间错误: $e，将使用当前时间');
        sendTime = DateTime.now();
      }

      return ChatMessage(
        id: messageId,
        meetingId: meetingId,
        senderId: userId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        type: messageType,
        content: content,
        voiceDuration: voiceDuration,
        timestamp: sendTime,
      );
    } catch (e) {
      debugPrint('创建ChatMessage对象失败: $e');
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
    );
  }

  // 判断是否为文字消息
  bool get isTextMessage => type == ChatMessageType.text;

  // 判断是否为语音消息
  bool get isVoiceMessage => type == ChatMessageType.voice;

  // 判断是否为系统消息
  bool get isSystemMessage => type == ChatMessageType.system;
}
