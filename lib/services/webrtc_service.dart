import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'chat_service.dart';
import '../models/chat_message.dart';
import 'service_providers.dart';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';

/// WebRTC连接信息类，跟踪连接状态
class ConnectionInfo {
  final String peerId;
  final String peerName;
  bool isConnected;
  bool isInitiator;
  DateTime? connectedAt; // 连接时间

  ConnectionInfo({
    required this.peerId,
    required this.peerName,
    this.isConnected = false,
    this.isInitiator = false,
    this.connectedAt,
  });

  @override
  String toString() {
    return 'ConnectionInfo(peerId: $peerId, name: $peerName, connected: $isConnected, initiator: $isInitiator)';
  }
}

/// WebRTC语音服务接口
abstract class WebRTCService {
  Future<void> initialize();
  Future<void> joinMeeting(String meetingId, String userId, String userName);
  Future<void> leaveMeeting();
  Future<void> toggleMicrophone(bool enabled);
  Stream<List<MeetingParticipant>> getParticipantsStream();
  bool get isConnected;
  bool get isMuted;
  void dispose();
  void setRef(Ref ref);
  void handleSystemMessage(ChatMessage message);
  void handleMuteMessage(Map<String, dynamic> message);
  bool isPeerConnected(String peerId); // 检查对等端连接状态
}

/// 参会者
class MeetingParticipant {
  final String id;
  final String name;
  final bool isMuted;
  final bool isMe;
  final bool isCreator;
  final bool isAdmin;

  MeetingParticipant({
    required this.id,
    required this.name,
    this.isMuted = false,
    this.isMe = false,
    this.isCreator = false,
    this.isAdmin = false,
  });

  MeetingParticipant copyWith({
    String? id,
    String? name,
    bool? isMuted,
    bool? isMe,
    bool? isCreator,
    bool? isAdmin,
  }) {
    return MeetingParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      isMuted: isMuted ?? this.isMuted,
      isMe: isMe ?? this.isMe,
      isCreator: isCreator ?? this.isCreator,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// WebRTC服务实现
class WebRTCServiceImpl implements WebRTCService {
  // 私有成员变量
  bool _isConnected = false;
  bool _isMuted = false;
  final _participantsController =
      StreamController<List<MeetingParticipant>>.broadcast();
  List<MeetingParticipant> _participants = [];
  String? _currentMeetingId;
  String? _currentUserId;
  String? _currentUserName;
  ChatService? _chatService;
  StreamSubscription<ChatMessage>? _chatSubscription;

  // WebRTC相关变量
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, ConnectionInfo> _connectionInfos = {};
  MediaStream? _localStream;

  // 存储未连接和已连接的用户列表
  final List<String> _connectedPeerIds = [];
  final List<String> _pendingPeerIds = [];

  // 连接重试计时器
  Timer? _connectionTimer;
  static const int _connectionRetryInterval = 3000; // 降低重试间隔到3秒

  // TURN服务器配置
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:38.22.95.154:3478'},
      {
        'urls': 'turn:38.22.95.154:3478',
        'username': 'user1',
        'credential': 'password1',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all',
    'rtcpMuxPolicy': 'require',
  };

  // 添加本地IP到ICE候选列表
  final List<RTCIceCandidate> _localIceCandidates = [];

  // 跟踪参会者连接状态的Map，用于UI显示，公开访问
  final Map<String, bool> peerConnectionStatus = {};

  // 添加ICE候选缓存和处理相关变量
  final Map<String, Map<String, bool>> _sentCandidates = {}; // 已发送的候选信息
  final Map<String, Map<String, bool>> _receivedCandidates = {}; // 已接收的候选信息
  final Map<String, List<Map<String, dynamic>>> _pendingCandidates =
      {}; // 待发送的候选信息
  int _candidateBatchCounter = 0; // 候选信息发送批次计数器
  Timer? _candidateBatchTimer; // 候选信息批处理定时器

  // 公有方法实现
  @override
  void setRef(Ref ref) {
    final chatService = ref.read(chatServiceProvider);
    setChatService(chatService);
  }

  @override
  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await WebRTC.initialize(
        options: {'androidAudioConfigurationLowLatency': true},
      );

      // 清理之前可能存在的连接
      await _cleanupAllConnections();

      await _initLocalStream();

      // 检查网络接口，收集本地IP优化连接
      await _checkNetworkInterfaces();
    } catch (e) {
      debugPrint('WebRTC初始化失败: $e');
      rethrow;
    }
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

    _participants = [
      MeetingParticipant(id: userId, name: userName, isMe: true, isMuted: true),
    ];

    _isConnected = true;
    _isMuted = true;

    if (_localStream == null) {
      await _initLocalStream();
    }

    _participantsController.add(_participants);

    if (_chatService != null && _currentMeetingId != null) {
      try {
        // 确保WebSocket连接已建立
        if (!_chatService!.isConnected) {
          debugPrint('加入会议时WebSocket未连接，正在连接...');
          await _chatService!.connectToChat(meetingId, userId);

          // 短暂延迟，确保WebSocket连接建立
          await Future.delayed(Duration(seconds: 1));

          // 再次检查连接状态
          if (!_chatService!.isConnected) {
            debugPrint('警告: WebSocket连接可能未成功建立');
          } else {
            debugPrint('WebSocket连接已成功建立');
          }
        }

        // 检查聊天服务连接状态
        _checkChatServiceState();

        // 获取会议参与者列表
        await _fetchMeetingParticipants(_currentMeetingId!);
        _setupMessageSubscription();

        // 启动连接定时器，定期检查并尝试连接未连接的用户
        _startConnectionTimer();

        // 启动连接监控
        _startConnectionMonitoring();
      } catch (e) {
        debugPrint('获取会议参与者失败: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> leaveMeeting() async {
    try {
      _stopConnectionTimer();

      // 发送bye信号给所有已连接的对等端
      for (final peerId in _peerConnections.keys.toList()) {
        try {
          await _sendWebRTCSignal(peerId, {
            'type': 'bye',
            'fromId': _currentUserId,
            'toId': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          debugPrint('发送bye信号给 ${_getPeerName(peerId)}');
        } catch (e) {
          debugPrint('发送bye信号失败: $e');
        }
      }

      await _cleanupAllConnections();
      _resetState();
    } catch (e) {
      debugPrint('离开会议时发生错误: $e');
    }
  }

  @override
  Future<void> toggleMicrophone(bool enabled) async {
    if (_currentMeetingId == null || _currentUserId == null) {
      throw Exception('会议ID或用户ID为空');
    }

    debugPrint('准备${enabled ? "开启" : "关闭"}麦克风...');
    debugPrint('当前麦克风状态: ${_isMuted ? "静音" : "开启"}');

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.apiBaseUrl}/voice/mute/$_currentMeetingId/$_currentUserId',
        ),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode({'muted': !enabled}),
      );

      debugPrint('服务器响应状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);
        debugPrint('服务器响应数据: $responseData');

        if (responseData['success'] == true) {
          _isMuted = !enabled;
          debugPrint('更新本地麦克风状态为: ${_isMuted ? "静音" : "开启"}');
          _updateLocalStream(enabled);
          _updateParticipantsMuteStatus();
          debugPrint('麦克风状态更新完成');
        } else {
          throw Exception(responseData['message'] ?? '更新麦克风状态失败');
        }
      } else {
        throw Exception('更新麦克风状态失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('更新麦克风状态失败: $e');
      rethrow;
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
    _stopConnectionTimer();
    _cleanupAllConnections();
    _resetState();
    if (!_participantsController.isClosed) {
      _participantsController.close();
    }
  }

  @override
  void handleSystemMessage(ChatMessage message) {
    if (message.isSystemMessage) {
      _handleChatMessage(message);
    }
  }

  @override
  void handleMuteMessage(Map<String, dynamic> message) {
    try {
      if (message['type'] != 'MUTE') {
        debugPrint('收到非MUTE类型的消息: ${message['type']}');
        return;
      }

      final userId = message['userId']?.toString();
      final bool? isMuted = message['muted'] as bool?;

      if (userId == null || isMuted == null) {
        debugPrint('MUTE消息格式错误: userId或muted字段为空');
        return;
      }

      // 更新参会者列表中对应用户的麦克风状态
      final index = _participants.indexWhere((p) => p.id == userId);
      if (index >= 0) {
        _participants[index] = _participants[index].copyWith(isMuted: isMuted);
        _participantsController.add(List.from(_participants));
        debugPrint('已更新用户 $userId 的麦克风状态为: ${isMuted ? "静音" : "开启"}');
      } else {
        debugPrint('未找到用户 $userId 在参会者列表中');
      }
    } catch (e) {
      debugPrint('处理MUTE消息时发生错误: $e');
    }
  }

  // 私有辅助方法
  void setChatService(ChatService chatService) {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _chatService = chatService;

    // 设置MUTE消息回调
    _chatService?.setOnMuteMessageReceived((message) {
      handleMuteMessage(message);
    });

    if (_currentMeetingId != null && _chatService != null) {
      _setupMessageSubscription();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.microphone].request();
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      throw Exception('麦克风权限被拒绝，WebRTC功能无法使用');
    }
  }

  Future<void> _initLocalStream() async {
    try {
      debugPrint('初始化本地媒体流...');

      if (_localStream != null) {
        debugPrint('本地媒体流已存在，先释放资源');
        await _localStream!.dispose();
        _localStream = null;
      }

      // 使用更高质量的音频设置
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          debugPrint('成功获取音频轨道，数量: ${audioTracks.length}');

          // 设置音频处理约束
          final audioTrack = audioTracks.first;
          try {
            final Map<String, dynamic> constraints = {
              'autoGainControl': true,
              'echoCancellation': true,
              'noiseSuppression': true,
              'volume': 1.0,
              'sampleRate': 48000,
              'sampleSize': 16,
              'channelCount': 1,
              'latency': 0.01,
              'audioGainControl': 1.0,
              'sensitivity': 1.0,
              'googAudioMirroring': false,
              'googAutoGainControl': true,
              'googAutoGainControl2': true,
              'googEchoCancellation': true,
              'googHighpassFilter': true,
              'googNoiseSuppression': true,
              'googTypingNoiseDetection': true,
            };
            await audioTrack.applyConstraints(constraints);
            debugPrint('已应用音频处理约束，增强音频灵敏度');
          } catch (e) {
            debugPrint('应用音频约束失败: $e');
          }

          for (final track in audioTracks) {
            track.enabled = !_isMuted;
            debugPrint(
              '音频轨道状态: enabled=${track.enabled}, muted=${track.muted}',
            );
          }
        } else {
          debugPrint('警告：未获取到音频轨道');
        }
      } else {
        debugPrint('警告：媒体流为空');
      }
    } catch (e) {
      debugPrint('初始化本地媒体流失败: $e');
      rethrow;
    }
  }

  void _setupMessageSubscription() {
    if (_chatService == null || _currentMeetingId == null) return;

    _chatSubscription?.cancel();
    _chatSubscription = _chatService!
        .getMessageStream(_currentMeetingId!)
        .listen(
          (message) {
            try {
              if (_currentMeetingId != null) {
                if (message.isSystemMessage &&
                    message.content.contains('webrtc_signal:')) {
                  // 处理旧的系统消息格式的WebRTC信令（向后兼容）
                  debugPrint('收到旧格式WebRTC信令系统消息');
                  _handleWebRTCSignal(message);
                } else if (!message.isSystemMessage) {
                  // 尝试解析普通消息中的WebRTC信令
                  try {
                    final jsonData = jsonDecode(message.content);
                    if (jsonData is Map<String, dynamic>) {
                      if (jsonData['messageType'] == 'WEBRTC_SIGNAL') {
                        debugPrint('收到WebSocket直接发送的WebRTC信令');
                        _handleWebRTCSignalFromJson(jsonData);
                      } else {
                        // 处理其他普通消息
                        _handleChatMessage(message);
                      }
                    } else {
                      // 处理其他普通消息
                      _handleChatMessage(message);
                    }
                  } catch (e) {
                    // 不是JSON格式或其他错误，当作普通消息处理
                    _handleChatMessage(message);
                  }
                } else {
                  // 处理其他系统消息
                  _handleChatMessage(message);
                }
              }
            } catch (e) {
              debugPrint('处理WebRTC消息时发生错误: $e');
            }
          },
          onError: (error) {
            debugPrint('WebRTCService-聊天消息流错误: $error');
            // 尝试重新建立消息订阅
            Future.delayed(Duration(seconds: 2), () {
              debugPrint('尝试重新建立消息订阅...');
              _setupMessageSubscription();
            });
          },
        );

    debugPrint('WebRTC消息订阅已设置，meetingId: $_currentMeetingId');
  }

  // 启动连接定时器
  void _startConnectionTimer() {
    _stopConnectionTimer();

    // 增加间隔时间，减少重试频率以提高稳定性
    _connectionTimer = Timer.periodic(
      Duration(milliseconds: _connectionRetryInterval),
      (_) {
        _processAllPendingConnections();
      },
    );

    // 短暂延迟后开始第一次处理，避免启动时连接风暴
    Future.delayed(Duration(milliseconds: 800), () {
      _processAllPendingConnections();
    });
  }

  // 停止连接定时器
  void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  // 处理所有待连接的用户
  Future<void> _processAllPendingConnections() async {
    if (_pendingPeerIds.isEmpty) return;

    // 先检查聊天服务连接状态
    _checkChatServiceState();

    debugPrint('开始处理所有待连接用户列表: $_pendingPeerIds');

    // 复制列表以避免迭代时修改列表
    final pendingList = List<String>.from(_pendingPeerIds);

    // 随机化连接顺序，避免信令风暴
    pendingList.shuffle();

    // 只处理一个待连接用户，提高单个连接成功率
    final batchSize = 1;
    final processList = pendingList.take(batchSize).toList();

    debugPrint('本次将处理 $batchSize 个连接: $processList');

    for (final peerId in processList) {
      // 跳过已连接的用户
      if (_connectedPeerIds.contains(peerId)) {
        _pendingPeerIds.remove(peerId);
        continue;
      }

      // 检查用户是否仍在参会
      if (!_participants.any((p) => p.id == peerId)) {
        debugPrint('用户 $peerId 已不在参会者列表中，从待连接列表中移除');
        _pendingPeerIds.remove(peerId);
        continue;
      }

      final peerName = _getPeerName(peerId);
      debugPrint('尝试建立与 $peerName 的WebRTC连接');

      try {
        // 检查WebSocket连接状态
        if (_chatService != null) {
          _chatService!.checkConnection();
          if (!_chatService!.isConnected) {
            debugPrint('WebSocket未连接，尝试重新连接');
            if (_currentMeetingId != null && _currentUserId != null) {
              await _chatService!.connectToChat(
                _currentMeetingId!,
                _currentUserId!,
              );
              // 给WebSocket连接一些时间
              await Future.delayed(Duration(milliseconds: 300));
            }
          }
        }

        // 如果已存在连接，先检查状态
        if (_peerConnections.containsKey(peerId)) {
          final existingPc = _peerConnections[peerId];
          final connectionState = existingPc?.connectionState;

          if (connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            debugPrint('已存在与 $peerName 的活跃连接，不再重新创建');
            _pendingPeerIds.remove(peerId);
            if (!_connectedPeerIds.contains(peerId)) {
              _connectedPeerIds.add(peerId);
            }
            continue;
          } else if (connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
            // 检查连接尝试时间
            final connectedAt = _connectionInfos[peerId]?.connectedAt;
            if (connectedAt != null &&
                DateTime.now().difference(connectedAt).inSeconds < 15) {
              debugPrint('与 $peerName 的连接正在建立中，给予更多时间');
              continue;
            }

            debugPrint('与 $peerName 的连接尝试时间过长，重新建立');
          }

          // 清理旧连接
          debugPrint('清理与 $peerName 的旧连接后重新建立');
          await _cleanupPeerConnection(peerId);

          // 添加较长延迟确保资源释放
          await Future.delayed(Duration(milliseconds: 500));
        }

        // 使用专门的处理方法，更好地控制连接流程
        await _processSpecificPendingConnection(peerId);

        // 每次连接后添加更长延迟，确保当前连接有足够时间处理
        await Future.delayed(Duration(milliseconds: 1000));
      } catch (e) {
        debugPrint('与 $peerName 建立连接失败: $e');
        // 添加较长延迟，避免立即重试导致的资源竞争
        await Future.delayed(Duration(milliseconds: 2000));
      }
    }
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    debugPrint('创建新的RTCPeerConnection...');

    // 使用预定义的ICE服务器配置
    debugPrint('ICE服务器配置: $_iceServers');

    // 简化连接约束配置
    final constraints = {
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    try {
      // 创建PeerConnection
      final pc = await createPeerConnection(_iceServers, constraints);

      return pc;
    } catch (e) {
      debugPrint('创建RTCPeerConnection失败: $e');
      rethrow;
    }
  }

  // 添加网络接口检查方法
  Future<void> _checkNetworkInterfaces() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      // 如果获取到本地IP，添加到ICE候选列表
      if (wifiIP != null) {
        debugPrint('检测到本地IPv4地址: $wifiIP，添加到ICE候选列表');
        // 移除重复检查，直接添加本地IP以提高连接成功率
        _addLocalIPsToIceCandidates(wifiIP, null);
      }
    } catch (e) {
      debugPrint('获取网络信息失败: $e');
    }
  }

  // 添加本地IP到ICE候选列表
  void _addLocalIPsToIceCandidates(String? ipv4, String? ipv6) {
    if (ipv4 != null) {
      // 修改此处，我们始终添加本地IP到ICE候选列表，不再检查是否重复
      // 因为ICE候选的多样性对建立连接很重要
      final candidate = RTCIceCandidate(
        'candidate:1 1 UDP 2122260223 $ipv4 9 typ host',
        '0',
        0,
      );
      _localIceCandidates.add(candidate);
      debugPrint('添加IPv4 ICE候选: $ipv4');
    }

    if (ipv6 != null) {
      final candidate = RTCIceCandidate(
        'candidate:1 1 UDP 2122260223 $ipv6 9 typ host',
        '0',
        0,
      );
      _localIceCandidates.add(candidate);
      debugPrint('添加IPv6 ICE候选: $ipv6');
    }
  }

  Future<void> _setupPeerConnection(
    RTCPeerConnection pc,
    String peerId,
    String peerName,
  ) async {
    debugPrint('设置与 $peerName 的PeerConnection事件处理器...');

    // 添加连接超时检测
    Timer? connectionTimeoutTimer;
    connectionTimeoutTimer = Timer(Duration(seconds: 15), () {
      if (_connectionInfos[peerId]?.isConnected != true) {
        debugPrint('与 $peerName 的连接超时，准备重试');
        _handleConnectionFailure(peerId, peerName);
        connectionTimeoutTimer = null;
      }
    });

    // 确保PeerConnection状态正常
    if (pc.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      debugPrint('警告: PeerConnection已关闭，无法设置事件处理器');
      return;
    }

    // 修改ICE候选事件处理器
    pc.onIceCandidate = (RTCIceCandidate candidate) async {
      // 检查连接状态，如果已连接则不发送ICE候选
      if (pc.connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        debugPrint('已与 $peerName 建立连接，不发送新的ICE候选');
        return;
      }

      if (candidate.candidate?.isNotEmpty ?? false) {
        debugPrint('收到本地ICE候选 [$peerId]: ${candidate.candidate}');

        // 将候选信息添加到待发送列表
        if (!_pendingCandidates.containsKey(peerId)) {
          _pendingCandidates[peerId] = [];
        }

        _pendingCandidates[peerId]!.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });

        // 安排批处理
        _scheduleCandidateBatch();
      }
    };

    // 2. 监听ICE收集状态
    pc.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE收集状态 [$peerName]: $state');
      _logConnectionState(peerId, peerName, iceGatheringState: state);
    };

    // 3. 监听连接状态变化
    pc.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('与$peerName的连接状态变化: $state');
      _logConnectionState(peerId, peerName, connectionState: state);

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          debugPrint('与$peerName的WebRTC连接已完全建立');
          _connectionInfos[peerId]?.isConnected = true;
          _connectionInfos[peerId]?.connectedAt = DateTime.now();
          _pendingPeerIds.remove(peerId);
          if (!_connectedPeerIds.contains(peerId)) {
            _connectedPeerIds.add(peerId);
          }
          connectionTimeoutTimer?.cancel();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          debugPrint('与$peerName的WebRTC连接失败，准备重试');
          connectionTimeoutTimer?.cancel();
          _handleConnectionFailure(peerId, peerName);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          debugPrint('与$peerName的WebRTC连接已关闭');
          connectionTimeoutTimer?.cancel();
          _handleConnectionFailure(peerId, peerName);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          debugPrint('与$peerName的WebRTC连接已断开');
          break;
        default:
          debugPrint('与$peerName的WebRTC连接状态: $state');
      }
    };

    // 4. 监听ICE连接状态
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('与$peerName的ICE连接状态: $state');
      _logConnectionState(peerId, peerName, iceConnectionState: state);

      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
          debugPrint('与$peerName的ICE连接已建立');
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          debugPrint('与$peerName的ICE连接失败，准备重试');
          _handleConnectionFailure(peerId, peerName);
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          debugPrint('与$peerName的ICE连接已断开');
          _handleConnectionFailure(peerId, peerName);
          break;
        default:
          break;
      }
    };

    // 5. 监听信令状态
    pc.onSignalingState = (RTCSignalingState state) {
      debugPrint('与$peerName的信令状态: $state');
      _logConnectionState(peerId, peerName, signalingState: state);
    };

    // 6. 监听媒体轨道 - 收到对方的媒体流时
    pc.onTrack = (RTCTrackEvent event) {
      debugPrint('收到来自$peerName的媒体轨道: ${event.track.kind}');
      if (event.streams.isNotEmpty && event.track.kind == 'audio') {
        // 处理接收到的音频轨道
        event.track.enabled = true;
        debugPrint('已启用来自$peerName的音频轨道');
      }
    };
  }

  // 新增方法：统一记录连接状态并更新UI状态
  void _logConnectionState(
    String peerId,
    String peerName, {
    RTCPeerConnectionState? connectionState,
    RTCIceConnectionState? iceConnectionState,
    RTCIceGatheringState? iceGatheringState,
    RTCSignalingState? signalingState,
  }) {
    final connectionInfo = _connectionInfos[peerId];
    final isInitiator = connectionInfo?.isInitiator ?? false;
    final role = isInitiator ? "发起方" : "接收方";
    final isConnected = connectionInfo?.isConnected ?? false;

    String status = "未知";
    bool isConnectionActive = false;

    if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      status = "已连接";
      isConnectionActive = true;
    } else if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
      status = "连接中";
      isConnectionActive = false;
    } else if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      status = "连接失败";
      isConnectionActive = false;
    } else if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
      status = "已断开";
      isConnectionActive = false;
    } else if (connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      status = "已关闭";
      isConnectionActive = false;
    }

    // 更新连接状态Map，用于UI显示
    if (connectionState != null) {
      peerConnectionStatus[peerId] = isConnectionActive;

      // 更新UI状态后刷新参会者列表
      if (!_participantsController.isClosed) {
        _participantsController.add(List.from(_participants));
      }
    }

    // 构建完整状态信息
    final statusInfo = {
      "peer": peerName,
      "peerId": peerId,
      "角色": role,
      "连接状态": connectionState?.toString() ?? "未变化",
      "ICE连接状态": iceConnectionState?.toString() ?? "未变化",
      "ICE收集状态": iceGatheringState?.toString() ?? "未变化",
      "信令状态": signalingState?.toString() ?? "未变化",
      "已连接": isConnected,
      "状态": status,
      "连接时间": connectionInfo?.connectedAt?.toString() ?? "未连接",
    };

    debugPrint('WebRTC连接状态: ${jsonEncode(statusInfo)}');
  }

  // 添加获取对等端连接状态的方法，供UI使用
  bool isPeerConnected(String peerId) {
    return peerConnectionStatus[peerId] ?? false;
  }

  void _handleConnectionFailure(String peerId, String peerName) async {
    debugPrint('处理与$peerName的连接失败...');

    // 记录失败状态，以便分析
    final connectionInfo = _connectionInfos[peerId];
    if (connectionInfo != null) {
      debugPrint('连接信息: ${connectionInfo.toString()}');
    }

    // 检查该对等端是否仍在参与者列表中
    final isParticipantActive = _participants.any((p) => p.id == peerId);
    if (!isParticipantActive) {
      debugPrint('$peerName 已不在参与者列表中，不再尝试重连');
      _pendingPeerIds.remove(peerId);
      _connectedPeerIds.remove(peerId);
      await _cleanupPeerConnection(peerId);
      return;
    }

    // 清理现有连接前，先发送一个bye信号通知对方
    if (_peerConnections.containsKey(peerId)) {
      try {
        await _sendWebRTCSignal(peerId, {
          'type': 'bye',
          'fromId': _currentUserId,
          'toId': peerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'meetingId': _currentMeetingId,
          'userId': _currentUserId,
        });
        debugPrint('已发送bye信号通知对方连接将被重置');
      } catch (e) {
        debugPrint('发送bye信号失败: $e');
      }
    }

    // 添加延迟，避免频繁清理重连
    await Future.delayed(Duration(milliseconds: 500));

    // 清理现有连接
    await _cleanupPeerConnection(peerId);

    // 延迟更长时间后重试，避免立即重连可能导致的问题
    await Future.delayed(Duration(milliseconds: 1000));

    // 如果用户仍在参会者列表中，并且根据ID规则应该由我方发起连接，则立即重新开始连接过程
    if (_participants.any((p) => p.id == peerId) &&
        _currentUserId != null &&
        _currentUserId!.compareTo(peerId) < 0) {
      debugPrint('连接失败后立即重试: 根据ID规则，我方需要主动重新连接 $peerName');

      if (!_pendingPeerIds.contains(peerId)) {
        _pendingPeerIds.add(peerId);

        // 立即开始连接过程，不等待定时器
        debugPrint('立即开始与 $peerName 的重新连接过程');
        Future.delayed(Duration(milliseconds: 500), () {
          if (_participants.any((p) => p.id == peerId) &&
              _pendingPeerIds.contains(peerId)) {
            _processSpecificPendingConnection(peerId);
          }
        });
      }
    } else {
      debugPrint('根据ID规则，等待$peerName向我方发起连接');
    }
  }

  Future<void> _cleanupPeerConnection(String peerId) async {
    final peerName = _getPeerName(peerId);
    debugPrint('清理与 $peerName 的连接');

    final pc = _peerConnections[peerId];
    if (pc != null) {
      try {
        // 标记状态为断开，避免重复清理
        _connectionInfos[peerId]?.isConnected = false;

        // 发送bye信号给对方，通知连接将要关闭
        try {
          await _sendWebRTCSignal(peerId, {
            'type': 'bye',
            'fromId': _currentUserId,
            'toId': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'meetingId': _currentMeetingId,
            'userId': _currentUserId,
          });
          debugPrint('成功发送bye信号给 $peerName');
        } catch (e) {
          debugPrint('发送bye信号失败: $e');
        }

        // 添加短暂延迟，等待bye信号发送
        await Future.delayed(Duration(milliseconds: 100));

        // 关闭前尝试移除所有轨道
        try {
          final senders = await pc.getSenders();
          for (final sender in senders) {
            try {
              await pc.removeTrack(sender);
            } catch (e) {
              debugPrint('移除轨道时发生错误: $e');
            }
          }
        } catch (e) {
          debugPrint('获取senders失败: $e');
        }

        // 添加短暂延迟，确保资源释放
        await Future.delayed(Duration(milliseconds: 200));

        // 停止所有可能的流和轨道
        try {
          // 先停止所有接收者
          final receivers = await pc.getReceivers();
          for (final receiver in receivers) {
            try {
              final track = receiver.track;
              if (track != null) {
                track.stop();
              }
            } catch (e) {
              debugPrint('停止接收轨道失败: $e');
            }
          }

          // 再停止所有发送者关联的轨道
          final senders = await pc.getSenders();
          for (final sender in senders) {
            try {
              final track = sender.track;
              if (track != null) {
                track.stop();
              }
            } catch (e) {
              debugPrint('停止发送轨道失败: $e');
            }
          }
        } catch (e) {
          debugPrint('停止轨道失败: $e');
        }

        // 添加短暂延迟
        await Future.delayed(Duration(milliseconds: 100));

        // 清理ICE候选
        try {
          // 尝试通过setConfiguration清理ICE状态
          await pc.setConfiguration({
            'iceServers': [],
            'iceTransportPolicy': 'relay',
          });
        } catch (e) {
          debugPrint('清理ICE配置失败: $e');
        }

        // 添加短暂延迟
        await Future.delayed(Duration(milliseconds: 100));

        try {
          // 安全关闭连接
          await pc.close();
          debugPrint('成功关闭与 $peerName 的连接');
        } catch (e) {
          debugPrint('关闭PeerConnection时发生错误: $e');
        }
      } catch (e) {
        debugPrint('清理PeerConnection时发生错误: $e');
      }
    }

    // 确保一定移除映射关系
    _peerConnections.remove(peerId);
    _connectionInfos.remove(peerId);
    _connectedPeerIds.remove(peerId);

    // 清理候选缓存
    _sentCandidates.remove(peerId);
    _receivedCandidates.remove(peerId);
    _pendingCandidates.remove(peerId);
  }

  Future<void> _cleanupAllConnections() async {
    try {
      for (final peerId in _peerConnections.keys.toList()) {
        await _cleanupPeerConnection(peerId);
      }
      _connectedPeerIds.clear();
      _pendingPeerIds.clear();
      _sentCandidates.clear();
      _receivedCandidates.clear();
      _pendingCandidates.clear();
      _candidateBatchTimer?.cancel();
      _candidateBatchTimer = null;
      _localStream?.getAudioTracks().forEach((track) => track.enabled = false);
    } catch (e) {
      debugPrint('清理连接时发生错误: $e');
    }
  }

  void _resetState() {
    try {
      _chatSubscription?.cancel();
      _chatSubscription = null;
      _isConnected = false;
      _participants = [];
      _currentMeetingId = null;
      _currentUserId = null;
      _currentUserName = null;
      _connectedPeerIds.clear();
      _pendingPeerIds.clear();
      if (!_participantsController.isClosed) {
        _participantsController.add(_participants);
      }
    } catch (e) {
      debugPrint('重置状态时发生错误: $e');
    }
  }

  void _updateLocalStream(bool enabled) {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      debugPrint('更新本地音频轨道状态: enabled=$enabled');
      for (final track in audioTracks) {
        track.enabled = enabled;
        debugPrint('音频轨道状态已更新: enabled=${track.enabled}, muted=${track.muted}');
      }
    } else {
      debugPrint('警告：尝试更新不存在的本地媒体流');
    }
  }

  void _updateParticipantsMuteStatus() {
    _participants =
        _participants.map((participant) {
          if (participant.isMe) {
            return participant.copyWith(isMuted: _isMuted);
          }
          return participant;
        }).toList();
    _participantsController.add(_participants);
  }

  // 检查是否可以发送WebRTC信令
  bool get _canSendWebRTCSignal {
    return _chatService != null &&
        _chatService!.isConnected &&
        _currentUserId != null;
  }

  Future<void> _sendWebRTCSignal(
    String peerId,
    Map<String, dynamic> signal,
  ) async {
    if (!_canSendWebRTCSignal) return;

    // 检查是否已经与该对等端建立了连接
    final isConnected =
        _peerConnections[peerId]?.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected;

    if (isConnected && signal['type'] != 'bye') {
      debugPrint('已与 ${_getPeerName(peerId)} 建立连接，不发送 ${signal['type']} 信令');
      return;
    }

    try {
      // 设置一个短暂的延迟，避免信令拥堵
      if (signal['type'] == 'candidate') {
        await Future.delayed(Duration(milliseconds: 5));
      } else if (signal['type'] == 'offer') {
        // 对offer信令特殊处理，确保WebRTC信令的有序传递
        debugPrint('正在发送关键offer信令，确保对方能正确接收...');
        // 使用更长的延迟，让WebSocket连接有时间准备好
        await Future.delayed(Duration(milliseconds: 200));
      }

      // 添加时间戳到所有信令消息，确保唯一性和有序性
      if (signal['timestamp'] == null) {
        signal['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      // 将消息类型设置为WebRTC信令
      signal['messageType'] = 'WEBRTC_SIGNAL';
      signal['meetingId'] = _currentMeetingId;
      signal['userId'] = _currentUserId;

      // 直接通过WebSocket发送信令
      final signalStr = jsonEncode(signal);

      // 使用WebSocket直接发送，不再通过系统消息接口
      await _chatService!.sendTextMessage(signalStr);

      // 添加额外的调试信息
      debugPrint(
        'WebRTC信令已通过WebSocket直接发送: type=${signal['type']}, to=$peerId, timestamp=${signal['timestamp']}',
      );
    } catch (e) {
      debugPrint('发送WebRTC信令失败: $e');
      rethrow;
    }
  }

  Future<void> _handleWebRTCSignal(ChatMessage message) async {
    try {
      final signalStr = message.content.substring('webrtc_signal:'.length);
      final signal = jsonDecode(signalStr);
      _handleWebRTCSignalFromJson(signal);
    } catch (e) {
      debugPrint('处理系统消息WebRTC信令失败: $e');
    }
  }

  Future<void> _handleWebRTCSignalFromJson(Map<String, dynamic> signal) async {
    try {
      final String type = signal['type'];
      final String fromId = signal['fromId'];
      final String meetingId = signal['meetingId'] ?? '';

      // 验证会议ID，确保只处理当前会议的信令
      if (meetingId != _currentMeetingId) {
        debugPrint('忽略非当前会议的WebRTC信令');
        return;
      }

      final String toId = signal['toId'] ?? '';
      if (toId != _currentUserId) return;

      // 检查是否已经与该对等端建立了连接
      final isConnected =
          _peerConnections[fromId]?.connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected;

      if (isConnected && type != 'bye') {
        debugPrint('已与 ${_getPeerName(fromId)} 建立连接，忽略 $type 信令');
        return;
      }

      debugPrint(
        '收到WebRTC信令: type=$type, fromId=$fromId, timestamp=${signal['timestamp'] ?? 'unknown'}',
      );

      switch (type) {
        case 'offer':
          await _handleOffer(fromId, signal);
          break;
        case 'answer':
          await _handleAnswer(fromId, signal);
          break;
        case 'candidate':
          await _handleIceCandidate(fromId, signal);
          break;
        case 'bye':
          await _handleBye(fromId);
          break;
      }
    } catch (e) {
      debugPrint('处理WebRTC信令失败: $e');
    }
  }

  Future<void> _handleOffer(String fromId, Map<String, dynamic> signal) async {
    debugPrint('收到来自 $fromId 的offer，准备处理...');

    // 从待连接列表中移除，因为对方主动发起了连接
    _pendingPeerIds.remove(fromId);

    // 检查是否已存在连接
    if (_peerConnections.containsKey(fromId)) {
      final pc = _peerConnections[fromId];
      final connectionState = pc?.connectionState;

      // 如果连接状态是connected或connecting，不要重新创建
      if (connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
          connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        debugPrint('已与$fromId建立有效连接，不重新创建');
        return;
      }

      // 清理旧连接
      debugPrint('与 $fromId 的连接状态无效，关闭旧连接并重新创建');
      await _cleanupPeerConnection(fromId);
      await Future.delayed(Duration(milliseconds: 200));
    }

    try {
      final peerName = _getPeerName(fromId);

      // ====== 接收方标准流程 ======
      debugPrint('【接收方流程】- 开始处理来自 $peerName 的Offer');

      // 步骤1: 创建新的PeerConnection
      debugPrint('【接收方流程】- 步骤1: 创建RTCPeerConnection');
      final pc = await _createPeerConnection();
      _peerConnections[fromId] = pc;

      // 步骤2: 设置事件处理器
      debugPrint('【接收方流程】- 步骤2: 设置事件监听器');
      _connectionInfos[fromId] = ConnectionInfo(
        peerId: fromId,
        peerName: peerName,
        isConnected: false,
        isInitiator: false,
      );
      await _setupPeerConnection(pc, fromId, peerName);

      // 步骤3: 设置远程描述(Offer)
      debugPrint('【接收方流程】- 步骤3: 设置远程描述(Offer)');
      final remoteDesc = RTCSessionDescription(signal['sdp'], 'offer');
      await pc.setRemoteDescription(remoteDesc);
      debugPrint('【接收方流程】- 远程描述设置成功');

      // 步骤4: 添加本地媒体流
      debugPrint('【接收方流程】- 步骤4: 添加本地媒体流');
      if (_localStream == null) {
        await _initLocalStream();
      }

      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          // 清理旧轨道（如果有）
          final senders = await pc.getSenders();
          for (final sender in senders) {
            await pc.removeTrack(sender);
          }

          // 添加音频轨道
          await pc.addTrack(audioTracks.first, _localStream!);
          audioTracks.first.enabled = !_isMuted;
          debugPrint('【接收方流程】- 已添加本地音频轨道，静音状态: $_isMuted');
        } else {
          debugPrint('【接收方流程】- 警告: 本地媒体流中没有音频轨道');
        }
      } else {
        debugPrint('【接收方流程】- 警告: 无法获取本地媒体流');
      }

      // 步骤5: 创建Answer
      debugPrint('【接收方流程】- 步骤5: 创建SDP Answer');
      final answerOptions = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      };
      final answer = await pc.createAnswer(answerOptions);

      // 步骤6: 设置本地描述(Answer)
      debugPrint('【接收方流程】- 步骤6: 设置本地描述(Answer)');
      await pc.setLocalDescription(answer);
      debugPrint('【接收方流程】- 本地描述设置成功');

      // 步骤7: 发送Answer给对方
      debugPrint('【接收方流程】- 步骤7: 通过信令发送Answer');
      await _sendWebRTCSignal(fromId, {
        'type': 'answer',
        'sdp': answer.sdp,
        'fromId': _currentUserId,
        'toId': fromId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'meetingId': _currentMeetingId,
        'userId': _currentUserId,
      });
      debugPrint('【接收方流程】- Answer已成功发送给 $peerName');

      // 更新连接信息
      _connectionInfos[fromId]?.connectedAt = DateTime.now();
      _pendingPeerIds.remove(fromId);

      // 等待ICE候选收集和交换
      debugPrint('【接收方流程】- 等待ICE候选收集和交换');

      // 标记为已连接的对等端
      if (!_connectedPeerIds.contains(fromId)) {
        _connectedPeerIds.add(fromId);
        debugPrint('【接收方流程】- 已将 $peerName 加入已连接列表');
      }

      debugPrint('【接收方流程】- 与 $peerName 的应答流程完成');
    } catch (e) {
      debugPrint('【接收方流程】- 处理offer失败: $e');
      await _cleanupPeerConnection(fromId);
      rethrow;
    }
  }

  String _getPeerName(String peerId) {
    final participant = _participants.firstWhere(
      (p) => p.id == peerId,
      orElse: () => MeetingParticipant(id: peerId, name: '未知用户'),
    );
    return participant.name;
  }

  Future<void> _handleAnswer(String fromId, Map<String, dynamic> signal) async {
    final peerName = _getPeerName(fromId);
    debugPrint('【发起方流程】- 收到来自 $peerName 的Answer...');

    final pc = _peerConnections[fromId];
    if (pc == null) {
      debugPrint('【发起方流程】- 未找到与 $peerName 的PeerConnection，忽略Answer');
      return;
    }

    try {
      // 检查连接状态
      if (pc.connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        debugPrint('【发起方流程】- PeerConnection已关闭，无法设置远程描述');
        return;
      }

      // 步骤1: 设置远程描述(Answer)
      debugPrint('【发起方流程】- 步骤1: 设置远程描述(Answer)');
      final remoteDesc = RTCSessionDescription(signal['sdp'], 'answer');
      await pc.setRemoteDescription(remoteDesc);

      debugPrint('【发起方流程】- 远程描述设置成功，连接状态: ${pc.connectionState}');
      debugPrint('【发起方流程】- 等待ICE连接建立...');

      // 更新连接信息
      _connectionInfos[fromId]?.isConnected = true;
      _connectionInfos[fromId]?.connectedAt = DateTime.now();
      _pendingPeerIds.remove(fromId);

      // 添加到已连接列表
      if (!_connectedPeerIds.contains(fromId)) {
        _connectedPeerIds.add(fromId);
      }

      // 连接建立完成后输出一次完整的连接状态
      _logConnectionState(
        fromId,
        peerName,
        connectionState: pc.connectionState,
        iceConnectionState: pc.iceConnectionState,
        signalingState: pc.signalingState,
      );

      debugPrint('【发起方流程】- 与 $peerName 的连接建立完成，等待ICE候选交换完成后建立媒体传输');
    } catch (e) {
      debugPrint('【发起方流程】- 处理Answer失败: $e');
    }
  }

  Future<void> _handleIceCandidate(
    String fromId,
    Map<String, dynamic> signal,
  ) async {
    final peerName = _getPeerName(fromId);
    debugPrint('收到来自 $peerName 的ICE候选...');

    RTCPeerConnection? pc = _peerConnections[fromId];
    if (pc == null) {
      debugPrint('未找到与 $peerName 的PeerConnection，忽略ICE候选');
      return;
    }

    try {
      final candidateStr = signal['candidate'] as String?;
      if (candidateStr == null || candidateStr.isEmpty) {
        debugPrint('收到空ICE候选，忽略');
        return;
      }

      // 检查PeerConnection状态
      if (pc.connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        debugPrint('PeerConnection已关闭，无法添加ICE候选');
        return;
      }

      // 获取候选类型和批次
      final String type =
          signal['candidateType'] ?? _getCandidateType(candidateStr);
      final int batchNumber = signal['batchNumber'] ?? 0;
      final String candidateKey = '${type}_$batchNumber';

      // 初始化接收缓存
      if (!_receivedCandidates.containsKey(fromId)) {
        _receivedCandidates[fromId] = {};
      }

      // 检查是否已处理过该候选
      if (_receivedCandidates[fromId]![candidateKey] == true) {
        debugPrint('已处理过 $type 类型的ICE候选 (批次: $batchNumber)，忽略');
        return;
      }

      // 创建并添加ICE候选
      final candidate = RTCIceCandidate(
        candidateStr,
        signal['sdpMid'],
        signal['sdpMLineIndex'],
      );

      debugPrint('添加 $type 类型的ICE候选 (批次: $batchNumber)...');
      await pc.addCandidate(candidate);

      // 标记为已处理
      _receivedCandidates[fromId]![candidateKey] = true;

      debugPrint(
        'ICE候选添加成功，当前连接状态: ${pc.connectionState}，ICE连接状态: ${pc.iceConnectionState}',
      );

      // 如果连接成功，标记状态
      if (pc.iceConnectionState ==
          RTCIceConnectionState.RTCIceConnectionStateConnected) {
        debugPrint('检测到ICE连接已建立，更新连接状态');
        _connectionInfos[fromId]?.isConnected = true;
        if (!_connectedPeerIds.contains(fromId)) {
          _connectedPeerIds.add(fromId);
        }
        _pendingPeerIds.remove(fromId);
      }
    } catch (e) {
      debugPrint('处理ICE候选失败: $e');
    }
  }

  void _handleChatMessage(ChatMessage message) {
    if (!message.isSystemMessage) return;

    final parts = message.content.split(', ');
    String? userId;
    String? username;
    String? action;

    for (final part in parts) {
      if (part.startsWith('userId:')) {
        userId = part.substring('userId:'.length).trim();
      } else if (part.startsWith('username:')) {
        username = part.substring('username:'.length).trim();
      } else if (part.startsWith('action:')) {
        action = part.substring('action:'.length).trim();
      }
    }

    if (userId == null || username == null || action == null) return;

    _processSystemAction(userId, username, action);
    _participantsController.add(List.from(_participants));
  }

  void _processSystemAction(String userId, String username, String action) {
    switch (action) {
      case '加入会议':
        _handleJoinAction(userId, username);
        break;
      case '离开会议':
        _handleLeaveAction(userId);
        break;
      case '开启麦克风':
      case '关闭麦克风':
        _handleMicrophoneAction(userId, action == '关闭麦克风');
        break;
    }
  }

  void _handleJoinAction(String userId, String username) {
    final existingIndex = _participants.indexWhere((p) => p.id == userId);
    if (existingIndex >= 0) {
      _participants[existingIndex] = _participants[existingIndex].copyWith(
        name: username,
      );
    } else {
      _participants.add(
        MeetingParticipant(
          id: userId,
          name: username,
          isMe: userId == _currentUserId,
          isMuted: true,
        ),
      );

      // 连接建立方向：先加入的用户主动向新用户发起连接
      if (userId != _currentUserId) {
        // 如果新用户ID比当前用户ID大，则当前用户主动发起连接
        // 这确保了连接的单向性，避免双方同时发起连接
        if (_currentUserId != null && _currentUserId!.compareTo(userId) < 0) {
          if (!_connectedPeerIds.contains(userId) &&
              !_pendingPeerIds.contains(userId)) {
            _pendingPeerIds.add(userId);
            debugPrint('我的ID较小，主动向新用户发起连接: $userId');
          }
        } else {
          // 如果当前用户ID较大，则等待对方发起连接
          debugPrint('我的ID较大，等待用户 $userId 向我发起连接');
        }
      }
    }
  }

  void _handleLeaveAction(String userId) {
    if (userId != _currentUserId) {
      _participants.removeWhere((p) => p.id == userId);
      _cleanupPeerConnection(userId);
      _pendingPeerIds.remove(userId);
      _connectedPeerIds.remove(userId);
    }
  }

  void _handleMicrophoneAction(String userId, bool isMuted) {
    final index = _participants.indexWhere((p) => p.id == userId);
    if (index >= 0) {
      _participants[index] = _participants[index].copyWith(isMuted: isMuted);
    }
  }

  // 获取会议参与者
  Future<void> _fetchMeetingParticipants(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.apiBaseUrl}/monitor/getParticipantsList/$meetingId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          // 保留当前用户信息
          var currentUserParticipant = _participants.firstWhere(
            (p) => p.isMe,
            orElse:
                () => MeetingParticipant(
                  id: _currentUserId ?? '',
                  name: _currentUserName ?? '',
                  isMe: true,
                  isMuted: _isMuted,
                ),
          );

          _participants = [currentUserParticipant];

          // 保存当前连接状态
          final currentConnectedPeers = Set<String>.from(_connectedPeerIds);

          _pendingPeerIds.clear(); // 清空待连接列表

          // 解析API返回的参与者列表
          final List<dynamic> participantsList = data['data'];
          for (var item in participantsList) {
            final String userId = item['userId'].toString();

            // 跳过当前用户，因为已经添加了
            if (userId == _currentUserId) continue;

            final String username = item['username'] ?? '未知用户';
            final bool isMuted = item['muted'] ?? false;
            final bool isCreator = item['role'] == 'HOST';
            final bool isAdmin =
                item['role'] == 'ADMIN' || item['role'] == 'HOST';

            _participants.add(
              MeetingParticipant(
                id: userId,
                name: username,
                isMe: false,
                isMuted: isMuted,
                isCreator: isCreator,
                isAdmin: isAdmin,
              ),
            );

            // 如果已经连接，保持连接状态
            if (currentConnectedPeers.contains(userId)) {
              if (!_connectedPeerIds.contains(userId)) {
                _connectedPeerIds.add(userId);
              }
            }
            // 否则根据ID大小决定是否主动发起连接
            else if (!_connectedPeerIds.contains(userId)) {
              if (_currentUserId != null &&
                  _currentUserId!.compareTo(userId) < 0) {
                if (!_pendingPeerIds.contains(userId)) {
                  _pendingPeerIds.add(userId);
                  debugPrint('初始化阶段: 我的ID较小，将向 $userId 发起连接');
                }
              } else {
                debugPrint('初始化阶段: 我的ID较大，等待 $userId 向我发起连接');
              }
            }
          }

          debugPrint('初始化待连接列表: $_pendingPeerIds');
          _participantsController.add(List.from(_participants));
        }
      } else {
        throw Exception('获取会议参与者失败: HTTP状态码 ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取会议参与者异常: $e');
      rethrow;
    }
  }

  // 启动连接监控
  void _startConnectionMonitoring() {
    // 不再使用定时器进行循环检测
    debugPrint('启动WebRTC连接状态监控（基于事件监听）...');

    // 执行一次初始化检查，确保所有参与者都有连接
    Future.delayed(Duration(seconds: 5), () {
      _ensureAllParticipantsConnected();
    });
  }

  // 确保所有参与者都有连接
  void _ensureAllParticipantsConnected() {
    debugPrint('检查确保所有参与者都有连接...');

    // 检查聊天服务WebSocket连接状态
    _checkChatServiceState();

    // 检查应该连接但未连接的参与者
    for (final participant in _participants) {
      final peerId = participant.id;
      // 跳过自己
      if (participant.isMe) continue;

      // 如果未连接且根据ID规则应由我方发起连接
      if (!_connectedPeerIds.contains(peerId) &&
          !_pendingPeerIds.contains(peerId) &&
          !_peerConnections.containsKey(peerId) &&
          _currentUserId != null &&
          _currentUserId!.compareTo(peerId) < 0) {
        _pendingPeerIds.add(peerId);
        debugPrint('发现未连接的参与者 ${participant.name}，已添加到待连接列表');
      }
    }
  }

  // 添加会议聊天服务状态检查
  void _checkChatServiceState() {
    if (_chatService == null) {
      debugPrint('警告: 聊天服务为空，WebRTC信令无法传递');
      return;
    }

    if (!_chatService!.isConnected) {
      debugPrint('警告: 聊天服务WebSocket未连接，尝试重新连接');
      if (_currentMeetingId != null && _currentUserId != null) {
        try {
          _chatService!.connectToChat(_currentMeetingId!, _currentUserId!);
          // 添加短暂延迟，等待WebSocket连接建立
          Future.delayed(Duration(seconds: 1), () {
            if (_chatService!.isConnected) {
              debugPrint('WebSocket重新连接成功');
            } else {
              debugPrint('WebSocket重新连接失败');
            }
          });
        } catch (e) {
          debugPrint('重新连接WebSocket失败: $e');
        }
      }
    } else {
      debugPrint('聊天服务WebSocket已连接');
    }
  }

  // 处理特定的待连接对象，用于立即处理ICE候选触发的连接需求
  Future<void> _processSpecificPendingConnection(String peerId) async {
    if (!_participants.any((p) => p.id == peerId)) {
      debugPrint('用户 $peerId 不在参会者列表中，跳过连接处理');
      _pendingPeerIds.remove(peerId);
      return;
    }

    // 跳过已连接的用户
    if (_connectedPeerIds.contains(peerId)) {
      debugPrint('用户 $peerId 已连接，跳过处理');
      _pendingPeerIds.remove(peerId);
      return;
    }

    final peerName = _getPeerName(peerId);
    debugPrint('立即处理与 $peerName 的WebRTC连接');

    try {
      // 检查WebSocket连接状态
      if (_chatService != null) {
        _chatService!.checkConnection();
      }

      // 如果已存在连接，先检查状态
      if (_peerConnections.containsKey(peerId)) {
        final existingPc = _peerConnections[peerId];
        if (existingPc?.connectionState ==
                RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
            existingPc?.connectionState ==
                RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          debugPrint('已存在与 $peerName 的活跃连接，不再重新创建');
          _pendingPeerIds.remove(peerId);
          if (!_connectedPeerIds.contains(peerId)) {
            _connectedPeerIds.add(peerId);
          }
          return;
        }

        // 清理旧连接
        debugPrint('清理与 $peerName 的旧连接后重新建立');
        await _cleanupPeerConnection(peerId);
        // 添加适当延迟确保资源释放
        await Future.delayed(Duration(milliseconds: 300));
      }

      // ====== 发起方标准流程 ======
      debugPrint('【发起方流程】- 开始与 $peerName 建立WebRTC连接');

      // 步骤1: 创建RTCPeerConnection对象
      debugPrint('【发起方流程】- 步骤1: 创建RTCPeerConnection');
      final pc = await _createPeerConnection();

      _peerConnections[peerId] = pc;
      _connectionInfos[peerId] = ConnectionInfo(
        peerId: peerId,
        peerName: peerName,
        isConnected: false,
        isInitiator: true,
      );

      // 步骤2: 设置事件监听器
      debugPrint('【发起方流程】- 步骤2: 设置事件监听器');
      await _setupPeerConnection(pc, peerId, peerName);

      // 确认pc有效性
      if (_peerConnections[peerId] == null ||
          _peerConnections[peerId]!.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        throw Exception('PeerConnection在设置事件处理器后变为无效');
      }

      // 步骤3: 确保本地媒体流并添加到连接中
      debugPrint('【发起方流程】- 步骤3: 添加本地媒体流');
      if (_localStream == null) {
        await _initLocalStream();
      }

      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          // 清理旧轨道
          final senders = await pc.getSenders();
          for (final sender in senders) {
            await pc.removeTrack(sender);
          }

          // 添加音频轨道
          await pc.addTrack(audioTracks.first, _localStream!);
          audioTracks.first.enabled = !_isMuted;
          debugPrint('【发起方流程】- 已添加本地音频轨道，静音状态: $_isMuted');
        } else {
          debugPrint('【发起方流程】- 警告: 本地媒体流中没有音频轨道');
        }
      } else {
        debugPrint('【发起方流程】- 警告: 无法获取本地媒体流');
      }

      // 步骤4: 创建SDP Offer
      debugPrint('【发起方流程】- 步骤4: 创建SDP Offer');
      final offerOptions = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      };
      final offer = await pc.createOffer(offerOptions);

      // 步骤5: 设置本地描述
      debugPrint('【发起方流程】- 步骤5: 设置本地描述(Offer)');
      await pc.setLocalDescription(offer);

      // 步骤6: 发送Offer给对方
      debugPrint('【发起方流程】- 步骤6: 通过信令发送Offer');
      await _sendWebRTCSignal(peerId, {
        'type': 'offer',
        'sdp': offer.sdp,
        'fromId': _currentUserId,
        'toId': peerId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'meetingId': _currentMeetingId,
        'userId': _currentUserId,
      });

      debugPrint('【发起方流程】- 发送Offer完成，等待对方的Answer');

      // 记录连接开始时间
      _connectionInfos[peerId]?.connectedAt = DateTime.now();

      // 等待ICE候选收集和交换
      debugPrint('【发起方流程】- 等待ICE候选收集和交换');

      // 每次连接后添加短暂延迟，确保当前连接有足够时间处理
      await Future.delayed(Duration(milliseconds: 800));

      // 检查连接是否建立成功
      if (_connectionInfos[peerId]?.isConnected == true) {
        debugPrint('【发起方流程】- 与 $peerName 的连接已成功建立');
        _pendingPeerIds.remove(peerId);
        if (!_connectedPeerIds.contains(peerId)) {
          _connectedPeerIds.add(peerId);
        }
      } else {
        debugPrint('【发起方流程】- 与 $peerName 的连接尚未建立，等待连接状态变化');
      }
    } catch (e) {
      debugPrint('【发起方流程】- 与 $peerName 建立连接失败: $e');
      // 失败后不立即重试，改为延迟重试
      await Future.delayed(Duration(milliseconds: 1000));
      if (_participants.any((p) => p.id == peerId) &&
          !_pendingPeerIds.contains(peerId)) {
        _pendingPeerIds.add(peerId);
        debugPrint('已将 $peerName 添加回待连接列表，稍后将重试');
      }
    }
  }

  // 添加处理bye信号的方法
  Future<void> _handleBye(String fromId) async {
    final peerName = _getPeerName(fromId);
    debugPrint('收到 $peerName 的bye信号，准备断开连接');

    await _cleanupPeerConnection(fromId);

    // 如果对方主动断开，我们先从待连接列表中移除
    _pendingPeerIds.remove(fromId);
    _connectedPeerIds.remove(fromId);
  }

  // 优化后的ICE候选处理方法
  String _getCandidateType(String candidateStr) {
    if (candidateStr.contains("typ host")) {
      return "host";
    } else if (candidateStr.contains("typ srflx")) {
      return "srflx";
    } else if (candidateStr.contains("typ relay")) {
      return "relay";
    } else if (candidateStr.contains("typ prflx")) {
      return "prflx";
    }
    return "unknown";
  }

  // 批量处理并发送ICE候选信息
  void _scheduleCandidateBatch() {
    _candidateBatchTimer?.cancel();
    _candidateBatchTimer = Timer(Duration(milliseconds: 500), () {
      _processPendingCandidates();
    });
  }

  // 处理待发送的候选信息
  Future<void> _processPendingCandidates() async {
    _candidateBatchCounter++;
    final int currentBatch = _candidateBatchCounter;

    debugPrint('处理第 $currentBatch 批次的ICE候选信息');

    // 复制待处理列表，避免处理过程中修改列表
    final Map<String, List<Map<String, dynamic>>> pendingCopy = Map.from(
      _pendingCandidates,
    );

    // 每个对等端每种类型只发送一个候选
    for (final String peerId in pendingCopy.keys) {
      final peerName = _getPeerName(peerId);

      // 如果没有为该对等端初始化缓存，先初始化
      if (!_sentCandidates.containsKey(peerId)) {
        _sentCandidates[peerId] = {};
      }

      // 按类型分组候选信息
      final Map<String, List<Map<String, dynamic>>> candidatesByType = {};

      for (final candidate in pendingCopy[peerId] ?? []) {
        final String candidateStr = candidate['candidate'] as String;
        final String type = _getCandidateType(candidateStr);

        if (!candidatesByType.containsKey(type)) {
          candidatesByType[type] = [];
        }
        candidatesByType[type]!.add(candidate);
      }

      // 每种类型只发送一个候选
      for (final String type in candidatesByType.keys) {
        // 检查该类型是否已在当前批次发送过
        final String batchKey = '${type}_$currentBatch';
        if (_sentCandidates[peerId]![batchKey] == true) {
          continue; // 当前批次已发送过该类型，跳过
        }

        // 取该类型的第一个候选发送
        final candidateToSend = candidatesByType[type]!.first;
        final String candidateStr = candidateToSend['candidate'] as String;

        debugPrint('向 $peerName 发送 $type 类型的ICE候选 (批次: $currentBatch)');

        try {
          await _sendWebRTCSignal(peerId, {
            'type': 'candidate',
            'candidate': candidateStr,
            'sdpMid': candidateToSend['sdpMid'],
            'sdpMLineIndex': candidateToSend['sdpMLineIndex'],
            'fromId': _currentUserId,
            'toId': peerId,
            'candidateType': type,
            'batchNumber': currentBatch,
          });

          // 标记为已发送
          _sentCandidates[peerId]![batchKey] = true;

          // 从待发送列表中移除该候选
          if (_pendingCandidates.containsKey(peerId)) {
            _pendingCandidates[peerId]!.remove(candidateToSend);
            if (_pendingCandidates[peerId]!.isEmpty) {
              _pendingCandidates.remove(peerId);
            }
          }

          // 每次发送后短暂延迟，避免信令风暴
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('发送ICE候选失败: $e');
        }
      }
    }

    // 如果还有待处理的候选，安排下一批处理
    if (_pendingCandidates.isNotEmpty) {
      _scheduleCandidateBatch();
    }
  }
}
