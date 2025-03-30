import '../models/meeting.dart';

/// 会议服务接口
abstract class MeetingService {
  /// 获取所有会议列表
  Future<List<Meeting>> getMeetings();

  /// 根据ID获取会议详情
  Future<Meeting> getMeetingById(String id);

  /// 获取我的会议（已签到）
  Future<List<Meeting>> getMyMeetings();

  /// 搜索会议
  Future<List<Meeting>> searchMeetings(String query);

  /// 签到会议
  Future<bool> signInMeeting(String meetingId);
}

/// 模拟会议服务实现
class MockMeetingService implements MeetingService {
  // 模拟数据
  final List<Meeting> _meetings = [
    Meeting(
      id: '1',
      title: '项目周会',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      location: '会议室A',
      status: MeetingStatus.upcoming,
      type: MeetingType.regular,
      organizerId: 'user1',
      organizerName: '张三',
      description: '讨论本周项目进度和下周计划',
      participantCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Meeting(
      id: '2',
      title: '新员工培训',
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      location: '培训室B',
      status: MeetingStatus.upcoming,
      type: MeetingType.training,
      organizerId: 'user2',
      organizerName: '李四',
      description: '新入职员工系统使用培训',
      participantCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Meeting(
      id: '3',
      title: '面试-高级开发工程师',
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: DateTime.now().subtract(const Duration(hours: 1)),
      location: '面试室C',
      status: MeetingStatus.ongoing,
      type: MeetingType.interview,
      organizerId: 'user3',
      organizerName: '王五',
      description: '高级开发工程师面试',
      isSignedIn: true,
      participantCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Meeting(
      id: '4',
      title: '产品设计评审',
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: 22)),
      location: '会议室D',
      status: MeetingStatus.completed,
      type: MeetingType.regular,
      organizerId: 'user4',
      organizerName: '赵六',
      description: '新产品UI/UX设计评审会议',
      isSignedIn: true,
      participantCount: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Meeting(
      id: '5',
      title: '市场策略讨论',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().subtract(const Duration(hours: 23)),
      location: '会议室E',
      status: MeetingStatus.cancelled,
      type: MeetingType.regular,
      organizerId: 'user5',
      organizerName: '孙七',
      description: '讨论Q2市场推广策略',
      participantCount: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  Future<List<Meeting>> getMeetings() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));
    return _meetings;
  }

  @override
  Future<Meeting> getMeetingById(String id) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    final meeting = _meetings.firstWhere(
      (m) => m.id == id,
      orElse: () => throw Exception('会议不存在'),
    );

    return meeting;
  }

  @override
  Future<List<Meeting>> getMyMeetings() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    return _meetings.where((meeting) => meeting.isSignedIn).toList();
  }

  @override
  Future<List<Meeting>> searchMeetings(String query) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 空查询返回空列表
    if (query.isEmpty) {
      return [];
    }

    return _meetings.where((m) {
      final titleMatch = m.title.toLowerCase().contains(query.toLowerCase());
      final descMatch =
          m.description != null &&
          m.description!.toLowerCase().contains(query.toLowerCase());
      return titleMatch || descMatch;
    }).toList();
  }

  @override
  Future<bool> signInMeeting(String meetingId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 1000));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      _meetings[index] = _meetings[index].copyWith(isSignedIn: true);
      return true;
    } else {
      throw Exception('会议不存在');
    }
  }
}

/// API会议服务实现 - 将来用于实际的后端API调用
class ApiMeetingService implements MeetingService {
  // TODO: 实现 API 服务
  @override
  Future<List<Meeting>> getMeetings() async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<Meeting> getMeetingById(String id) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<List<Meeting>> getMyMeetings() async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<List<Meeting>> searchMeetings(String query) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<bool> signInMeeting(String meetingId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }
}
