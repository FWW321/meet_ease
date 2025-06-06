import '../models/meeting.dart';
import '../models/user.dart';
import '../models/meeting_recommendation.dart';
import '../models/meeting_participation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_providers.dart';
import 'package:flutter/foundation.dart';

/// 会议服务接口
abstract class MeetingService {
  /// 获取所有会议列表
  Future<List<Meeting>> getMeetings();

  /// 根据ID获取会议详情
  Future<Meeting> getMeetingById(String id);

  /// 获取我的会议（我参与的会议历史）
  Future<List<Meeting>> getMyMeetings();

  /// 搜索会议
  Future<List<Meeting>> searchMeetings(String query);

  /// 搜索私有会议
  Future<List<Meeting>> searchPrivateMeetings(String userId, String title);

  /// 搜索公有会议
  Future<List<Meeting>> searchPublicMeetings(String userId, String title);

  /// 签到会议
  Future<bool> signInMeeting(String meetingId);

  /// 验证会议密码
  Future<bool> validateMeetingPassword(String meetingId, String password);

  /// 更新会议密码
  /// @deprecated 此方法已废弃，会议密码在创建时确定，不支持后续修改
  Future<void> updateMeetingPassword(String meetingId, String? password);

  /// 获取会议参与者
  Future<List<User>> getMeetingParticipants(String meetingId);

  /// 获取会议管理员列表
  Future<List<User>> getMeetingManagers(String meetingId);

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

  /// 取消会议 - 仅即将开始的会议可取消，只有创建者有权限
  Future<Meeting> cancelMeeting(String meetingId, String creatorId);

  /// 结束会议 - 仅进行中的会议可结束，只有创建者有权限
  Future<Meeting> endMeeting(String meetingId, String creatorId);

  /// 上传会议文件
  Future<bool> uploadMeetingFile(
    String meetingId,
    String uploaderId,
    dynamic file,
  );

  /// 获取推荐会议
  Future<List<MeetingRecommendation>> getRecommendedMeetings(String userId);

  /// 获取我的私密会议
  Future<List<Meeting>> getMyPrivateMeetings(String userId);

  /// 提交请假申请
  Future<String> submitLeaveRequest(
    String userId,
    String meetingId,
    String reason,
  );
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
    // 添加一个私有会议
    Meeting(
      id: '6',
      title: '高管战略会议',
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
      location: '会议室F',
      status: MeetingStatus.upcoming,
      type: MeetingType.regular,
      visibility: MeetingVisibility.private,
      organizerId: 'user1',
      organizerName: '张三',
      description: '讨论公司下半年战略规划',
      participantCount: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      admins: ['user4'],
      blacklist: const [],
      allowedUsers: ['user2', 'user3', 'user4', 'user5'],
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
      admins: meeting.admins,
      blacklist: meeting.blacklist,
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
      if (m.visibility == MeetingVisibility.public) {
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
  Future<List<User>> getMeetingManagers(String meetingId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 随机选择几个用户作为会议管理者
    return _users.take(3).toList();
  }

  @override
  Future<void> addMeetingAdmin(String meetingId, String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index != -1) {
      final currentAdmins = List<String>.from(_meetings[index].admins);
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
      final currentAdmins = List<String>.from(_meetings[index].admins);
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
      final currentBlacklist = List<String>.from(_meetings[index].blacklist);
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
      final currentBlacklist = List<String>.from(_meetings[index].blacklist);
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
    if (visibility == MeetingVisibility.public) {
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
    // 获取此会议的锁并尝试获取
    final lock = _getLockForMeeting(meetingId);

    // 如果已有验证正在进行，等待锁
    try {
      await lock.acquire();
      debugPrint('获取到密码验证锁，开始验证: $meetingId');
    } catch (e) {
      debugPrint('获取验证锁失败: $e');
      throw Exception('无法验证密码，请稍后重试');
    }

    try {
      debugPrint('验证会议密码 - 会议ID: $meetingId, 密码: $password');

      // 尝试获取会议详情并验证密码
      final meetingFuture = getMeetingById(meetingId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('获取会议详情超时');
        },
      );

      final meeting = await meetingFuture;

      // 如果会议无密码，直接通过
      if (meeting.password == null || meeting.password!.isEmpty) {
        debugPrint('会议未设置密码，验证通过');
        return true;
      }

      // 比较密码是否匹配
      final isValid = meeting.password == password;
      debugPrint('密码比较: "${meeting.password}" == "$password" => $isValid');

      // 根据比较结果返回，不区分环境
      return isValid;
    } catch (e) {
      // 捕获到异常时，输出并向上传递
      debugPrint('密码验证过程出错: $e');
      rethrow;
    } finally {
      // 无论成功失败，都释放锁
      lock.release();
      debugPrint('释放密码验证锁: $meetingId');
    }
  }

  @override
  Future<void> updateMeetingPassword(String meetingId, String? password) async {
    // 该方法已废弃，直接抛出异常
    throw UnimplementedError('会议密码在创建时确定，不支持后续修改');
  }

  @override
  Future<Meeting> cancelMeeting(String meetingId, String creatorId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index == -1) {
      throw Exception('会议不存在');
    }

    final meeting = _meetings[index];

    // 检查创建者权限
    if (meeting.organizerId != creatorId) {
      throw Exception('只有会议创建者才能取消会议');
    }

    // 检查会议状态
    if (meeting.status != MeetingStatus.upcoming) {
      throw Exception('只有即将开始的会议可以取消');
    }

    // 更新会议状态为已取消
    final updatedMeeting = meeting.copyWith(
      status: MeetingStatus.cancelled,
      updatedAt: DateTime.now(),
    );

    _meetings[index] = updatedMeeting;
    return updatedMeeting;
  }

  @override
  Future<Meeting> endMeeting(String meetingId, String creatorId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _meetings.indexWhere((m) => m.id == meetingId);
    if (index == -1) {
      throw Exception('会议不存在');
    }

    final meeting = _meetings[index];

    // 检查创建者权限
    if (meeting.organizerId != creatorId) {
      throw Exception('只有会议创建者才能结束会议');
    }

    // 检查会议状态
    if (meeting.status != MeetingStatus.ongoing) {
      throw Exception('只有进行中的会议可以结束');
    }

    // 更新会议状态为已结束
    final updatedMeeting = meeting.copyWith(
      status: MeetingStatus.completed,
      updatedAt: DateTime.now(),
    );

    _meetings[index] = updatedMeeting;
    return updatedMeeting;
  }

  @override
  Future<bool> uploadMeetingFile(
    String meetingId,
    String uploaderId,
    dynamic file,
  ) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 1000));

    // 实现上传会议文件的逻辑
    // 这里需要根据实际情况实现文件上传的逻辑
    // 返回true表示上传成功，返回false表示上传失败
    return false;
  }

  @override
  Future<List<MeetingRecommendation>> getRecommendedMeetings(
    String userId,
  ) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 创建一些模拟推荐会议数据
    return [
      MeetingRecommendation(matchScore: 0.85, meeting: _meetings.first),
      MeetingRecommendation(
        matchScore: 0.65,
        meeting: _meetings.length > 1 ? _meetings[1] : _meetings.first,
      ),
    ];
  }

  @override
  Future<List<Meeting>> getMyPrivateMeetings(String userId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 返回我的私密会议模拟数据
    return _meetings
        .where(
          (m) =>
              m.visibility == MeetingVisibility.private &&
              (m.organizerId == userId || m.participants.contains(userId)),
        )
        .toList();
  }

  @override
  Future<String> submitLeaveRequest(
    String userId,
    String meetingId,
    String reason,
  ) async {
    // 实现提交请假申请的逻辑
    // 这里需要根据实际情况实现提交请假申请的逻辑
    // 返回请假申请提交后的处理结果
    return '请假申请提交成功';
  }

  @override
  Future<List<Meeting>> searchPrivateMeetings(
    String userId,
    String title,
  ) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    // 过滤私有会议，查找标题包含搜索关键词的会议
    return _meetings
        .where(
          (m) =>
              m.visibility == MeetingVisibility.private &&
              m.title.toLowerCase().contains(title.toLowerCase()) &&
              (m.organizerId == userId || m.allowedUsers.contains(userId)),
        )
        .toList();
  }

  @override
  Future<List<Meeting>> searchPublicMeetings(
    String userId,
    String title,
  ) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));

    // 过滤公开和可搜索会议，查找标题包含搜索关键词的会议
    return _meetings
        .where(
          (m) =>
              (m.visibility == MeetingVisibility.public ||
                  m.visibility == MeetingVisibility.public) &&
              m.title.toLowerCase().contains(title.toLowerCase()),
        )
        .toList();
  }
}

/// API会议服务实现 - 将来用于实际的后端API调用
class ApiMeetingService implements MeetingService {
  final http.Client _client = http.Client();
  final Ref? _ref;

  ApiMeetingService([this._ref]);

  @override
  Future<List<Meeting>> getMeetings() async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/list'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final meetingListData = responseData['data'];
          final meetingRecords = meetingListData['records'] as List<dynamic>;
          final currentTime = DateTime.now();

          // 将API返回的会议记录转换为Meeting对象列表
          return meetingRecords.map<Meeting>((record) {
            // 解析会议状态
            MeetingStatus meetingStatus = _parseMeetingStatus(
              record['status'] ?? '待开始',
            );

            // 解析开始和结束时间
            final startTime = DateTime.parse(record['startTime']);
            final endTime = DateTime.parse(record['endTime']);

            // 根据当前时间更新会议状态
            // 如果当前时间在会议开始和结束时间之间，将状态设为"进行中"
            if (currentTime.isAfter(startTime) &&
                currentTime.isBefore(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.ongoing;
              // TODO: 调用更新会议状态为"进行中"的接口 - 接口未实现，保留逻辑
            }
            // 如果当前时间超过会议结束时间，将状态设为"已结束"
            else if (currentTime.isAfter(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.completed;
              // TODO: 调用更新会议状态为"已结束"的接口 - 接口未实现，保留逻辑
            }

            return Meeting(
              id: record['meetingId'].toString(),
              title: record['title'],
              startTime: startTime,
              endTime: endTime,
              location: record['location'],
              status: meetingStatus,
              type: MeetingType.regular, // 默认为常规会议
              visibility: MeetingVisibility.public, // 默认可见性，API未提供
              organizerId: record['organizerId'].toString(),
              organizerName: '', // API未提供组织者名称
              description: record['description'],
              createdAt: DateTime.parse(record['createdAt']),
            );
          }).toList();
        } else {
          final message = responseData['message'] ?? '获取会议列表失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '获取会议列表请求失败'),
        );
      }
    } catch (e) {
      throw Exception('获取会议列表时出错: $e');
    }
  }

  // 解析会议状态字符串为枚举值
  MeetingStatus _parseMeetingStatus(String statusStr) {
    switch (statusStr) {
      case '待开始':
        return MeetingStatus.upcoming;
      case '进行中':
        return MeetingStatus.ongoing;
      case '已结束':
        return MeetingStatus.completed;
      case '已取消':
        return MeetingStatus.cancelled;
      default:
        return MeetingStatus.upcoming;
    }
  }

  @override
  Future<Meeting> getMeetingById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/$id'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final meetingData = responseData['data'];
          final currentTime = DateTime.now();

          // 解析会议状态
          MeetingStatus meetingStatus = _parseMeetingStatus(
            meetingData['status'] ?? '待开始',
          );

          // 解析开始和结束时间
          final startTime = DateTime.parse(meetingData['startTime']);
          final endTime = DateTime.parse(meetingData['endTime']);

          // 根据当前时间更新会议状态
          // 如果当前时间在会议开始和结束时间之间，将状态设为"进行中"
          if (currentTime.isAfter(startTime) &&
              currentTime.isBefore(endTime) &&
              meetingStatus != MeetingStatus.cancelled) {
            meetingStatus = MeetingStatus.ongoing;
            // TODO: 调用更新会议状态为"进行中"的接口 - 接口未实现，保留逻辑
          }
          // 如果当前时间超过会议结束时间，将状态设为"已结束"
          else if (currentTime.isAfter(endTime) &&
              meetingStatus != MeetingStatus.cancelled) {
            meetingStatus = MeetingStatus.completed;
            // TODO: 调用更新会议状态为"已结束"的接口 - 接口未实现，保留逻辑
          }

          // 处理管理员ID列表
          List<String> adminIds = [];
          if (meetingData['adminIds'] != null) {
            if (meetingData['adminIds'] is List) {
              adminIds =
                  (meetingData['adminIds'] as List)
                      .map((item) => item.toString())
                      .toList();
            } else if (meetingData['adminIds'] is String) {
              // 如果adminIds是逗号分隔的字符串，则拆分为列表
              final adminIdsStr = meetingData['adminIds'] as String;
              if (adminIdsStr.isNotEmpty) {
                adminIds =
                    adminIdsStr.split(',').map((id) => id.trim()).toList();
              }
            }
          }

          // 解析会议可见性
          final visibility = _parseMeetingVisibility(meetingData['visibility']);
          debugPrint(
            '从API解析的会议可见性: ${meetingData['visibility']} => $visibility',
          );

          return Meeting(
            id: meetingData['meetingId'].toString(),
            title: meetingData['title'],
            startTime: startTime,
            endTime: endTime,
            location: meetingData['location'] ?? '',
            status: meetingStatus,
            type: MeetingType.regular, // 默认为常规会议
            visibility: visibility,
            organizerId: meetingData['organizerId'].toString(),
            organizerName: '', // API未提供组织者名称
            description: meetingData['description'],
            createdAt:
                meetingData['createdAt'] != null
                    ? DateTime.parse(meetingData['createdAt'])
                    : null,
            admins: adminIds,
            blacklist: const [], // API未提供
            allowedUsers: const [], // API未提供
            password: meetingData['joinPassword'], // 添加会议密码字段
          );
        } else {
          final message = responseData['message'] ?? '获取会议详情失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '获取会议详情请求失败'),
        );
      }
    } catch (e) {
      throw Exception('获取会议详情时出错: $e');
    }
  }

  @override
  Future<List<Meeting>> getMyMeetings() async {
    try {
      String userId;

      // 如果有依赖注入的 Ref，则通过 Provider 获取用户ID
      if (_ref != null) {
        userId = await _ref.read(currentUserIdProvider.future);
        if (userId.isEmpty) {
          throw Exception('用户未登录，无法获取参与会议');
        }
      } else {
        // 兼容性处理：如果没有 Ref，则尝试从本地存储获取
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        if (userJson == null) {
          throw Exception('用户未登录，无法获取参与会议');
        }

        final userData = jsonDecode(userJson);
        userId = userData['id']?.toString() ?? '';
        if (userId.isEmpty) {
          throw Exception('获取用户ID失败');
        }
      }

      final url =
          '${AppConstants.apiBaseUrl}/meeting/user/$userId/participation-history';
      final response = await http
          .get(Uri.parse(url), headers: HttpUtils.createHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 使用HttpUtils.decodeResponse处理UTF-8编码的响应数据
        final responseData = HttpUtils.decodeResponse(response);
        final meetingParticipationResponse =
            MeetingParticipationResponse.fromJson(responseData);

        // 将会议参与数据转换为Meeting模型
        return meetingParticipationResponse.data
            .map((participation) => participation.toMeeting())
            .toList();
      } else {
        throw Exception('获取参与会议历史失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取我的会议列表异常: $e');
      throw Exception('获取我的会议列表失败: $e');
    }
  }

  @override
  Future<List<Meeting>> searchMeetings(String query) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<bool> signInMeeting(String meetingId) async {
    try {
      // 获取当前用户ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('用户未登录，无法签到');
      }

      // 先获取会议详情，检查会议类型
      final meeting = await getMeetingById(meetingId);

      // 检查会议是否为私有会议
      if (meeting.visibility != MeetingVisibility.private) {
        throw Exception('只有私有会议支持签到功能');
      }

      // 创建请求URL，添加查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/signin/submit',
      ).replace(queryParameters: {'meetingId': meetingId, 'userId': userId});

      // 发起POST请求
      final response = await _client.post(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 签到成功
          return true;
        } else {
          final message = responseData['message'] ?? '签到失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '签到请求失败'),
        );
      }
    } catch (e) {
      debugPrint('签到失败: $e');
      throw Exception('签到时出错: $e');
    }
  }

  @override
  Future<List<User>> getMeetingParticipants(String meetingId) async {
    try {
      // 尝试从API获取会议参与者列表
      final response = await _client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/meeting/$meetingId/participants'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final participants = responseData['data'] as List<dynamic>;

          // 将API返回的参与者记录转换为User对象列表
          return participants.map<User>((record) {
            // 获取角色类型并转换为MeetingPermission类型
            final roleString = record['role'] as String? ?? 'PARTICIPANT';
            MeetingPermission role;

            switch (roleString) {
              case 'HOST':
                role = MeetingPermission.creator;
                break;
              case 'ADMIN':
                role = MeetingPermission.admin;
                break;
              case 'PARTICIPANT':
                role = MeetingPermission.participant;
                break;
              default:
                role = MeetingPermission.participant;
            }

            // 获取签到状态
            final signInStatus = record['sign_in_status'] as String? ?? '未签到';

            // 获取请假状态
            final leaveStatus = record['leave_status'] as String?;

            return User(
              id: record['user_id']?.toString() ?? '',
              name: record['username'] ?? '未知用户',
              email: '',
              role: role,
              signInStatus: signInStatus,
              leaveStatus: leaveStatus,
            );
          }).toList();
        } else {
          // API返回错误
          final message = responseData['message'] ?? '获取会议参与者失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(
            response,
            defaultMessage: '获取会议参与者请求失败',
          ),
        );
      }
    } catch (e) {
      // 如果API调用失败，返回空列表
      debugPrint('获取会议参与者失败: $e');
      return [];
    }
  }

  @override
  Future<List<User>> getMeetingManagers(String meetingId) async {
    try {
      // 构建API请求
      final response = await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}/meeting/$meetingId/managers'),
            headers: HttpUtils.createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // 解析响应
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] == 200 && responseData['data'] != null) {
        final data = responseData['data'];

        // 获取管理员列表
        final adminsData = data['admins'] as List<dynamic>? ?? [];

        // 将返回数据转换为User对象
        final managers =
            adminsData.map((admin) {
              return User(
                id: admin['user_id'].toString(), // 确保转换为字符串
                name: admin['username'] ?? '',
                email: '', // API未提供邮箱
              );
            }).toList();

        return managers;
      } else {
        throw Exception('获取会议管理员失败: ${responseData['message']}');
      }
    } catch (e) {
      // 重抛出异常
      throw Exception('获取会议管理员时出错: $e');
    }
  }

  @override
  Future<void> addMeetingAdmin(String meetingId, String userId) async {
    try {
      // 获取当前用户ID
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      String currentUserId = '';

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        currentUserId = userData['id'] ?? '';
      }

      // 构建API请求
      final response = await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}/meeting/admin/add').replace(
              queryParameters: {
                'meetingId': meetingId,
                'userId': userId,
                'currentUserId': currentUserId,
              },
            ),
            headers: HttpUtils.createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // 解析响应
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '添加管理员失败');
      }

      // 操作成功
      return;
    } catch (e) {
      // 重抛出异常
      throw Exception('添加管理员时出错: $e');
    }
  }

  @override
  Future<void> removeMeetingAdmin(String meetingId, String userId) async {
    try {
      // 获取当前用户ID
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      String currentUserId = '';

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        currentUserId = userData['id'] ?? '';
      }

      // 构建API请求
      final response = await http
          .post(
            Uri.parse(
              '${AppConstants.apiBaseUrl}/meeting/admin/remove',
            ).replace(
              queryParameters: {
                'meetingId': meetingId,
                'userId': userId,
                'currentUserId': currentUserId,
              },
            ),
            headers: HttpUtils.createHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      // 解析响应
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '移除管理员失败');
      }

      // 操作成功
      return;
    } catch (e) {
      // 重抛出异常
      throw Exception('移除管理员时出错: $e');
    }
  }

  @override
  Future<void> addUserToBlacklist(String meetingId, String userId) async {
    try {
      // 获取当前用户ID作为操作者ID
      String operatorId = '';
      if (_ref != null) {
        operatorId = await _ref.read(currentUserIdProvider.future);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        if (userJson != null) {
          final userData = jsonDecode(userJson);
          operatorId = userData['id']?.toString() ?? '';
        }
      }

      if (operatorId.isEmpty) {
        throw Exception('无法获取操作者ID');
      }

      // 构建请求体
      final requestBody = jsonEncode({
        'meetingId': meetingId,
        'userId': userId,
        'duration': -1, // 固定值
        'operatorId': operatorId,
      });

      // 发送POST请求
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/blacklist/add'),
        headers: HttpUtils.createHeaders(),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        if (responseData['code'] == 200) {
          debugPrint('添加黑名单成功: ${responseData['data']}');
        } else {
          throw Exception(responseData['message'] ?? '添加黑名单失败');
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '添加黑名单请求失败'),
        );
      }
    } catch (e) {
      throw Exception('添加黑名单时出错: $e');
    }
  }

  @override
  Future<void> removeUserFromBlacklist(String meetingId, String userId) async {
    try {
      // 获取当前用户ID作为操作者ID
      String operatorId = '';
      if (_ref != null) {
        operatorId = await _ref.read(currentUserIdProvider.future);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        if (userJson != null) {
          final userData = jsonDecode(userJson);
          operatorId = userData['id']?.toString() ?? '';
        }
      }

      if (operatorId.isEmpty) {
        throw Exception('无法获取操作者ID');
      }

      // 构建请求体
      final requestBody = jsonEncode({
        'meetingId': meetingId,
        'userId': userId,
        'operatorId': operatorId,
      });

      // 发送POST请求
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/blacklist/remove'),
        headers: HttpUtils.createHeaders(),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        if (responseData['code'] == 200) {
          debugPrint('移除黑名单成功: ${responseData['data']}');
        } else {
          throw Exception(responseData['message'] ?? '移除黑名单失败');
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '移除黑名单请求失败'),
        );
      }
    } catch (e) {
      throw Exception('移除黑名单时出错: $e');
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
    try {
      // 获取会议详情，检查是否可以更新startTime
      Meeting? currentMeeting;
      if (startTime != null) {
        currentMeeting = await getMeetingById(meetingId);

        // 如果会议不是即将开始状态，则不允许修改startTime
        if (currentMeeting.status != MeetingStatus.upcoming) {
          throw Exception('只有即将开始的会议才能修改开始时间');
        }
      }

      // 构建查询参数
      final Map<String, String> queryParams = {'meetingId': meetingId};

      // 添加可选参数
      if (title != null) {
        queryParams['title'] = title;
      }

      if (location != null) {
        queryParams['location'] = location;
      }

      if (startTime != null) {
        queryParams['startTime'] = startTime.toIso8601String();
      }

      if (endTime != null) {
        queryParams['endTime'] = endTime.toIso8601String();
      }

      if (type != null) {
        queryParams['meetingType'] = _getMeetingTypeString(type);
      }

      // 创建URI并添加查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/update',
      ).replace(queryParameters: queryParams);

      // 发送PUT请求
      final response = await _client.put(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        if (responseData['code'] == 200) {
          // 操作成功，可以处理返回的消息
          debugPrint('更新会议成功');
        } else {
          throw Exception(responseData['message'] ?? '更新会议失败');
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '更新会议请求失败'),
        );
      }
    } catch (e) {
      throw Exception('更新会议时出错: $e');
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
    try {
      // 获取当前用户ID
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      String organizerId = '';
      String organizerName = '';

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        organizerId = userData['id'] ?? '';
        organizerName = userData['name'] ?? '';
      }

      // 格式化日期时间
      final formattedStartTime = startTime.toIso8601String();
      final formattedEndTime = endTime.toIso8601String();

      // 确定使用的API路径
      String apiPath;
      Map<String, dynamic> requestBodyMap;

      // 根据可见性类型选择API路径
      if (visibility == MeetingVisibility.private) {
        // 私有会议请求使用原有的接口
        apiPath = '${AppConstants.apiBaseUrl}/meeting/create';
        requestBodyMap = {
          'title': title,
          'description': description ?? '',
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
          'organizerId': organizerId,
          'location': location,
          'participantIds': allowedUsers,
        };
      } else {
        // 公开会议和可搜索会议使用新接口
        apiPath = '${AppConstants.apiBaseUrl}/meeting/createPublic';

        // 根据可见性设置visibility字段（大写）
        String visibilityStr =
            visibility == MeetingVisibility.public ? 'PUBLIC' : 'SEARCHABLE';

        // 构建请求体
        requestBodyMap = {
          'title': title,
          'description': description ?? '',
          'startTime': formattedStartTime,
          'endTime': formattedEndTime,
          'organizerId': organizerId,
          'location': location,
          'visibility': visibilityStr,
          'meetingType': _getMeetingTypeString(type),
          'joinPassword': password, // 如果为null则表示不设置密码
        };
      }

      // 转换为JSON
      final requestBody = jsonEncode(requestBodyMap);

      // 发送POST请求
      final response = await _client.post(
        Uri.parse(apiPath),
        headers: HttpUtils.createHeaders(),
        body: requestBody,
      );

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 判断请求是否成功
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final meetingData = responseData['data'];

          // 根据返回数据创建Meeting对象
          final meetingStatus = _parseMeetingStatus(
            meetingData['status'] ?? '待开始',
          );

          // 获取可见性
          MeetingVisibility returnedVisibility = visibility; // 默认使用请求中的可见性
          if (meetingData['visibility'] != null) {
            // 从响应中解析可见性（如果有）
            final visibilityStr =
                meetingData['visibility'].toString().toUpperCase();
            if (visibilityStr == 'PUBLIC') {
              returnedVisibility = MeetingVisibility.public;
            } else if (visibilityStr == 'PRIVATE') {
              returnedVisibility = MeetingVisibility.private;
            }
          }

          return Meeting(
            id: meetingData['meetingId'].toString(),
            title: meetingData['title'],
            startTime: DateTime.parse(meetingData['startTime']),
            endTime: DateTime.parse(meetingData['endTime']),
            location: meetingData['location'],
            status: meetingStatus,
            type: type, // API响应中没有会议类型，使用请求参数中的类型
            visibility: returnedVisibility,
            organizerId: meetingData['organizerId'].toString(),
            organizerName: organizerName, // API响应中可能没有组织者名称
            description: meetingData['description'],
            createdAt:
                meetingData['createdAt'] != null
                    ? DateTime.parse(meetingData['createdAt'])
                    : DateTime.now(),
            password: meetingData['joinPassword'],
          );
        } else {
          final message = responseData['message'] ?? '创建会议失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '创建会议请求失败'),
        );
      }
    } catch (e) {
      throw Exception('创建会议时出错: $e');
    }
  }

  // 获取会议类型的字符串表示
  String _getMeetingTypeString(MeetingType type) {
    switch (type) {
      case MeetingType.regular:
        return '常规会议';
      case MeetingType.training:
        return '培训会议';
      case MeetingType.interview:
        return '面试会议';
      case MeetingType.other:
        return '其他';
    }
  }

  @override
  Future<bool> validateMeetingPassword(
    String meetingId,
    String password,
  ) async {
    // 获取此会议的锁并尝试获取
    final lock = _getLockForMeeting(meetingId);

    // 如果已有验证正在进行，等待锁
    try {
      await lock.acquire();
      debugPrint('获取到密码验证锁，开始验证: $meetingId');
    } catch (e) {
      debugPrint('获取验证锁失败: $e');
      throw Exception('无法验证密码，请稍后重试');
    }

    try {
      debugPrint('验证会议密码 - 会议ID: $meetingId, 密码: $password');

      // 尝试获取会议详情并验证密码
      final meetingFuture = getMeetingById(meetingId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('获取会议详情超时');
        },
      );

      final meeting = await meetingFuture;

      // 如果会议无密码，直接通过
      if (meeting.password == null || meeting.password!.isEmpty) {
        debugPrint('会议未设置密码，验证通过');
        return true;
      }

      // 比较密码是否匹配
      final isValid = meeting.password == password;
      debugPrint('密码比较: "${meeting.password}" == "$password" => $isValid');

      // 根据比较结果返回，不区分环境
      return isValid;
    } catch (e) {
      // 捕获到异常时，输出并向上传递
      debugPrint('密码验证过程出错: $e');
      rethrow;
    } finally {
      // 无论成功失败，都释放锁
      lock.release();
      debugPrint('释放密码验证锁: $meetingId');
    }
  }

  @override
  Future<void> updateMeetingPassword(String meetingId, String? password) async {
    // 该方法已废弃，直接抛出异常
    throw UnimplementedError('会议密码在创建时确定，不支持后续修改');
  }

  @override
  Future<Meeting> cancelMeeting(String meetingId, String creatorId) async {
    // TODO: 使用HTTP客户端调用后端API
    throw UnimplementedError('API会议服务尚未实现');
  }

  @override
  Future<Meeting> endMeeting(String meetingId, String creatorId) async {
    try {
      // 构建请求 URL
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/$meetingId/end',
      ).replace(queryParameters: {'userId': creatorId});

      // 发送 POST 请求
      final response = await _client.post(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200 && responseData['data'] != null) {
          final meetingData = responseData['data'];

          // 解析会议状态
          MeetingStatus meetingStatus = _parseMeetingStatus(
            meetingData['status'] ?? '已结束',
          );

          // 解析开始和结束时间
          final startTime = DateTime.parse(meetingData['startTime']);
          final endTime = DateTime.parse(meetingData['endTime']);

          // 获取可见性
          final visibility = _parseMeetingVisibility(meetingData['visibility']);

          // 获取管理员列表
          final adminIds =
              (meetingData['adminIds'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .toList() ??
              [];

          return Meeting(
            id: meetingData['meetingId'].toString(),
            title: meetingData['title'],
            startTime: startTime,
            endTime: endTime,
            location: meetingData['location'] ?? '',
            status: meetingStatus,
            type: MeetingType.regular, // 默认为常规会议
            visibility: visibility,
            organizerId: meetingData['organizerId'].toString(),
            organizerName: '', // API未提供组织者名称
            description: meetingData['description'],
            createdAt:
                meetingData['createdAt'] != null
                    ? DateTime.parse(meetingData['createdAt'])
                    : null,
            admins: adminIds,
            blacklist: const [], // API未提供
            allowedUsers: const [], // API未提供
            password: meetingData['joinPassword'],
          );
        } else {
          final message = responseData['message'] ?? '结束会议失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '结束会议请求失败'),
        );
      }
    } catch (e) {
      debugPrint('结束会议时出错: $e');
      throw Exception('结束会议时出错: $e');
    }
  }

  @override
  Future<bool> uploadMeetingFile(
    String meetingId,
    String uploaderId,
    dynamic file,
  ) async {
    try {
      // 创建multipart请求
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/meeting/file/upload/$meetingId',
      );
      final request = http.MultipartRequest('POST', uri);

      // 添加文件
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // 添加其他表单字段
      request.fields['meetingId'] = meetingId;
      request.fields['uploaderId'] = uploaderId;

      // 发送请求
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 处理响应
      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 判断请求是否成功
        if (responseData['code'] == 200) {
          return true;
        } else {
          final message = responseData['message'] ?? '上传会议文件失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '上传会议文件请求失败'),
        );
      }
    } catch (e) {
      throw Exception('上传会议文件时出错: $e');
    }
  }

  @override
  Future<List<MeetingRecommendation>> getRecommendedMeetings(
    String userId,
  ) async {
    try {
      final url =
          '${AppConstants.apiBaseUrl}/meetings/recommend/public/$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        // 使用HttpUtils.decodeResponse解决编码问题
        final jsonData = HttpUtils.decodeResponse(response);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> recommendationsData = jsonData['data'];

          return recommendationsData
              .map((data) => MeetingRecommendation.fromJson(data))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('获取推荐会议失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Meeting>> getMyPrivateMeetings(String userId) async {
    try {
      final url =
          '${AppConstants.apiBaseUrl}/meetings/recommend/private/$userId';
      final response = await http.get(
        Uri.parse(url),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        // 使用HttpUtils.decodeResponse解决编码问题
        final jsonData = HttpUtils.decodeResponse(response);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> meetingsData = jsonData['data'];
          final currentTime = DateTime.now();

          // 将API返回的会议记录转换为Meeting对象列表
          return meetingsData.map<Meeting>((record) {
            // 解析会议状态
            MeetingStatus meetingStatus = _parseMeetingStatus(
              record['status'] ?? '待开始',
            );

            // 解析开始和结束时间
            final startTime = DateTime.parse(record['startTime']);
            final endTime = DateTime.parse(record['endTime']);

            // 根据当前时间更新会议状态
            // 如果当前时间在会议开始和结束时间之间，将状态设为"进行中"
            if (currentTime.isAfter(startTime) &&
                currentTime.isBefore(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.ongoing;
            }
            // 如果当前时间超过会议结束时间，将状态设为"已结束"
            else if (currentTime.isAfter(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.completed;
            }

            return Meeting(
              id: record['meetingId'].toString(),
              title: record['title'],
              startTime: startTime,
              endTime: endTime,
              location: record['location'] ?? '',
              status: meetingStatus,
              type: MeetingType.regular, // 默认为常规会议
              visibility: MeetingVisibility.private, // 私密会议
              organizerId: record['organizerId'].toString(),
              organizerName: '', // API未提供组织者名称
              description: record['description'],
              createdAt: DateTime.parse(record['createdAt']),
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('获取我的私密会议失败: $e');
      rethrow;
    }
  }

  @override
  Future<String> submitLeaveRequest(
    String userId,
    String meetingId,
    String reason,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/leave/submit'),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode({
          'userId': userId,
          'meetingId': meetingId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          return responseData['data'] ?? '请假申请提交成功';
        } else {
          final message = responseData['message'] ?? '提交请假申请失败';
          throw Exception(message);
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '提交请假申请请求失败'),
        );
      }
    } catch (e) {
      throw Exception('提交请假申请时出错: $e');
    }
  }

  @override
  Future<List<Meeting>> searchPrivateMeetings(
    String userId,
    String title,
  ) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/meeting/searchPrivate/$userId';
      final uri = Uri.parse(
        url,
      ).replace(queryParameters: title.isNotEmpty ? {'title': title} : null);

      final response = await _client.get(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = HttpUtils.decodeResponse(response);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> meetingsData = jsonData['data'];
          final currentTime = DateTime.now();

          return meetingsData.map<Meeting>((record) {
            // 解析会议状态
            MeetingStatus meetingStatus = _parseMeetingStatus(
              record['status'] ?? '待开始',
            );

            // 解析开始和结束时间
            final startTime = DateTime.parse(record['startTime']);
            final endTime = DateTime.parse(record['endTime']);

            // 根据当前时间更新会议状态
            // 如果当前时间在会议开始和结束时间之间，将状态设为"进行中"
            if (currentTime.isAfter(startTime) &&
                currentTime.isBefore(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.ongoing;
            }
            // 如果当前时间超过会议结束时间，将状态设为"已结束"
            else if (currentTime.isAfter(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.completed;
            }

            return Meeting(
              id: record['meetingId'].toString(),
              title: record['title'],
              startTime: startTime,
              endTime: endTime,
              location: record['location'] ?? '',
              status: meetingStatus,
              type: MeetingType.regular, // 默认为常规会议
              visibility: MeetingVisibility.private, // 私密会议
              organizerId: record['organizerId'].toString(),
              organizerName: record['organizerName'] ?? '',
              description: record['description'],
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('搜索私有会议失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<Meeting>> searchPublicMeetings(
    String userId,
    String title,
  ) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/meeting/searchPublic/$userId';
      final uri = Uri.parse(
        url,
      ).replace(queryParameters: title.isNotEmpty ? {'title': title} : null);

      final response = await _client.get(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = HttpUtils.decodeResponse(response);

        if (jsonData['code'] == 200 && jsonData['data'] != null) {
          final List<dynamic> meetingsData = jsonData['data'];
          final currentTime = DateTime.now();

          return meetingsData.map<Meeting>((record) {
            // 解析会议状态
            MeetingStatus meetingStatus = _parseMeetingStatus(
              record['status'] ?? '待开始',
            );

            // 解析开始和结束时间
            final startTime = DateTime.parse(record['startTime']);
            final endTime = DateTime.parse(record['endTime']);

            // 根据当前时间更新会议状态
            // 如果当前时间在会议开始和结束时间之间，将状态设为"进行中"
            if (currentTime.isAfter(startTime) &&
                currentTime.isBefore(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.ongoing;
            }
            // 如果当前时间超过会议结束时间，将状态设为"已结束"
            else if (currentTime.isAfter(endTime) &&
                meetingStatus != MeetingStatus.cancelled) {
              meetingStatus = MeetingStatus.completed;
            }

            MeetingType meetingType = MeetingType.regular;
            // 尝试解析会议类型
            if (record['meetingType'] != null) {
              if (record['meetingType'] == '培训会议') {
                meetingType = MeetingType.training;
              } else if (record['meetingType'] == '面试会议') {
                meetingType = MeetingType.interview;
              } else if (record['meetingType'] == '其他') {
                meetingType = MeetingType.other;
              }
            }

            return Meeting(
              id: record['meetingId'].toString(),
              title: record['title'],
              startTime: startTime,
              endTime: endTime,
              location: record['location'] ?? '',
              status: meetingStatus,
              type: meetingType,
              visibility: MeetingVisibility.public, // 公开会议
              organizerId: record['organizerId'].toString(),
              organizerName: record['organizerName'] ?? '',
              description: record['description'],
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('搜索公有会议失败: $e');
      rethrow;
    }
  }
}

// 添加全局作用域的锁机制，防止并发验证
class _Lock {
  bool _locked = false;
  final _completer = Completer<void>();

  bool get isLocked => _locked;

  Future<void> acquire() async {
    if (_locked) {
      // 等待锁释放
      await _completer.future;
      // 递归调用获取锁
      return acquire();
    }
    // 获取锁
    _locked = true;
  }

  void release() {
    if (!_locked) return;
    _locked = false;
    // 如果有等待的Completer，完成它
    if (!_completer.isCompleted) {
      final oldCompleter = _completer;
      oldCompleter.complete();
    }
  }
}

// 创建针对每个会议ID的锁实例
final Map<String, _Lock> _meetingLocks = {};

// 获取指定会议的锁
_Lock _getLockForMeeting(String meetingId) {
  if (!_meetingLocks.containsKey(meetingId)) {
    _meetingLocks[meetingId] = _Lock();
  }
  return _meetingLocks[meetingId]!;
}

// 添加辅助函数将可见性字符串转换为枚举值
MeetingVisibility _parseMeetingVisibility(String? visibilityStr) {
  if (visibilityStr == null || visibilityStr.isEmpty) {
    return MeetingVisibility.public; // 默认值
  }

  switch (visibilityStr.toUpperCase()) {
    case 'PRIVATE':
      return MeetingVisibility.private;
    case 'PUBLIC':
    default:
      return MeetingVisibility.public;
  }
}
