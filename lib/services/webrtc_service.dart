import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_service.dart';
import '../models/chat_message.dart';
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
  ChatService? _chatService;
  StreamSubscription<ChatMessage>? _chatSubscription;
  // Riverpod引用，用于获取当前用户信息
  Ref? _ref;

  // WebRTC相关变量
  final Map<String, RTCPeerConnection> _peerConnections = {};
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  // TURN服务器配置
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'urls': 'turn:fwwhub.fun:3478',
        'username': 'user1',
        'credential': 'password1',
      },
    ],
  };

  // 信令消息队列和锁
  final List<Map<String, dynamic>> _signalQueue = [];
  bool _isSendingSignal = false;

  // 添加ICE候选防抖动变量
  int _lastIceCandidateSent = 0;
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};

  // 设置ICE候选收集器防抖动
  void _setupIceCandidateCollector(RTCPeerConnection pc, String peerId) {
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        return;
      }

      // 将候选添加到待发送列表
      if (!_pendingIceCandidates.containsKey(peerId)) {
        _pendingIceCandidates[peerId] = [];
      }

      _pendingIceCandidates[peerId]!.add(candidate);

      // 使用防抖动发送
      _debounceSendIceCandidates(peerId);
    };
  }

  // 防抖动发送ICE候选
  Timer? _iceCandidateTimer;
  void _debounceSendIceCandidates(String peerId) {
    // 取消现有定时器
    _iceCandidateTimer?.cancel();

    // 创建新定时器，延迟发送候选
    _iceCandidateTimer = Timer(const Duration(milliseconds: 100), () {
      _sendPendingIceCandidates(peerId);
    });
  }

  // 发送等待的ICE候选
  Future<void> _sendPendingIceCandidates(String peerId) async {
    final candidates = _pendingIceCandidates[peerId];
    if (candidates == null || candidates.isEmpty) {
      return;
    }

    // 最多一次发送3个候选
    final toSend = candidates.take(3).toList();

    // 从等待列表中移除将要发送的候选
    _pendingIceCandidates[peerId] = candidates.sublist(
      toSend.length > candidates.length ? candidates.length : toSend.length,
    );

    // 发送这些候选
    for (final candidate in toSend) {
      _sendIceCandidate(peerId, candidate);
    }

    // 如果还有候选等待发送，安排下一次发送
    if (_pendingIceCandidates[peerId]!.isNotEmpty) {
      _debounceSendIceCandidates(peerId);
    }
  }

  // 设置聊天服务
  void setChatService(ChatService chatService) {
    debugPrint('WebRTCService-设置聊天服务');

    // 先取消旧的订阅
    _chatSubscription?.cancel();
    _chatSubscription = null;

    _chatService = chatService;

    // 如果已经有会议ID，立即订阅新的消息流
    if (_currentMeetingId != null && _chatService != null) {
      debugPrint('WebRTCService-立即订阅新聊天服务的消息流: $_currentMeetingId');

      try {
        final messageStream = _chatService!.getMessageStream(
          _currentMeetingId!,
        );

        _chatSubscription = messageStream.listen(
          (message) {
            // 确保在处理消息时会议ID仍然有效
            if (_currentMeetingId != null) {
              _handleChatMessage(message);
            }
          },
          onError: (error) {
            debugPrint('WebRTCService-聊天消息流错误: $error');
          },
          onDone: () {
            debugPrint('WebRTCService-聊天消息流已关闭');
          },
        );
      } catch (e) {
        debugPrint('WebRTCService-订阅聊天消息流失败: $e');
      }
    }
  }

  // 设置Ref
  @override
  void setRef(Ref ref) {
    _ref = ref;
  }

  @override
  Future<void> initialize() async {
    try {
      // 请求必要权限
      await _requestPermissions();

      // 初始化本地视频渲染器
      await _localRenderer.initialize();

      // 设置WebRTC全局选项，提高Android 15兼容性
      await WebRTC.initialize(
        options: {
          'androidAudioConfigurationLowLatency': true,
          'enableHardwareAcceleration': false, // 尝试禁用硬件加速增加稳定性
          'androidNetworkMonitor': false, // 禁用网络监控器，避免权限问题
        },
      );

      // 初始化本地媒体流
      await _initLocalStream();
    } catch (e) {
      debugPrint('WebRTC初始化失败: $e');
      // 不要立即抛出异常，允许应用继续运行
    }

    // 模拟初始化延迟
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // 请求必要权限
  Future<void> _requestPermissions() async {
    // 请求WebRTC所需权限
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.microphone, // 麦克风
          Permission.camera, // 摄像头(虽然我们不使用，但请求它可能会提高兼容性)
          Permission.bluetoothConnect, // 蓝牙连接(对耳机等设备)
        ].request();

    // 检查麦克风权限(最关键的权限)
    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      debugPrint('麦克风权限被拒绝，WebRTC功能可能受限');
    } else {
      debugPrint('成功获取麦克风权限');
    }

    // 记录其他权限状态但不强制要求
    statuses.forEach((permission, status) {
      if (permission != Permission.microphone) {
        debugPrint('$permission 权限状态: $status');
      }
    });
  }

  // 初始化本地媒体流
  Future<void> _initLocalStream() async {
    try {
      // 再次检查麦克风权限状态
      final micStatus = await Permission.microphone.status;
      if (micStatus != PermissionStatus.granted) {
        debugPrint('麦克风权限未授予，尝试再次请求');
        final result = await Permission.microphone.request();
        if (result != PermissionStatus.granted) {
          debugPrint('用户拒绝了麦克风权限，无法初始化媒体流');
          return;
        }
      }

      // 添加回音消除和降噪配置
      final Map<String, dynamic> constraints = {
        'audio': {
          'echoCancellation': true, // 启用回音消除
          'noiseSuppression': true, // 启用噪声抑制
          'autoGainControl': true, // 自动增益控制
          'disableLocalEcho': true, // 禁用本地回音
        },
        'video': false, // 仅音频会议
      };

      // 使用try-catch包装媒体流获取
      try {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
        debugPrint('本地媒体流初始化成功');

        // 确保音轨的默认状态是静音
        _localStream!.getAudioTracks().forEach((track) {
          track.enabled = false; // 默认静音
          debugPrint('已设置音轨 ${track.id} 为静音');
        });
      } catch (mediaError) {
        debugPrint('无法获取媒体流: $mediaError');
        // 尝试使用更宽松的约束
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
        });
      }
    } catch (e) {
      debugPrint('初始化本地媒体流失败: $e');
      // 记录错误但不抛出异常
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

    await Future.delayed(const Duration(seconds: 1));

    // 初始只有当前用户，默认麦克风关闭
    _participants = [
      MeetingParticipant(id: userId, name: userName, isMe: true, isMuted: true),
    ];

    _isConnected = true;
    _isMuted = true; // 默认麦克风静音

    // 确保本地媒体流已准备就绪
    if (_localStream == null) {
      try {
        await _initLocalStream();
      } catch (e) {
        debugPrint('加入会议时初始化媒体流失败: $e');
      }
    }

    // 初始化音频设置
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !_isMuted; // 根据静音状态设置音频轨道
      });
    }

    // 发布初始参会人员列表
    _participantsController.add(_participants);

    // 获取会议历史消息并更新参会人员列表
    if (_chatService != null && _currentMeetingId != null) {
      try {
        debugPrint('获取历史消息以初始化参会人员列表...');
        final messages = await _chatService!.getMeetingMessages(
          _currentMeetingId!,
        );
        debugPrint('成功获取历史消息: ${messages.length}条');

        // 先取消旧的订阅
        _chatSubscription?.cancel();
        _chatSubscription = null;

        // 先订阅新消息流，再更新参会人员列表，避免错过消息
        // 确保当前会议ID仍然有效(可能在异步操作期间已经改变)
        if (_currentMeetingId != null && _chatService != null) {
          debugPrint('开始订阅聊天消息流...');
          final messageStream = _chatService!.getMessageStream(
            _currentMeetingId!,
          );

          _chatSubscription = messageStream.listen(
            (message) {
              // 再次检查会议ID是否仍然有效
              if (_currentMeetingId != null) {
                debugPrint('WebRTC服务收到新消息: ${message.type}');

                // 处理WebRTC信令消息
                if (message.isSystemMessage &&
                    message.content.contains('webrtc_signal:')) {
                  _handleWebRTCSignal(message);
                } else {
                  _handleChatMessage(message);
                }
              }
            },
            onError: (error) {
              debugPrint('WebRTC服务聊天消息流错误: $error');
            },
            onDone: () {
              debugPrint('WebRTC服务聊天消息流已关闭');
            },
          );
          debugPrint('聊天消息流订阅成功');
        } else {
          debugPrint('会议ID已变更，取消订阅消息流');
        }

        // 更新参会人员列表
        if (_currentMeetingId != null) {
          // 再次检查会议ID是否有效
          _updateParticipantsFromMessages(messages);
          debugPrint('成功从历史消息初始化参会人员列表');

          // 作为新加入者，向所有现有参会者发送offer
          _sendOffersToExistingParticipants();
        }
      } catch (e) {
        debugPrint('获取会议消息失败: $e');
      }
    }
  }

  // 向所有现有参会者发送offer
  Future<void> _sendOffersToExistingParticipants() async {
    // 排除自己
    final existingParticipants = _participants.where((p) => !p.isMe).toList();

    debugPrint('向${existingParticipants.length}位现有参会者发送offer...');

    for (final participant in existingParticipants) {
      try {
        await _createPeerConnectionAndSendOffer(
          participant.id,
          participant.name,
        );
      } catch (e) {
        debugPrint('向${participant.name}发送offer失败: $e');
      }
    }
  }

  // 创建点对点连接并发送offer
  Future<void> _createPeerConnectionAndSendOffer(
    String peerId,
    String peerName,
  ) async {
    // 如果已存在连接，先关闭
    if (_peerConnections.containsKey(peerId)) {
      await _peerConnections[peerId]!.close();
      _peerConnections.remove(peerId);
    }

    debugPrint('开始创建与$peerName的连接...');

    try {
      // 创建RTCPeerConnection，添加兼容性选项
      final Map<String, dynamic> config = {
        ..._iceServers,
        'sdpSemantics': 'unified-plan',
        'enableDtlsSrtp': true,
        'rtcAudioJitterBufferMaxPackets': 30,
        'rtcAudioJitterBufferFastAccelerate': true,
        'iceTransportPolicy': 'all',
        // 添加音频处理配置
        'audioProcessing': {
          'echoCancellation': true, // 回音消除
          'noiseSuppression': true, // 噪声抑制
          'autoGainControl': true, // 自动增益控制
          'highpassFilter': true, // 高通滤波器（过滤低频噪音）
          'typingNoiseDetection': true, // 按键声检测
        },
      };

      // PeerConnection约束
      final Map<String, dynamic> constraints = {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
          {'RtpDataChannels': false},
        ],
      };

      final pc = await createPeerConnection(config, constraints);
      _peerConnections[peerId] = pc;

      // 添加本地媒体轨道 - 确保音频轨道正确添加
      if (_localStream != null) {
        try {
          debugPrint('准备添加本地音频轨道到连接...');
          final audioTracks = _localStream!.getAudioTracks();
          if (audioTracks.isNotEmpty) {
            // 只添加第一个音频轨道，避免回音问题
            final track = audioTracks.first;
            pc.addTrack(track, _localStream!);
            debugPrint('已添加单个音频轨道: ${track.id} 到与$peerName的连接');
            // 确保音频轨道状态与当前麦克风状态一致
            track.enabled = !_isMuted;
          } else {
            debugPrint('警告：本地流中没有可用的音频轨道');
          }
        } catch (e) {
          debugPrint('添加音频轨道失败: $e');
        }
      } else {
        debugPrint('错误：本地媒体流为空，无法添加音频轨道');
      }

      // 设置ICE候选收集器防抖动
      _setupIceCandidateCollector(pc, peerId);

      // 监听连接状态变化
      pc.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('与$peerName的连接状态: $state');
        // 当连接建立时，记录成功
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('🎉 与$peerName的WebRTC连接已成功建立!');
        }
      };

      // 监听ICE连接状态
      pc.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('与$peerName的ICE连接状态: $state');
      };

      // 监听远程媒体流
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          debugPrint(
            '收到来自$peerName的媒体流，包含轨道: ${event.track.id}, 类型: ${event.track.kind}',
          );

          // 如果是音频轨道
          if (event.track.kind == 'audio') {
            // 确保音频轨道已启用
            event.track.enabled = true;
            debugPrint('已启用来自$peerName的音频轨道');

            // 只处理第一个音频轨道
            final audioTracks = event.streams[0].getAudioTracks();
            if (audioTracks.isNotEmpty) {
              // 启用第一个轨道，忽略其他轨道
              final track = audioTracks.first;
              track.enabled = true;
              debugPrint('已启用单个远程音频轨道: ${track.id}');
            }

            // 更新UI，显示该用户正在通话中
            _updateParticipantConnectionStatus(peerId, true);
          }
        }
      };

      // 创建offer
      try {
        debugPrint('创建offer中...');
        final offer = await pc.createOffer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': false,
          'voiceActivityDetection': true,
        });
        await pc.setLocalDescription(offer);

        debugPrint('已创建offer，准备发送...');
        debugPrint('Offer SDP内容预览: ${offer.sdp?.substring(0, 100)}...');

        // 将offer通过系统消息发送给目标用户
        await _sendWebRTCSignal(peerId, {
          'type': 'offer',
          'sdp': offer.sdp,
          'fromId': _currentUserId,
          'toId': peerId,
        });

        debugPrint('已向$peerName发送offer');
      } catch (e) {
        debugPrint('创建或发送offer失败: $e');
      }
    } catch (e) {
      debugPrint('创建与$peerName的连接失败: $e');
      // 记录错误但继续执行
    }
  }

  // 处理WebRTC信令消息
  Future<void> _handleWebRTCSignal(ChatMessage message) async {
    try {
      // webrtc_signal:{"type":"offer","sdp":"...","fromId":"user1","toId":"user2"}
      final signalStr = message.content.substring('webrtc_signal:'.length);
      final signal = jsonDecode(signalStr);

      final String type = signal['type'];
      final String fromId = signal['fromId'];
      final String toId = signal['toId'];

      // 检查信令是否发给当前用户
      if (toId != _currentUserId) {
        // 不是发给当前用户的信令，忽略
        return;
      }

      debugPrint('处理来自$fromId的WebRTC信令: $type');

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
      }
    } catch (e) {
      debugPrint('处理WebRTC信令失败: $e');
    }
  }

  // 处理offer
  Future<void> _handleOffer(String fromId, Map<String, dynamic> signal) async {
    try {
      final String sdp = signal['sdp'];

      // 如果已存在连接，先关闭
      if (_peerConnections.containsKey(fromId)) {
        await _peerConnections[fromId]!.close();
        _peerConnections.remove(fromId);
      }

      // 创建新连接
      final Map<String, dynamic> config = {
        ..._iceServers,
        'sdpSemantics': 'unified-plan',
        'enableDtlsSrtp': true,
        'rtcAudioJitterBufferMaxPackets': 30,
        'rtcAudioJitterBufferFastAccelerate': true,
        'iceTransportPolicy': 'all',
      };

      final Map<String, dynamic> constraints = {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
          {'RtpDataChannels': false},
        ],
      };

      final pc = await createPeerConnection(config, constraints);
      _peerConnections[fromId] = pc;

      // 添加本地媒体轨道
      if (_localStream != null) {
        try {
          debugPrint('准备添加本地音频轨道到answer连接...');
          final audioTracks = _localStream!.getAudioTracks();
          if (audioTracks.isNotEmpty) {
            // 只添加第一个音频轨道，避免回音问题
            final track = audioTracks.first;
            pc.addTrack(track, _localStream!);
            debugPrint('已添加单个音频轨道: ${track.id} 到与$fromId的应答连接');
            // 确保音频轨道状态与当前麦克风状态一致
            track.enabled = !_isMuted;
          } else {
            debugPrint('警告：本地流中没有可用的音频轨道用于应答');
          }
        } catch (e) {
          debugPrint('添加音频轨道到应答连接失败: $e');
        }
      } else {
        debugPrint('错误：本地媒体流为空，无法添加音频轨道到应答连接');
      }

      // 设置ICE候选收集器防抖动
      _setupIceCandidateCollector(pc, fromId);

      // 监听连接状态变化
      pc.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('与$fromId的应答连接状态: $state');

        // 当连接建立时，记录成功
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('🎉 与$fromId的WebRTC应答连接已成功建立!');
        }

        // 如果连接失败或关闭，清理资源
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _peerConnections.remove(fromId);
        }
      };

      // 监听ICE连接状态
      pc.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint('与$fromId的ICE连接状态: $state');
      };

      // 监听远程媒体流
      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          debugPrint(
            '收到来自$fromId的媒体流，包含轨道: ${event.track.id}, 类型: ${event.track.kind}',
          );

          // 如果是音频轨道
          if (event.track.kind == 'audio') {
            // 确保音频轨道已启用
            event.track.enabled = true;
            debugPrint('已启用来自$fromId的音频轨道');

            // 只处理第一个音频轨道
            final audioTracks = event.streams[0].getAudioTracks();
            if (audioTracks.isNotEmpty) {
              // 启用第一个轨道，忽略其他轨道
              final track = audioTracks.first;
              track.enabled = true;
              debugPrint('已启用单个远程音频轨道: ${track.id}');
            }

            // 更新UI，显示该用户正在通话中
            _updateParticipantConnectionStatus(fromId, true);
          }
        }
      };

      try {
        // 设置远程描述
        debugPrint('设置远程描述(offer)...');
        final RTCSessionDescription remoteDesc = RTCSessionDescription(
          sdp,
          'offer',
        );
        await pc.setRemoteDescription(remoteDesc);

        // 创建answer
        debugPrint('创建answer...');
        final answer = await pc.createAnswer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': false,
          'voiceActivityDetection': true,
        });

        // 设置本地描述
        await pc.setLocalDescription(answer);
        debugPrint('Answer SDP内容预览: ${answer.sdp?.substring(0, 100)}...');

        // 发送answer
        await _sendWebRTCSignal(fromId, {
          'type': 'answer',
          'sdp': answer.sdp,
          'fromId': _currentUserId,
          'toId': fromId,
        });

        debugPrint('已向$fromId发送answer');
      } catch (e) {
        debugPrint('处理offer或创建answer失败: $e');
        // 清理连接
        _peerConnections.remove(fromId);
        await pc.close();
      }
    } catch (e) {
      debugPrint('处理offer失败: $e');
    }
  }

  // 处理answer
  Future<void> _handleAnswer(String fromId, Map<String, dynamic> signal) async {
    try {
      final String sdp = signal['sdp'];
      final pc = _peerConnections[fromId];

      if (pc == null) {
        debugPrint('未找到与$fromId的连接');
        return;
      }

      // 设置远程描述
      final RTCSessionDescription remoteDesc = RTCSessionDescription(
        sdp,
        'answer',
      );
      await pc.setRemoteDescription(remoteDesc);

      debugPrint('已设置来自$fromId的answer');
    } catch (e) {
      debugPrint('处理answer失败: $e');
    }
  }

  // 处理ICE候选
  Future<void> _handleIceCandidate(
    String fromId,
    Map<String, dynamic> signal,
  ) async {
    try {
      final pc = _peerConnections[fromId];

      if (pc == null) {
        debugPrint('未找到与$fromId的连接');
        return;
      }

      final candidate = RTCIceCandidate(
        signal['candidate'],
        signal['sdpMid'],
        signal['sdpMLineIndex'],
      );

      await pc.addCandidate(candidate);
      debugPrint('已添加来自$fromId的ICE候选');
    } catch (e) {
      debugPrint('处理ICE候选失败: $e');
    }
  }

  // 发送ICE候选
  Future<void> _sendIceCandidate(
    String peerId,
    RTCIceCandidate candidate,
  ) async {
    try {
      await _sendWebRTCSignal(peerId, {
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'fromId': _currentUserId,
        'toId': peerId,
      });
    } catch (e) {
      debugPrint('发送ICE候选失败: $e');
    }
  }

  // 发送WebRTC信令
  Future<void> _sendWebRTCSignal(
    String peerId,
    Map<String, dynamic> signal,
  ) async {
    if (_chatService == null || _currentMeetingId == null) {
      debugPrint('无法发送WebRTC信令: ChatService或会议ID为空');
      return;
    }

    // 将消息添加到队列
    _signalQueue.add({
      'peerId': peerId,
      'signal': signal,
      'type': signal['type'],
    });

    // 如果没有正在发送的消息，则开始处理队列
    if (!_isSendingSignal) {
      _processSignalQueue();
    }
  }

  // 处理信令队列
  Future<void> _processSignalQueue() async {
    if (_signalQueue.isEmpty || _isSendingSignal) {
      return;
    }

    _isSendingSignal = true;

    try {
      while (_signalQueue.isNotEmpty) {
        final item = _signalQueue.removeAt(0);
        final peerId = item['peerId'];
        final signal = item['signal'];
        final type = item['type'];

        try {
          final signalStr = jsonEncode(signal);
          final content = 'webrtc_signal:$signalStr';

          // 在发送前添加短暂延迟
          await Future.delayed(const Duration(milliseconds: 50));

          if (_chatService != null && _currentMeetingId != null) {
            await _chatService!.sendSystemMessage(_currentMeetingId!, content);
            debugPrint('已发送WebRTC信令: $type 到 $peerId');

            // 在消息之间添加延迟，避免WebSocket状态冲突
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          debugPrint('发送WebRTC信令失败: $e');
          // 失败后继续处理队列中的下一条消息
        }
      }
    } finally {
      _isSendingSignal = false;
    }
  }

  // 更新参会者连接状态
  void _updateParticipantConnectionStatus(
    String participantId,
    bool isConnected,
  ) {
    final index = _participants.indexWhere((p) => p.id == participantId);
    if (index >= 0) {
      // 这里可以添加更多状态，例如是否正在连接等
      // 当前仅简单更新
      _participantsController.add(List.from(_participants));
    }
  }

  // 处理聊天消息，特别是系统消息
  void _handleChatMessage(ChatMessage message) {
    debugPrint('WebRTCService收到消息: 类型=${message.type}, 内容=${message.content}');

    if (message.isSystemMessage) {
      debugPrint('WebRTCService收到系统消息: ${message.content}');

      // 检查消息内容是否包含关键动作
      if (message.content.contains('action:加入会议') ||
          message.content.contains('action:离开会议') ||
          message.content.contains('action:开启麦克风') ||
          message.content.contains('action:关闭麦克风')) {
        debugPrint('WebRTCService处理会议相关系统消息: ${message.content}');
        _updateParticipantsFromSystemMessage(message);
      } else {
        debugPrint('WebRTCService忽略非会议相关系统消息');
      }
    }
  }

  // 从系统消息更新参会人员
  void _updateParticipantsFromSystemMessage(ChatMessage message) {
    if (!message.isSystemMessage) {
      debugPrint('非系统消息，忽略: ${message.content}');
      return;
    }

    debugPrint('开始处理系统消息: ${message.content}');

    // 处理可能包含多个操作的系统消息
    // 例如 "userId:xxx, username:xxx, action:开启麦克风, userId:yyy, username:yyy, action:关闭麦克风"
    // 首先按照逗号分割，然后组合相关的字段
    final parts = message.content.split(', ');

    // 每三个部分（userId, username, action）为一组
    for (int i = 0; i < parts.length; i += 3) {
      if (i + 2 >= parts.length) {
        // 如果剩余部分不足一组，则跳过
        debugPrint('系统消息格式不正确，剩余部分不足一组: ${parts.sublist(i).join(', ')}');
        continue;
      }

      String? userId;
      String? username;
      String? action;

      // 提取当前组的三个部分
      for (int j = 0; j < 3; j++) {
        final part = parts[i + j];
        if (part.startsWith('userId:')) {
          userId = part.substring('userId:'.length).trim();
        } else if (part.startsWith('username:')) {
          username = part.substring('username:'.length).trim();
        } else if (part.startsWith('action:')) {
          action = part.substring('action:'.length).trim();
        }
      }

      // 如果缺少必要信息，则忽略当前组
      if (userId == null || username == null || action == null) {
        debugPrint('系统消息格式不正确，缺少必要信息: ${parts.sublist(i, i + 3).join(', ')}');
        continue;
      }

      debugPrint('处理系统消息组: userId=$userId, username=$username, action=$action');

      // 根据动作类型更新参会人员列表
      _processSystemAction(userId, username, action);
    }
  }

  // 处理系统消息中的单个动作
  void _processSystemAction(String userId, String username, String action) {
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
        // 新用户加入，默认麦克风为静音状态
        _participants.add(
          MeetingParticipant(
            id: userId,
            name: username,
            isMe: userId == _currentUserId,
            isMuted: true, // 默认麦克风静音
          ),
        );
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
    final index = _participants.indexWhere((p) => p.id == userId);
    if (index >= 0) {
      _participants[index] = _participants[index].copyWith(
        isMuted: isMuted,
        isSpeaking: isMuted ? false : _participants[index].isSpeaking,
      );
      debugPrint(
        '已更新用户 ${_participants[index].name} 的麦克风状态: ${isMuted ? "已静音" : "未静音"}',
      );
    } else {
      debugPrint('未找到要更新麦克风状态的用户: $userId');
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
            isMuted: true, // 默认麦克风静音
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
        userMicStates.putIfAbsent(userId, () => true); // 默认麦克风状态为静音
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
          // 获取用户麦克风状态，默认为静音
          final isMuted = userMicStates[userId] ?? true;

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
    debugPrint('WebRTCService-离开会议');

    // 停止音频活动检测
    _stopVoiceActivityDetection();

    // 关闭所有点对点连接
    for (final peerId in _peerConnections.keys) {
      try {
        await _peerConnections[peerId]?.close();
      } catch (e) {
        debugPrint('关闭与$peerId的连接失败: $e');
      }
    }
    _peerConnections.clear();

    // 禁用所有音频轨道
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = false;
    });

    // 取消消息订阅
    if (_chatSubscription != null) {
      await _chatSubscription!.cancel();
      _chatSubscription = null;
      debugPrint('WebRTCService-已取消聊天消息订阅');
    }

    _isConnected = false;
    _participants = [];
    _currentMeetingId = null;
    _currentUserId = null;
    _currentUserName = null;

    // 发布空列表
    if (!_participantsController.isClosed) {
      _participantsController.add(_participants);
      debugPrint('WebRTCService-已发布空参会人员列表');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('WebRTCService-离开会议完成');
  }

  @override
  Future<void> toggleMicrophone(bool enabled) async {
    final previousState = _isMuted;
    _isMuted = !enabled;

    // 更新本地媒体流轨道状态
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
        debugPrint('已${enabled ? "启用" : "禁用"}本地音频轨道');
      });
    }

    // 同步更新所有对等连接中的发送轨道状态
    for (final pc in _peerConnections.values) {
      pc
          .getSenders()
          .then((senders) {
            for (final sender in senders) {
              if (sender.track?.kind == 'audio') {
                sender.track!.enabled = enabled;
              }
            }
          })
          .catchError((e) {
            debugPrint('更新发送轨道状态失败: $e');
          });
    }

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

    // 启动音频级别检测（如果麦克风已开启）
    if (enabled) {
      _startVoiceActivityDetection();
    } else {
      _stopVoiceActivityDetection();
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // 音频活动检测相关变量
  Timer? _voiceDetectionTimer;
  final double _voiceThreshold = 0.01; // 音量阈值

  // 启动语音活动检测
  void _startVoiceActivityDetection() {
    // 取消现有的检测计时器
    _stopVoiceActivityDetection();

    // 如果麦克风静音或本地流为空，不启动检测
    if (_isMuted || _localStream == null) return;

    // 创建计时器，定期检测音频级别
    _voiceDetectionTimer = Timer.periodic(const Duration(milliseconds: 200), (
      _,
    ) {
      _detectVoiceActivity();
    });

    debugPrint('已启动语音活动检测');
  }

  // 停止语音活动检测
  void _stopVoiceActivityDetection() {
    _voiceDetectionTimer?.cancel();
    _voiceDetectionTimer = null;

    // 确保说话状态被重置
    _updateCurrentUserSpeakingStatus(false);
  }

  // 检测语音活动
  void _detectVoiceActivity() async {
    if (_localStream == null || _isMuted) {
      _updateCurrentUserSpeakingStatus(false);
      return;
    }

    try {
      // 获取音频轨道
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isEmpty) return;

      // 简化的语音活动检测方法
      // 仅检查音频轨道是否启用，而不是实际检测音量
      // 未来可以考虑使用更准确的音频级别检测
      final isEnabled = audioTracks.first.enabled && !_isMuted;

      // 随机模拟说话状态以实现可视化效果
      // 注意：这只是演示用，实际应用中应该使用真实的音频级别
      final bool isSpeaking =
          isEnabled && (DateTime.now().millisecondsSinceEpoch % 3000 < 1000);

      _updateCurrentUserSpeakingStatus(isSpeaking);

      // 记录状态变化
      if (isSpeaking) {
        debugPrint('检测到语音活动');
      }
    } catch (e) {
      debugPrint('语音活动检测失败: $e');
      // 确保说话状态被重置
      _updateCurrentUserSpeakingStatus(false);
    }
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

      // 使用ChatService发送系统消息
      if (_chatService != null) {
        await _chatService!.sendSystemMessage(_currentMeetingId!, content);
      } else {
        debugPrint('ChatService为空，无法发送麦克风状态系统消息');
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
    debugPrint('WebRTCService-正在销毁');

    // 停止音频活动检测
    _stopVoiceActivityDetection();

    // 释放WebRTC资源
    _localRenderer.dispose();

    // 关闭所有连接
    for (final pc in _peerConnections.values) {
      pc.close();
    }
    _peerConnections.clear();

    // 停止并释放媒体流
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    // 取消消息订阅
    if (_chatSubscription != null) {
      _chatSubscription!.cancel();
      _chatSubscription = null;
      debugPrint('WebRTCService-已取消聊天消息订阅');
    }

    // 关闭流控制器
    if (!_participantsController.isClosed) {
      _participantsController.close();
      debugPrint('WebRTCService-已关闭参会人员流控制器');
    }

    // 清空资源
    _participants = [];
    _currentMeetingId = null;
    _currentUserId = null;
    _currentUserName = null;
    _isConnected = false;

    debugPrint('WebRTCService-销毁完成');
  }

  // 直接处理系统消息
  void handleSystemMessage(ChatMessage message) {
    if (!message.isSystemMessage) {
      debugPrint('非系统消息，忽略');
      return;
    }

    if (message.content.startsWith('webrtc_signal:')) {
      _handleWebRTCSignal(message);
    } else {
      debugPrint('手动处理系统消息: ${message.content}');
      _updateParticipantsFromSystemMessage(message);
    }
  }
}
