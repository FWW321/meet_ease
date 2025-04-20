import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String baseUrl;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketService({required this.baseUrl});

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // 连接到WebSocket服务器
  Future<void> connectToChat(String meetingId, String userId) async {
    try {
      final wsUrl = '$baseUrl/chat?meetingId=$meetingId&userId=$userId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听消息
      _channel!.stream.listen(
        (dynamic message) {
          try {
            final Map<String, dynamic> decodedMessage = jsonDecode(
              message as String,
            );
            _messageController.add(decodedMessage);
          } catch (e) {
            print('解析WebSocket消息失败: $e');
          }
        },
        onError: (error) {
          print('WebSocket错误: $error');
          disconnect();
        },
        onDone: () {
          print('WebSocket连接已关闭');
          disconnect();
        },
      );
    } catch (e) {
      print('WebSocket连接失败: $e');
      rethrow;
    }
  }

  // 发送消息
  Future<void> sendMessage(String message) async {
    if (_channel != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        print('发送消息失败: $e');
        rethrow;
      }
    } else {
      throw Exception('WebSocket未连接');
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  // 销毁服务
  void dispose() {
    disconnect();
    _messageController.close();
  }

  // 检查连接状态
  bool get isConnected => _channel != null;
}
