import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../constants/app_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../utils/http_utils.dart';

/// 聊天服务接口
/// 提供会议聊天相关的所有功能，包括消息收发、WebSocket连接管理等
abstract class ChatService {
  /// 获取历史聊天消息
  Future<List<ChatMessage>> getMeetingMessages(String meetingId);

  /// 发送文字消息
  Future<void> sendTextMessage(String content);

  /// 发送系统消息
  Future<void> sendSystemMessage(String meetingId, String content);

  /// 获取实时消息流
  Stream<ChatMessage> getMessageStream(String meetingId);

  /// 关闭消息流并清理资源
  void dispose();

  /// 连接到WebSocket
  Future<void> connectToChat(String meetingId, String userId);

  /// 断开WebSocket连接
  Future<void> disconnect();

  /// 获取WebSocket连接状态
  bool get isConnected;

  /// 获取WebSocket连接状态流
  Stream<bool> get connectionStateStream;

  void setOnMuteMessageReceived(Function(Map<String, dynamic>)? callback);

  /// 检查WebSocket连接状态
  void checkConnection();
}

/// 聊天服务实现类
class ChatServiceImpl implements ChatService {
  // 消息流控制器
  final _messageController = StreamController<ChatMessage>.broadcast();

  // 连接状态控制器
  final _connectionStateController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  // WebSocket相关
  WebSocketChannel? _webSocketChannel;
  String? _currentMeetingId;
  bool _isConnected = false;
  bool _isConnecting = false;

  // 添加手动关闭标志
  bool _isManuallyClosed = false;

  // 添加用户ID存储
  String? _currentUserId;

  Function(Map<String, dynamic>)? _onMuteMessageReceived;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connectToChat(String meetingId, String userId) async {
    _isManuallyClosed = false;
    // 如果已经连接且是当前会议，直接返回
    if (_isConnected && _currentMeetingId == meetingId) {
      debugPrint('WebSocket已连接到当前会议，无需重新连接');
      return;
    }

    if (_isConnecting) {
      debugPrint('WebSocket正在连接中，忽略重复连接请求');
      return;
    }

    _isConnecting = true;
    _currentMeetingId = meetingId;
    _currentUserId = userId;

    try {
      final wsUrl = _buildWebSocketUrl(meetingId, userId);
      debugPrint('正在连接WebSocket: $wsUrl');

      _webSocketChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        connectTimeout: const Duration(seconds: 10),
        headers: _getWebSocketHeaders(),
      );

      debugPrint('WebSocket连接已创建，等待连接建立...');
      _setupWebSocketConnection();
      debugPrint('WebSocket连接已建立');
    } catch (e) {
      debugPrint('WebSocket连接失败: $e');
      _handleConnectionLost();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_isManuallyClosed) return;

    try {
      // 首先设置手动关闭标志，确保不会触发重连
      _isManuallyClosed = true;

      await _webSocketChannel?.sink.close();
      _resetConnectionState();
    } catch (e) {
      debugPrint('断开WebSocket连接时发生错误: $e');
    } finally {
      _webSocketChannel = null;
    }
  }

  @override
  Future<List<ChatMessage>> getMeetingMessages(String meetingId) async {
    return _retryOperation(
      () => _fetchMessages(meetingId),
      maxRetries: 3,
      initialTimeout: const Duration(seconds: 30),
    );
  }

  @override
  Future<void> sendTextMessage(String content) async {
    if (!_isConnected) {
      throw Exception('WebSocket未连接，请先建立连接');
    }

    try {
      debugPrint('通过WebSocket发送消息: $content');
      _webSocketChannel?.sink.add(content);
    } catch (e) {
      debugPrint('发送WebSocket消息失败: $e');
      throw Exception('发送消息失败: $e');
    }
  }

  @override
  Future<void> sendSystemMessage(String meetingId, String content) async {
    final requestBody = {'meetingId': meetingId, 'content': content};

    try {
      final response = await _sendHttpRequest(
        '${AppConstants.apiBaseUrl}/system-message/send',
        requestBody,
      );

      // 检查响应状态
      if (response['code'] == 200 && response['success'] == true) {
        debugPrint('系统消息发送成功');
        return;
      } else {
        throw Exception('发送系统消息失败: ${response['message']}');
      }
    } catch (e) {
      debugPrint('发送系统消息失败: $e');
      rethrow;
    }
  }

  @override
  Stream<ChatMessage> getMessageStream(String meetingId) {
    if (!_isConnected || _currentMeetingId != meetingId) {
      debugPrint('需要先调用connectToChat建立WebSocket连接');
    }

    return _messageController.stream.where(
      (message) => message.meetingId == meetingId,
    );
  }

  @override
  void dispose() {
    _isManuallyClosed = true;
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _resetConnectionState();
    _messageController.close();
    _connectionStateController.close();
  }

  @override
  void setOnMuteMessageReceived(Function(Map<String, dynamic>)? callback) {
    _onMuteMessageReceived = callback;
  }

  @override
  void checkConnection() {
    if (_webSocketChannel == null || !_isConnected) {
      _handleConnectionLost();
    }
  }

  // 私有辅助方法

  String _buildWebSocketUrl(String meetingId, String userId) {
    final url =
        '${AppConstants.webSocketUrl}?meetingId=$meetingId&userId=$userId';
    debugPrint('构建WebSocket URL: $url');
    return url;
  }

  Map<String, String> _getWebSocketHeaders() {
    return {
      'Connection': 'Upgrade',
      'Upgrade': 'websocket',
      'Cache-Control': 'no-cache',
    };
  }

  void _setupWebSocketConnection() {
    _isConnected = true;
    _connectionStateController.add(true);
    debugPrint('WebSocket连接状态已更新: 已连接');

    _webSocketChannel!.stream.listen(
      (data) {
        debugPrint('收到WebSocket消息: $data');
        _handleWebSocketMessage(data);
      },
      onError: (error) {
        debugPrint('WebSocket错误: $error');
        _handleConnectionLost();
      },
      onDone: () {
        debugPrint('WebSocket连接已关闭');
        _handleConnectionLost();
      },
      cancelOnError: false,
    );
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data);

      // 检查是否是MUTE类型的消息
      if (jsonData['type'] == 'MUTE') {
        debugPrint('收到MUTE消息: $jsonData');
        _onMuteMessageReceived?.call(jsonData);
        return;
      }

      final message = ChatMessage.fromJson(jsonData);
      _messageController.add(message);
    } catch (e) {
      debugPrint('解析WebSocket消息失败: $e');
    }
  }

  void _handleConnectionLost() {
    if (_isManuallyClosed) {
      debugPrint('WebSocket连接是手动关闭的，不进行重连');
      return;
    }

    if (!_isConnected) return; // 避免重复处理

    _isConnected = false;
    _connectionStateController.add(false);

    // 直接尝试重新连接
    if (_currentMeetingId != null && _currentUserId != null) {
      debugPrint('WebSocket连接断开，正在尝试重新连接...');
      connectToChat(_currentMeetingId!, _currentUserId!);
    }
  }

  void _resetConnectionState() {
    _isConnected = false;
    _isConnecting = false;
    _currentMeetingId = null;
    _currentUserId = null;
    _connectionStateController.add(false);
  }

  Future<List<ChatMessage>> _fetchMessages(String meetingId) async {
    final response = await http
        .get(
          Uri.parse('${AppConstants.apiBaseUrl}/chat/messages/$meetingId'),
          headers: HttpUtils.createHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final jsonResponse = HttpUtils.decodeResponse(response);
      if (jsonResponse['code'] == 200) {
        final List<dynamic> messagesJson = jsonResponse['data'];
        final messages =
            messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }
      throw Exception('获取消息失败: ${jsonResponse['message']}');
    }
    throw Exception('获取消息失败: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _sendHttpRequest(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: HttpUtils.createHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonResponse = HttpUtils.decodeResponse(response);
      return jsonResponse;
    }
    throw Exception('请求失败: ${response.statusCode}');
  }

  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    required int maxRetries,
    required Duration initialTimeout,
  }) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final timeout = initialTimeout * (1 << retryCount);
        return await operation().timeout(timeout);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('操作失败: $e');
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    throw Exception('操作失败: 超过最大重试次数');
  }
}
