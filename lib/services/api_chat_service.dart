import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/chat_message.dart';
import '../services/service_providers.dart';
import '../utils/http_utils.dart';
import 'chat_service.dart';

/// 实际的API聊天服务实现
class ApiChatService implements ChatService {
  // 消息控制器
  final _messageController = StreamController<ChatMessage>.broadcast();
  // WebSocket连接映射，按会议ID存储
  final Map<String, WebSocketChannel> _wsConnections = {};
  // 是否使用外部WebSocket
  bool _useExternalWebSocket = false;
  // 外部WebSocket消息流订阅
  StreamSubscription? _externalWebSocketSubscription;

  /// 设置使用外部WebSocket连接 (由MeetingDetailPage建立)
  void useExternalWebSocket(WidgetRef ref, String meetingId) {
    // 先清理自己管理的WebSocket连接
    if (_wsConnections.containsKey(meetingId)) {
      _wsConnections[meetingId]?.sink.close();
      _wsConnections.remove(meetingId);
    }

    // 取消之前的订阅
    _externalWebSocketSubscription?.cancel();
    _externalWebSocketSubscription = null;

    // 订阅外部WebSocket消息流
    _useExternalWebSocket = true;

    // 创建一个本地变量存储WebSocketService以直接访问消息流
    final webSocketService = ref.read(webSocketServiceProvider);

    _externalWebSocketSubscription = webSocketService.messageStream.listen(
      (message) {
        try {
          // 从WebSocket消息创建ChatMessage对象
          // 调试每一条WebSocket消息
          print('ApiChatService-收到WebSocket消息: ${jsonEncode(message)}');

          final chatMessage = ChatMessage.fromJson(message);
          // 只处理当前会议的消息
          if (chatMessage.meetingId == meetingId) {
            // 添加调试日志确认系统消息被处理
            if (chatMessage.isSystemMessage) {
              print('ApiChatService-转发系统消息: ${chatMessage.content}');
            }
            _messageController.add(chatMessage);
          }
        } catch (e) {
          print('处理外部WebSocket消息失败: $e');
        }
      },
      onError: (error) {
        print('外部WebSocket错误: $error');
      },
      onDone: () {
        print('外部WebSocket连接已关闭');
        _useExternalWebSocket = false;
      },
    );

    print('已设置使用外部WebSocket连接');
  }

  @override
  Future<void> sendSystemMessage(String meetingId, String content) async {
    try {
      print('发送系统消息: $content');

      final requestBody = jsonEncode({
        'meetingId': meetingId,
        'content': content,
      });

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/system-message/send'),
            headers: HttpUtils.createHeaders(),
            body: requestBody,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      if (response.statusCode == 200) {
        final jsonResponse = HttpUtils.decodeResponse(response);
        if (jsonResponse['code'] == 200) {
          print('系统消息发送成功');
        } else {
          print('系统消息发送失败: ${jsonResponse['message']}');
          throw Exception('发送系统消息失败: ${jsonResponse['message']}');
        }
      } else {
        final errorMessage = HttpUtils.extractErrorMessage(
          response,
          defaultMessage: '发送系统消息失败',
        );
        print(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('发送系统消息异常: $e');
      throw Exception('发送系统消息异常: $e');
    }
  }

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
    print(
      '获取会议消息流, meetingId: $meetingId, 使用外部WebSocket: $_useExternalWebSocket',
    );

    // 如果使用外部WebSocket，直接返回消息流
    if (_useExternalWebSocket) {
      print('使用外部WebSocket连接获取消息流');
      return _messageController.stream.where(
        (message) => message.meetingId == meetingId,
      );
    }

    // 否则使用内部WebSocket连接
    // 检查是否已有该会议的WebSocket连接，如果有则复用
    if (!_wsConnections.containsKey(meetingId)) {
      // 创建WebSocket连接
      final wsUrl = 'ws://${AppConstants.apiDomain}/ws/chat/$meetingId';
      print('正在连接WebSocket: $wsUrl');
      final wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听WebSocket消息并将其添加到流中
      wsChannel.stream.listen(
        (dynamic message) {
          try {
            final jsonData = jsonDecode(message);
            print('收到WebSocket消息: $jsonData');
            if (jsonData is Map<String, dynamic>) {
              final chatMessage = ChatMessage.fromJson(jsonData);

              // 添加系统消息调试日志
              if (chatMessage.isSystemMessage) {
                print('解析得到系统消息: ${chatMessage.content}');
              }

              _messageController.add(chatMessage);
            }
          } catch (e) {
            print('解析WebSocket消息失败: $e');
          }
        },
        onError: (error) {
          print('WebSocket错误: $error');
        },
        onDone: () {
          print('WebSocket连接已关闭');
          _wsConnections.remove(meetingId);
        },
      );

      // 保存WebSocket连接以便复用
      _wsConnections[meetingId] = wsChannel;
    } else {
      print('复用已有的WebSocket连接: $meetingId');
    }

    // 过滤出本会议的消息
    final filteredStream = _messageController.stream.where((message) {
      final isCurrentMeeting = message.meetingId == meetingId;
      if (isCurrentMeeting && message.isSystemMessage) {
        print('消息流过滤：传递系统消息: ${message.content}');
      }
      return isCurrentMeeting;
    });

    return filteredStream;
  }

  @override
  void closeMessageStream() {
    print('关闭聊天消息流');

    // 取消外部WebSocket订阅
    if (_externalWebSocketSubscription != null) {
      _externalWebSocketSubscription!.cancel();
      _externalWebSocketSubscription = null;
      print('已取消外部WebSocket订阅');
    }
    _useExternalWebSocket = false;

    // 关闭所有WebSocket连接
    for (final connection in _wsConnections.values) {
      connection.sink.close();
    }
    _wsConnections.clear();
    print('已关闭所有WebSocket连接');

    // 关闭消息控制器 (如果尚未关闭)
    if (!_messageController.isClosed) {
      _messageController.close();
      print('已关闭消息控制器');
    }
  }
}
