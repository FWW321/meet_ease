import '../models/meeting.dart';
import '../models/user.dart';

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

  /// 验证会议密码
  Future<bool> validateMeetingPassword(String meetingId, String password);

  /// 更新会议密码
  Future<void> updateMeetingPassword(String meetingId, String? password);

  /// 获取会议参与者
  Future<List<User>> getMeetingParticipants(String meetingId);

  /// 添加会议管理员
  Future<void> addMeetingAdmin(String meetingId, String userId);

  /// 移除会议管理员
  Future<void> removeMeetingAdmin(String meetingId, String userId);

  /// 添加用户到黑名单
  Future<void> addUserToBlacklist(String meetingId, String userId);

  /// 从黑名单移除用户
  Future<void> removeUserFromBlacklist(String meetingId, String userId);

  /// 更新会议信息
  Future<void> updateMeeting(
    String meetingId, {
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    MeetingType? type,
  });

  /// 创建会议
  Future<Meeting> createMeeting({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required MeetingType type,
    required MeetingVisibility visibility,
    String? description,
    List<String> allowedUsers = const [],
    String? password,
  });
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
      admins: ['user5'],
      blacklist: const [],
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
      admins: const [],
      blacklist: const [],
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
      admins: ['user4'],
      blacklist: ['user8'],
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
      admins: const [],
      blacklist: const [],
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
      admins: const [],
      blacklist: const [],
    ),
  ];

  // 模拟用户数据
  final List<User> _users = [
    User(id: 'user1', name: '张三', email: 'zhangsan@example.com'),
    User(id: 'user2', name: '李四', email: 'lisi@example.com'),
    User(id: 'user3', name: '王五', email: 'wangwu@example.com'),
    User(id: 'user4', name: '赵六', email: 'zhaoliu@example.com'),
    User(id: 'user5', name: '孙七', email: 'sunqi@example.com'),
    User(id: 'user6', name: '周八', email: 'zhouba@example.com'),
    User(id: 'user7', name: '吴九', email: 'wujiu@example.com'),
    User(id: 'user8', name: '郑十', email: 'zhengshi@example.com'),
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

    // 确保admins和blacklist不为null
    return meeting.copyWith(
      admins: meeting.admins ?? const [],
      blacklist: meeting.blacklist ?? const [],
    );
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
      // 如果是通过会议ID搜索，优先检查ID匹配
      final idMatch = m.id.toLowerCase() == query.toLowerCase();

      // 对于可搜索会议，只有通过会议ID搜索才能找到
      if (m.visibility == MeetingVisibility.searchable) {
        return idMatch;
      }

      // 对于其他类型会议，支持通过标题或描述搜索
      final titleMatch = m.title.toLowerCase().contains(query.toLowerCase());
      final descMatch =
          m.description != null &&
          m.description!.toLowerCase().contains(query.toLowerCase());

      // 公开会议可以通过标题、描述或ID找到
      return titleMatch || descMatch || idMatch;
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

  @override
  Future<List<User>> getMeetingParticipants(String meetingId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 随机选择几个用户作为会议参与者
    return _users.take(6).toList();
  }

  @override
  Future<void> addMeetingAdmin(String meetingId, String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      final currentAdmins = List<String>.from(
        _meetings[index].admins ?? const [],
      );
      if (!currentAdmins.contains(userId)) {
        currentAdmins.add(userId);
        _meetings[index] = _meetings[index].copyWith(admins: currentAdmins);
      }
    } else {
      throw Exception('会议不存在');
    }
  }

  @override
  Future<void> removeMeetingAdmin(String meetingId, String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      final currentAdmins = List<String>.from(
        _meetings[index].admins ?? const [],
      );
      currentAdmins.remove(userId);
      _meetings[index] = _meetings[index].copyWith(admins: currentAdmins);
    } else {
      throw Exception('会议不存在');
    }
  }

  @override
  Future<void> addUserToBlacklist(String meetingId, String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      final currentBlacklist = List<String>.from(
        _meetings[index].blacklist ?? const [],
      );
      if (!currentBlacklist.contains(userId)) {
        currentBlacklist.add(userId);
        _meetings[index] = _meetings[index].copyWith(
          blacklist: currentBlacklist,
        );
      }
    } else {
      throw Exception('会议不存在');
    }
  }

  @override
  Future<void> removeUserFromBlacklist(String meetingId, String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      final currentBlacklist = List<String>.from(
        _meetings[index].blacklist ?? const [],
      );
      currentBlacklist.remove(userId);
      _meetings[index] = _meetings[index].copyWith(blacklist: currentBlacklist);
    } else {
      throw Exception('会议不存在');
    }
  }

  @override
  Future<void> updateMeeting(
    String meetingId, {
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    MeetingType? type,
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      _meetings[index] = _meetings[index].copyWith(
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        type: type,
        updatedAt: DateTime.now(),
      );
    } else {
      throw Exception('会议不存在');
    }
  }

  @override
  Future<Meeting> createMeeting({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required MeetingType type,
    required MeetingVisibility visibility,
    String? description,
    List<String> allowedUsers = const [],
    String? password,
  }) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 1000));

    // 生成唯一ID
    String id;
    if (visibility == MeetingVisibility.searchable) {
      // 为可搜索会议生成简短的会议码 (6位数字)
      id = _generateMeetingCode();
    } else {
      // 其他类型会议使用普通ID
      id = 'meeting_${DateTime.now().millisecondsSinceEpoch}';
    }

    // 创建新会议
    final newMeeting = Meeting(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      location: location,
      status: MeetingStatus.upcoming, // 新创建的会议默认为即将开始
      type: type,
      visibility: visibility,
      organizerId: 'user1', // 假设当前用户ID，实际中应该从认证服务中获取
      organizerName: '张三', // 假设当前用户名，实际中应该从认证服务中获取
      description: description,
      participantCount: 1, // 初始只有创建者
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      admins: const [],
      blacklist: const [],
      allowedUsers: allowedUsers,
      password: password,
    );

    // 将新会议添加到列表中
    _meetings.add(newMeeting);

    return newMeeting;
  }

  // 生成6位数字会议码
  String _generateMeetingCode() {
    // 生成6位随机数字
    final int code = 100000 + (DateTime.now().millisecondsSinceEpoch % 900000);
    return code.toString();
  }

  @override
  Future<bool> validateMeetingPassword(
    String meetingId,
    String password,
  ) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final meeting = await getMeetingById(meetingId);
      return meeting.checkPassword(password);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateMeetingPassword(String meetingId, String? password) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      _meetings[index] = _meetings[index].copyWith(
        password: password,
        updatedAt: DateTime.now(),
      );
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

  @override
  Future<List<User>> getMeetingParticipants(String meetingId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> addMeetingAdmin(String meetingId, String userId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> removeMeetingAdmin(String meetingId, String userId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> addUserToBlacklist(String meetingId, String userId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> removeUserFromBlacklist(String meetingId, String userId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> updateMeeting(
    String meetingId, {
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    MeetingType? type,
  }) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<Meeting> createMeeting({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required MeetingType type,
    required MeetingVisibility visibility,
    String? description,
    List<String> allowedUsers = const [],
    String? password,
  }) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<bool> validateMeetingPassword(
    String meetingId,
    String password,
  ) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<void> updateMeetingPassword(String meetingId, String? password) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }
}
