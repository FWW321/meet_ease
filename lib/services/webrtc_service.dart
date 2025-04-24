import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'chat_service.dart';
import '../models/chat_message.dart';
import '../constants/app_constants.dart';
import '../providers/user_providers.dart';

/// WebRTC语音服务接口
abstract class WebRTCService {
  /// 初始化WebRTC
  Future<void> initialize();

  /// 加入会议
  Future<void> joinMeeting(String meetingId, String userId, String userName);

  /// 离开会议
  Future<void> leaveMeeting();

  /// 开启/关闭麦克风
  Future<void> toggleMicrophone(bool enabled);

  /// 获取参会人员流
  Stream<List<MeetingParticipant>> getParticipantsStream();

  /// 是否已连接
  bool get isConnected;

  /// 当前是否静音
  bool get isMuted;

  /// 关闭资源
  void dispose();

  /// 设置Ref
  void setRef(Ref ref);
}

/// 会议参会人模型
class MeetingParticipant {
  final String id;
  final String name;
  final bool isSpeaking;
  final bool isMuted;
  final bool isMe;
  final bool isCreator; // 是否是会议创建者
  final bool isAdmin; // 是否是会议管理员

  MeetingParticipant({
    required this.id,
    required this.name,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isMe = false,
    this.isCreator = false,
    this.isAdmin = false,
  });

  MeetingParticipant copyWith({
    String? id,
    String? name,
    bool? isSpeaking,
    bool? isMuted,
    bool? isMe,
    bool? isCreator,
    bool? isAdmin,
  }) {
    return MeetingParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isMe: isMe ?? this.isMe,
      isCreator: isCreator ?? this.isCreator,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// 模拟WebRTC服务实现
class MockWebRTCService implements WebRTCService {
  bool _isConnected = false;
  bool _isMuted = false;
  final _participantsController =
      StreamController<List<MeetingParticipant>>.broadcast();
  List<MeetingParticipant> _participants = [];
  String? _currentMeetingId;
  String? _currentUserId;
  String? _currentUserName;
  Timer? _speakingSimulatorTimer;
  ChatService? _chatService;
  StreamSubscription<ChatMessage>? _chatSubscription;
  // Riverpod引用，用于获取当前用户信息
  Ref? _ref;

  // 设置聊天服务
  void setChatService(ChatService chatService) {
    _chatService = chatService;
  }

  // 设置Ref
  @override
  void setRef(Ref ref) {
    _ref = ref;
  }

  @override
  Future<void> initialize() async {
    // 模拟初始化延迟
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> joinMeeting(
    String meetingId,
    String userId,
    String userName,
  ) async {
    _currentMeetingId = meetingId;
    _currentUserId = userId;
    _currentUserName = userName;

    await Future.delayed(const Duration(seconds: 1));

    // 初始只有当前用户
    _participants = [
      MeetingParticipant(id: userId, name: userName, isMe: true),
    ];

    _isConnected = true;

    // 发布初始参会人员列表
    _participantsController.add(_participants);

    // 获取会议历史消息并更新参会人员列表
    if (_chatService != null && _currentMeetingId != null) {
      try {
        final messages = await _chatService!.getMeetingMessages(
          _currentMeetingId!,
        );
        _updateParticipantsFromMessages(messages);

        // 订阅新消息以实时更新参会人员
        _chatSubscription?.cancel();
        _chatSubscription = _chatService!
            .getMessageStream(_currentMeetingId!)
            .listen(_handleChatMessage);
      } catch (e) {
        debugPrint('获取会议消息失败: $e');
      }
    }

    // 模拟说话状态变化（简化版，只有当前用户会偶尔"说话"）
    _speakingSimulatorTimer = Timer.periodic(const Duration(seconds: 8), (
      timer,
    ) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // 随机控制当前用户说话状态
      final isSpeaking = DateTime.now().millisecondsSinceEpoch % 3 == 0;

      // 更新说话状态
      _updateCurrentUserSpeakingStatus(isSpeaking);
    });
  }

  // 处理聊天消息，特别是系统消息
  void _handleChatMessage(ChatMessage message) {
    if (message.isSystemMessage) {
      debugPrint('收到系统消息: ${message.content}');
      // 处理单个系统消息
      _updateParticipantsFromSystemMessage(message);
    }
  }

  // 从系统消息更新参会人员
  void _updateParticipantsFromSystemMessage(ChatMessage message) {
    if (!message.isSystemMessage) return;

    // 解析系统消息内容
    String? userId;
    String? username;
    String? action;

    // 分析系统消息格式: "userId:xxx, username:xxx, action:xxx"
    final parts = message.content.split(', ');
    for (final part in parts) {
      if (part.startsWith('userId:')) {
        userId = part.substring('userId:'.length).trim();
      } else if (part.startsWith('username:')) {
        username = part.substring('username:'.length).trim();
      } else if (part.startsWith('action:')) {
        action = part.substring('action:'.length).trim();
      }
    }

    // 如果缺少必要信息，则忽略
    if (userId == null || username == null || action == null) {
      debugPrint('系统消息格式不正确，缺少必要信息');
      return;
    }

    debugPrint('处理系统消息: userId=$userId, username=$username, action=$action');

    // 根据动作类型更新参会人员列表
    if (action == '加入会议') {
      debugPrint('用户加入会议: $username (ID: $userId)');
      // 检查用户是否已在列表中
      final existingIndex = _participants.indexWhere((p) => p.id == userId);
      if (existingIndex >= 0) {
        debugPrint('用户已在列表中，更新用户信息');
        // 用户已在列表中，但可能是之前离开的用户重新加入
        _participants[existingIndex] = _participants[existingIndex].copyWith(
          name: username,
        );
      } else {
        debugPrint('添加新用户到参会人员列表');
        // 新用户加入
        _participants.add(
          MeetingParticipant(
            id: userId,
            name: username,
            isMe: userId == _currentUserId,
          ),
        );
      }

      // 打印当前参会人员列表
      debugPrint('更新后的参会人员列表:');
      for (final p in _participants) {
        debugPrint('- ${p.name} (ID: ${p.id}, isMe: ${p.isMe})');
      }

      // 发布更新后的参会人员列表
      _participantsController.add(List.from(_participants));
    } else if (action == '离开会议') {
      debugPrint('用户离开会议: $username (ID: $userId)');
      // 不移除当前用户自己
      if (userId != _currentUserId) {
        final beforeCount = _participants.length;
        _participants.removeWhere((p) => p.id == userId);
        final afterCount = _participants.length;

        if (beforeCount != afterCount) {
          debugPrint('已从参会人员列表中移除用户');
        } else {
          debugPrint('未找到要移除的用户');
        }

        // 打印当前参会人员列表
        debugPrint('更新后的参会人员列表:');
        for (final p in _participants) {
          debugPrint('- ${p.name} (ID: ${p.id}, isMe: ${p.isMe})');
        }

        // 发布更新后的参会人员列表
        _participantsController.add(List.from(_participants));
      } else {
        debugPrint('忽略当前用户自己的离开消息');
      }
    } else if (action == '开启麦克风' || action == '关闭麦克风') {
      final isMuted = action == '关闭麦克风';
      debugPrint('用户${isMuted ? "关闭" : "开启"}麦克风: $username (ID: $userId)');

      // 更新用户麦克风状态
      _updateUserMicrophoneStatus(userId, isMuted);

      // 发布更新后的参会人员列表
      _participantsController.add(List.from(_participants));
    }
  }

  // 更新用户麦克风状态
  void _updateUserMicrophoneStatus(String userId, bool isMuted) {
    // 查找用户
    final userIndex = _participants.indexWhere((p) => p.id == userId);
    if (userIndex >= 0) {
      // 更新用户的麦克风状态
      _participants[userIndex] = _participants[userIndex].copyWith(
        isMuted: isMuted,
      );

      // 如果用户正在说话但麦克风静音，需要更新说话状态
      if (isMuted && _participants[userIndex].isSpeaking) {
        _participants[userIndex] = _participants[userIndex].copyWith(
          isSpeaking: false,
        );
      }
    }
  }

  // 从历史消息列表更新参会人员
  void _updateParticipantsFromMessages(List<ChatMessage> messages) {
    // 初始只保留当前用户
    var currentUserParticipant = _participants.firstWhere(
      (p) => p.isMe,
      orElse:
          () => MeetingParticipant(
            id: _currentUserId ?? '',
            name: _currentUserName ?? '',
            isMe: true,
          ),
    );

    _participants = [currentUserParticipant];

    // 用于跟踪用户最新状态的映射
    final userStates = <String, bool>{}; // 是否在会议中
    final userMicStates = <String, bool>{}; // 麦克风状态 (true表示静音)

    // 遍历所有系统消息，按时间顺序更新用户状态
    for (final message in messages) {
      if (!message.isSystemMessage) continue;

      // 解析系统消息
      String? userId;
      String? username;
      String? action;

      final parts = message.content.split(', ');
      for (final part in parts) {
        if (part.startsWith('userId:')) {
          userId = part.substring('userId:'.length).trim();
        } else if (part.startsWith('username:')) {
          username = part.substring('username:'.length).trim();
        } else if (part.startsWith('action:')) {
          action = part.substring('action:'.length).trim();
        }
      }

      // 如果缺少必要信息，则忽略
      if (userId == null || username == null || action == null) continue;

      // 对当前用户特殊处理
      if (userId == _currentUserId) {
        // 更新当前用户的麦克风状态
        if (action == '开启麦克风') {
          currentUserParticipant = currentUserParticipant.copyWith(
            isMuted: false,
          );
          _participants[0] = currentUserParticipant;
          _isMuted = false;
        } else if (action == '关闭麦克风') {
          currentUserParticipant = currentUserParticipant.copyWith(
            isMuted: true,
          );
          _participants[0] = currentUserParticipant;
          _isMuted = true;
        }
        continue;
      }

      // 更新用户状态映射
      if (action == '加入会议') {
        userStates[userId] = true; // 用户在会议中
      } else if (action == '离开会议') {
        userStates[userId] = false; // 用户不在会议中
      } else if (action == '开启麦克风') {
        userMicStates[userId] = false; // 麦克风开启（不静音）
      } else if (action == '关闭麦克风') {
        userMicStates[userId] = true; // 麦克风关闭（静音）
      }
    }

    // 根据最终状态构建参会人员列表
    userStates.forEach((userId, isInMeeting) {
      if (isInMeeting) {
        // 找出用户名
        String? username;
        for (final message in messages) {
          if (!message.isSystemMessage) continue;

          if (message.content.contains('userId:$userId') &&
              message.content.contains('action:加入会议')) {
            // 提取用户名
            final parts = message.content.split(', ');
            for (final part in parts) {
              if (part.startsWith('username:')) {
                username = part.substring('username:'.length).trim();
                break;
              }
            }
            if (username != null) break;
          }
        }

        if (username != null) {
          // 获取用户麦克风状态，如果没有特定状态，默认为非静音
          final isMuted = userMicStates[userId] ?? false;

          _participants.add(
            MeetingParticipant(
              id: userId,
              name: username,
              isMe: false,
              isMuted: isMuted,
            ),
          );
        }
      }
    });

    // 发布更新后的参会人员列表
    _participantsController.add(_participants);
  }

  // 更新当前用户的说话状态
  void _updateCurrentUserSpeakingStatus(bool isSpeaking) {
    if (_participants.isEmpty) return;

    // 更新当前用户的说话状态
    _participants =
        _participants.map((participant) {
          if (participant.isMe) {
            return participant.copyWith(
              isSpeaking: isSpeaking && !participant.isMuted,
            );
          }
          return participant;
        }).toList();

    // 发布更新后的参会人员列表
    _participantsController.add(_participants);
  }

  @override
  Future<void> leaveMeeting() async {
    _speakingSimulatorTimer?.cancel();
    _chatSubscription?.cancel();
    _isConnected = false;
    _participants = [];
    _currentMeetingId = null;
    _currentUserId = null;
    _currentUserName = null;

    // 发布空列表
    _participantsController.add(_participants);

    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> toggleMicrophone(bool enabled) async {
    final previousState = _isMuted;
    _isMuted = !enabled;

    // 更新当前用户的静音状态
    _participants =
        _participants.map((participant) {
          if (participant.isMe) {
            return participant.copyWith(
              isMuted: _isMuted,
              // 如果静音，停止说话状态
              isSpeaking: participant.isSpeaking && !_isMuted,
            );
          }
          return participant;
        }).toList();

    // 发布更新后的参会人员列表
    _participantsController.add(_participants);

    // 只有当状态实际发生变化时才发送系统消息
    if (previousState != _isMuted && _currentMeetingId != null) {
      // 发送麦克风状态变更的系统消息
      await _sendMicrophoneStatusSystemMessage(enabled);
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // 发送麦克风状态变更的系统消息
  Future<void> _sendMicrophoneStatusSystemMessage(bool enabled) async {
    try {
      // 确保拥有当前用户ID和用户名
      String userId = _currentUserId ?? '';
      String userName = _currentUserName ?? '';

      // 如果当前用户ID为空，从Riverpod获取
      if (userId.isEmpty && _ref != null) {
        try {
          // 尝试读取当前用户ID (这是异步操作，需要等待)
          userId = await _ref!.read(currentUserIdProvider.future);
          debugPrint('从Provider获取到用户ID: $userId');

          // 如果用户ID不为空，但用户名为空，也尝试获取用户名
          if (userId.isNotEmpty && userName.isEmpty) {
            final userService = _ref!.read(userServiceProvider);
            final user = await userService.getUserById(userId);
            userName = user.name;
            debugPrint('从Provider获取到用户名: $userName');
          }
        } catch (e) {
          debugPrint('获取用户信息出错: $e');
        }
      }

      // 如果仍然没有用户ID或用户名，则不发送消息
      if (userId.isEmpty || userName.isEmpty || _currentMeetingId == null) {
        debugPrint('无法发送麦克风状态系统消息: 用户ID、用户名或会议ID为空');
        return;
      }

      final action = enabled ? '开启麦克风' : '关闭麦克风';
      final content = 'userId:$userId, username:$userName, action:$action';

      final requestBody = jsonEncode({
        'meetingId': _currentMeetingId,
        'content': content,
      });

      debugPrint('发送麦克风状态系统消息: $content');

      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/system-message/send'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json; charset=utf-8',
            },
            body: requestBody,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      if (response.statusCode != 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        debugPrint('发送麦克风状态系统消息失败: ${response.statusCode}, $responseBody');
      } else {
        debugPrint('麦克风状态系统消息发送成功');
      }
    } catch (e) {
      debugPrint('发送麦克风状态系统消息异常: $e');
    }
  }

  @override
  Stream<List<MeetingParticipant>> getParticipantsStream() {
    return _participantsController.stream;
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isMuted => _isMuted;

  @override
  void dispose() {
    _speakingSimulatorTimer?.cancel();
    _chatSubscription?.cancel();
    _participantsController.close();
  }

  // 直接处理系统消息
  void handleSystemMessage(ChatMessage message) {
    if (!message.isSystemMessage) {
      debugPrint('非系统消息，忽略');
      return;
    }

    debugPrint('手动处理系统消息: ${message.content}');
    _updateParticipantsFromSystemMessage(message);
  }
}
