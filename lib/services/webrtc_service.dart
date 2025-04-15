import 'dart:async';

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
  Timer? _speakingSimulatorTimer;

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
    await Future.delayed(const Duration(seconds: 1));

    // 模拟数据 - 参会人员列表
    _participants = [
      MeetingParticipant(id: userId, name: userName, isMe: true),
      MeetingParticipant(id: 'user2', name: '李四', isCreator: true),
      MeetingParticipant(id: 'user3', name: '王五', isAdmin: true),
      MeetingParticipant(id: 'user4', name: '赵六'),
      MeetingParticipant(id: 'user5', name: '钱七'),
    ];

    _isConnected = true;

    // 发布初始参会人员列表
    _participantsController.add(_participants);

    // 模拟说话状态变化
    _speakingSimulatorTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // 随机选择一个人说话
      final speakingIndex =
          DateTime.now().millisecondsSinceEpoch % _participants.length;

      // 更新说话状态
      _participants =
          _participants.map((participant) {
            return participant.copyWith(
              isSpeaking:
                  _participants.indexOf(participant) == speakingIndex &&
                  !participant.isMuted,
            );
          }).toList();

      // 发布更新后的参会人员列表
      _participantsController.add(_participants);
    });
  }

  @override
  Future<void> leaveMeeting() async {
    _speakingSimulatorTimer?.cancel();
    _isConnected = false;
    _participants = [];

    // 发布空列表
    _participantsController.add(_participants);

    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> toggleMicrophone(bool enabled) async {
    _isMuted = !enabled;

    // 更新当前用户的静音状态
    _participants =
        _participants.map((participant) {
          if (participant.isMe) {
            return participant.copyWith(isMuted: _isMuted);
          }
          return participant;
        }).toList();

    // 发布更新后的参会人员列表
    _participantsController.add(_participants);

    await Future.delayed(const Duration(milliseconds: 100));
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
    _participantsController.close();
  }
}
