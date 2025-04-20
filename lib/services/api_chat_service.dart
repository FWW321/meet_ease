import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import 'chat_service.dart';

/// 实际的API聊天服务实现
class ApiChatService implements ChatService {
  // 消息控制器
  final _messageController = StreamController<ChatMessage>.broadcast();

  @override
  Future<List<ChatMessage>> getMeetingMessages(String meetingId) async {
    try {
      print('正在获取会议消息，meetingId: $meetingId');
      final response = await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}/chat/messages/$meetingId'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
            },
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      print('API响应: 状态码=${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        print('API响应内容: $jsonResponse');

        if (jsonResponse['code'] == 200) {
          final List<dynamic> messagesJson = jsonResponse['data'];
          print('获取到 ${messagesJson.length} 条消息');

          final messages =
              messagesJson.map((json) {
                try {
                  return ChatMessage.fromJson(json);
                } catch (e) {
                  print('解析消息错误: $e，消息JSON: $json');
                  throw Exception('解析消息错误: $e');
                }
              }).toList();

          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        } else {
          print('API返回错误: ${jsonResponse['message']}');
          throw Exception('获取消息失败: ${jsonResponse['message']}');
        }
      } else {
        print(
          'HTTP错误: ${response.statusCode}, 响应内容: ${utf8.decode(response.bodyBytes)}',
        );
        throw Exception('获取消息失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取消息异常: $e');
      throw Exception('获取消息失败: $e');
    }
  }

  @override
  Future<ChatMessage> sendTextMessage(
    String meetingId,
    String senderId,
    String senderName,
    String content, {
    String? senderAvatar,
  }) async {
    try {
      final requestBody = jsonEncode({
        'meetingId': meetingId,
        'userId': senderId,
        'senderName': senderName,
        'content': content,
        'messageType': 'CHAT',
      });

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/chat/send'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
            },
            body: requestBody,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['code'] == 200) {
          final messageJson = jsonResponse['data'];
          final message = ChatMessage.fromJson(messageJson);

          // 发送到消息流
          _messageController.add(message);
          return message;
        } else {
          throw Exception('发送消息失败: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('发送消息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('发送消息失败: $e');
    }
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
    try {
      final requestBody = jsonEncode({
        'meetingId': meetingId,
        'userId': senderId,
        'senderName': senderName,
        'content': jsonEncode({
          'voiceUrl': voiceUrl,
          'voiceDuration': voiceDuration.inSeconds,
        }),
        'messageType': 'VOICE',
      });

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/chat/send'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
            },
            body: requestBody,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['code'] == 200) {
          final messageJson = jsonResponse['data'];
          final message = ChatMessage.fromJson(messageJson);

          // 发送到消息流
          _messageController.add(message);
          return message;
        } else {
          throw Exception('发送语音消息失败: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('发送语音消息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('发送语音消息失败: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId, String userId) async {
    try {
      await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/chat/read'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'messageId': messageId, 'userId': userId}),
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));
    } catch (e) {
      // 忽略标记已读的错误，不影响用户体验
      print('标记消息为已读失败: $e');
    }
  }

  @override
  Stream<ChatMessage> getMessageStream(String meetingId) {
    // 因为服务器没有流式加载功能，我们可以设置一个定时器定期刷新消息
    // 但在实际应用中应该使用WebSocket或轮询
    Timer.periodic(const Duration(seconds: 3), (timer) {
      getMeetingMessages(meetingId)
          .then((messages) {
            // 获取最新消息，这里简单实现，实际使用中可以根据时间过滤
            if (messages.isNotEmpty) {
              final lastMessage = messages.last;
              _messageController.add(lastMessage);
            }
          })
          .catchError((e) {
            print('获取消息更新失败: $e');
          });
    });

    return _messageController.stream.where(
      (message) => message.meetingId == meetingId,
    );
  }

  @override
  void closeMessageStream() {
    _messageController.close();
  }
}
