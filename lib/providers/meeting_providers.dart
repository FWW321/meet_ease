import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async'; // 添加async支持
import '../models/meeting.dart';
import '../models/meeting_recommendation.dart';
import '../models/user.dart';
import '../services/meeting_service.dart';
import 'user_providers.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';
import '../models/meeting_participation.dart';

part 'meeting_providers.g.dart';

// HTTP客户端提供者
final apiClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// 会议服务提供者 - 用于获取会议服务实例
final meetingServiceProvider = Provider<MeetingService>((ref) {
  // 使用真实API服务从服务器获取数据
  return ApiMeetingService(ref);
});

/// 会议列表提供者
@riverpod
Future<List<Meeting>> meetingList(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  try {
    return await meetingService.getMeetings();
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    print('获取会议列表失败: $e');
    return [];
  }
}

/// 会议详情提供者
@riverpod
Future<Meeting> meetingDetail(Ref ref, String meetingId) async {
  final meetingService = ref.watch(meetingServiceProvider);
  try {
    return await meetingService.getMeetingById(meetingId);
  } catch (e) {
    // 记录错误并重新抛出，因为详情页面需要显示错误状态
    print('获取会议详情失败: $e');
    throw Exception('无法加载会议详情: $e');
  }
}

/// 我的会议提供者 (我参与的会议)
@riverpod
Future<List<Meeting>> myMeetings(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  try {
    return await meetingService.getMyMeetings();
  } catch (e) {
    // 记录错误并重新抛出，以便UI可以显示错误
    print('获取我的会议列表失败: $e');
    throw Exception('无法加载我的会议列表: $e');
  }
}

/// 搜索会议提供者
@riverpod
Future<List<Meeting>> searchMeetings(Ref ref, String query) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.searchMeetings(query);
}

/// 搜索私有会议提供者
@riverpod
Future<List<Meeting>> searchPrivateMeetings(Ref ref, String query) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  return meetingService.searchPrivateMeetings(userId, query);
}

/// 搜索公有会议提供者
@riverpod
Future<List<Meeting>> searchPublicMeetings(Ref ref, String query) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  return meetingService.searchPublicMeetings(userId, query);
}

/// 会议参与者提供者
@riverpod
Future<List<User>> meetingParticipants(Ref ref, String meetingId) async {
  final meetingService = ref.watch(meetingServiceProvider);
  return meetingService.getMeetingParticipants(meetingId);
}

/// 会议管理员列表提供者
@riverpod
Future<List<User>> meetingManagers(Ref ref, String meetingId) async {
  // 将请求包装在keepAliveLink中以便能实现强制刷新
  ref.keepAlive();

  final meetingService = ref.watch(meetingServiceProvider);
  try {
    final managers = await meetingService.getMeetingManagers(meetingId);
    print('获取到${managers.length}个管理员');
    return managers;
  } catch (e) {
    print('获取管理员列表出错: $e');
    throw e;
  }
}

/// 创建会议提供者
@riverpod
class CreateMeeting extends _$CreateMeeting {
  @override
  FutureOr<Meeting?> build() {
    // 初始状态为null，表示没有创建会议
    return null;
  }

  Future<Meeting> create({
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
    state = const AsyncValue.loading();

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final meeting = await meetingService.createMeeting(
        title: title,
        startTime: startTime,
        endTime: endTime,
        location: location,
        type: type,
        visibility: visibility,
        description: description,
        allowedUsers: allowedUsers,
        password: password,
      );

      // 创建成功后更新状态
      state = AsyncValue.data(meeting);

      // 刷新相关提供者
      ref.invalidate(meetingListProvider);

      return meeting;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// 验证会议密码提供者
@riverpod
class ValidateMeetingPassword extends _$ValidateMeetingPassword {
  @override
  FutureOr<bool?> build(String meetingId) {
    // 初始状态为null，表示未验证密码
    return null;
  }

  // 验证密码 - 完全重构以避免状态冲突问题
  Future<bool> validate(String password) async {
    // 用一个确定性的key标记此次验证
    final validationKey =
        '${meetingId}_${DateTime.now().millisecondsSinceEpoch}';
    print('开始新的密码验证: $validationKey');

    // 先将状态设为null，避免状态冲突
    ref.invalidateSelf();

    // 设置为加载状态
    state = const AsyncValue.loading();

    // 使用本地变量存储结果，避免状态竞争
    bool validationResult;

    try {
      // 获取会议服务实例
      final meetingService = ref.read(meetingServiceProvider);

      // 调用验证方法并添加超时处理
      validationResult = await meetingService
          .validateMeetingPassword(meetingId, password)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('验证密码请求超时'),
          );

      print('密码验证完成: $validationKey, 结果: $validationResult');

      // 只有在验证成功后才更新状态
      if (state is AsyncLoading) {
        // 只有在仍然处于Loading状态时才更新
        state = AsyncValue.data(validationResult);
      } else {
        print('警告: 状态已被其他操作更改，不更新结果');
      }

      // 返回验证结果
      return validationResult;
    } catch (e, stackTrace) {
      // 捕获并记录错误
      print('密码验证失败: $validationKey, 错误: $e');

      // 设置错误状态
      if (state is AsyncLoading) {
        // 只有在仍然处于Loading状态时才更新错误
        state = AsyncValue.error(e, stackTrace);
      }

      // 向上抛出异常
      rethrow;
    } finally {
      print('完成密码验证过程: $validationKey');
    }
  }
}

/// 会议签到提供者
@riverpod
class MeetingSignIn extends _$MeetingSignIn {
  @override
  FutureOr<bool> build(String meetingId) async {
    // 获取当前会议的签到状态
    final meetingService = ref.watch(meetingServiceProvider);
    final meeting = await meetingService.getMeetingById(meetingId);
    return meeting.isSignedIn;
  }

  // 签到方法
  Future<void> signIn() async {
    state = const AsyncValue.loading();

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final result = await meetingService.signInMeeting(meetingId);

      // 签到成功后，更新状态并刷新其他相关提供者
      state = AsyncValue.data(result);

      // 刷新相关提供者
      ref.invalidate(meetingDetailProvider(meetingId));
      ref.invalidate(myMeetingsProvider);

      // 刷新直接从API获取的签到状态
      ref.invalidate(meetingSignInStatusProvider(meetingId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// 手动创建签到状态提供者，用于替代 @riverpod 注解无法正常生成代码的情况
final meetingSignInStatusProvider = FutureProvider.family<String, String>((
  ref,
  meetingId,
) async {
  try {
    // 获取当前用户ID
    final userId = await ref.read(currentUserIdProvider.future);

    if (userId.isEmpty) {
      return '未签到';
    }

    // 获取会议详情，检查是否为私有会议
    final meetingDetail = await ref.read(
      meetingDetailProvider(meetingId).future,
    );

    // 如果不是私有会议，直接返回不支持签到
    if (meetingDetail.visibility != MeetingVisibility.private) {
      return '不支持签到';
    }

    final client = ref.read(apiClientProvider);

    // 创建请求URL，添加查询参数
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/signin/status',
    ).replace(queryParameters: {'meetingId': meetingId, 'userId': userId});

    // 发起GET请求
    final response = await client.get(uri, headers: HttpUtils.createHeaders());

    if (response.statusCode == 200) {
      final responseData = HttpUtils.decodeResponse(response);

      // 检查响应码
      if (responseData['code'] == 200) {
        // 返回签到状态
        return responseData['data'] as String? ?? '未签到';
      } else {
        print('获取签到状态失败: ${responseData['message']}');
        return '未签到';
      }
    } else {
      print('获取签到状态请求失败: ${response.statusCode}');
      return '未签到';
    }
  } catch (e) {
    print('获取签到状态出错: $e');
    return '未签到';
  }
});

// 签到操作提供者
final meetingSignInOperationProvider =
    Provider.family<MeetingSignInOperation, String>((ref, meetingId) {
      return MeetingSignInOperation(ref, meetingId);
    });

// 签到操作类
class MeetingSignInOperation {
  final Ref ref;
  final String meetingId;

  MeetingSignInOperation(this.ref, this.meetingId);

  // 签到方法
  Future<bool> signIn() async {
    try {
      // 获取当前用户ID
      final userId = await ref.read(currentUserIdProvider.future);

      if (userId.isEmpty) {
        throw Exception('用户未登录，无法签到');
      }

      // 获取会议详情，检查是否为私有会议
      final meetingDetail = await ref.read(
        meetingDetailProvider(meetingId).future,
      );

      // 验证会议是否为私有会议
      if (meetingDetail.visibility != MeetingVisibility.private) {
        throw Exception('只有私有会议支持签到功能');
      }

      final client = ref.read(apiClientProvider);

      // 创建请求URL，添加查询参数
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/signin/submit',
      ).replace(queryParameters: {'meetingId': meetingId, 'userId': userId});

      // 发起POST请求
      final response = await client.post(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);

        // 检查响应码
        if (responseData['code'] == 200) {
          // 刷新相关提供者
          ref.invalidate(meetingSignInStatusProvider(meetingId));
          ref.invalidate(meetingDetailProvider(meetingId));
          ref.invalidate(myMeetingsProvider);
          ref.invalidate(meetingSignInProvider(meetingId));

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
      print('签到失败: $e');
      throw Exception('签到时出错: $e');
    }
  }
}

/// 会议管理操作提供者
@riverpod
class MeetingOperations extends _$MeetingOperations {
  @override
  AsyncValue<Meeting?> build() {
    // 初始状态为未加载
    return const AsyncValue.data(null);
  }

  // 取消会议
  Future<Meeting> cancelMeeting(String meetingId, String creatorId) async {
    state = const AsyncValue.loading();

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final meeting = await meetingService.cancelMeeting(meetingId, creatorId);

      // 更新状态
      state = AsyncValue.data(meeting);

      // 刷新相关数据
      ref.invalidate(meetingListProvider);
      ref.invalidate(meetingDetailProvider(meetingId));

      return meeting;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // 结束会议
  Future<Meeting> endMeeting(String meetingId, String creatorId) async {
    state = const AsyncValue.loading();

    try {
      final meetingService = ref.read(meetingServiceProvider);
      final meeting = await meetingService.endMeeting(meetingId, creatorId);

      // 更新状态
      state = AsyncValue.data(meeting);

      // 刷新相关数据
      ref.invalidate(meetingListProvider);
      ref.invalidate(meetingDetailProvider(meetingId));

      return meeting;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// 推荐会议列表提供者
@riverpod
Future<List<MeetingRecommendation>> recommendedMeetings(
  RecommendedMeetingsRef ref,
) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  try {
    return await meetingService.getRecommendedMeetings(userId);
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    print('获取推荐会议失败: $e');
    return [];
  }
}

/// 我的私密会议列表提供者
@riverpod
Future<List<Meeting>> myPrivateMeetings(MyPrivateMeetingsRef ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  try {
    return await meetingService.getMyPrivateMeetings(userId);
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    print('获取我的私密会议失败: $e');
    return [];
  }
}
