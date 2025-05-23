import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async'; // 添加async支持
import 'package:flutter/foundation.dart'; // 添加debugPrint支持
import '../models/meeting.dart';
import '../models/meeting_recommendation.dart';
import '../models/user.dart';
import '../services/meeting_service.dart';
import 'user_providers.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';

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

/// 全局缓存提供者，用于跨provider共享缓存数据
final globalCacheProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// 会议列表提供者
@riverpod
Future<List<Meeting>> meetingList(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  try {
    return await meetingService.getMeetings();
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    debugPrint('获取会议列表失败: $e');
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
    debugPrint('获取会议详情失败: $e');
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
    debugPrint('获取我的会议列表失败: $e');
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
    debugPrint('获取到${managers.length}个管理员');
    return managers;
  } catch (e) {
    debugPrint('获取管理员列表出错: $e');
    rethrow;
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
    debugPrint('开始新的密码验证: $validationKey');

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

      debugPrint('密码验证完成: $validationKey, 结果: $validationResult');

      // 只有在验证成功后才更新状态
      if (state is AsyncLoading) {
        // 只有在仍然处于Loading状态时才更新
        state = AsyncValue.data(validationResult);
      } else {
        debugPrint('警告: 状态已被其他操作更改，不更新结果');
      }

      // 返回验证结果
      return validationResult;
    } catch (e, stackTrace) {
      // 捕获并记录错误
      debugPrint('密码验证失败: $validationKey, 错误: $e');

      // 设置错误状态
      if (state is AsyncLoading) {
        // 只有在仍然处于Loading状态时才更新错误
        state = AsyncValue.error(e, stackTrace);
      }

      // 向上抛出异常
      rethrow;
    } finally {
      debugPrint('完成密码验证过程: $validationKey');
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
        debugPrint('获取签到状态失败: ${responseData['message']}');
        return '未签到';
      }
    } else {
      debugPrint('获取签到状态请求失败: ${response.statusCode}');
      return '未签到';
    }
  } catch (e) {
    debugPrint('获取签到状态出错: $e');
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
      debugPrint('签到失败: $e');
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
Future<List<MeetingRecommendation>> recommendedMeetings(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  try {
    return await meetingService.getRecommendedMeetings(userId);
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    debugPrint('获取推荐会议失败: $e');
    return [];
  }
}

/// 我的私密会议列表提供者
@riverpod
Future<List<Meeting>> myPrivateMeetings(Ref ref) async {
  final meetingService = ref.watch(meetingServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  try {
    return await meetingService.getMyPrivateMeetings(userId);
  } catch (e) {
    // 记录错误但返回空列表，防止应用崩溃
    debugPrint('获取我的私密会议失败: $e');
    return [];
  }
}

/// 获取会议黑名单列表
@riverpod
Future<List<dynamic>> blacklistMembers(Ref ref, String meetingId) async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/blacklist/list/$meetingId'),
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] == 200 && responseData['data'] != null) {
        return responseData['data'] as List<dynamic>;
      } else {
        throw Exception(responseData['message'] ?? '获取黑名单列表失败');
      }
    } else {
      throw Exception(
        HttpUtils.extractErrorMessage(response, defaultMessage: '获取黑名单列表请求失败'),
      );
    }
  } catch (e) {
    throw Exception('获取黑名单列表时出错: $e');
  }
}

/// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
@riverpod
Future<bool> isUserInBlacklist(Ref ref, String meetingId, String userId) async {
  // autoDispose注解会自动添加（由riverpod_generator生成）
  // 确保每次使用都会重新请求

  // 额外添加一个时间戳依赖，以确保每次都是新请求
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  ref.keepAlive(); // 主动保持这个provider直到请求完成

  try {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/blacklist/check').replace(
      queryParameters: {
        'meetingId': meetingId,
        'userId': userId,
        '_t': timestamp.toString(), // 添加时间戳防止缓存
      },
    );

    final response = await http.get(uri, headers: HttpUtils.createHeaders());

    if (response.statusCode == 200) {
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] == 200) {
        debugPrint('获取到最新黑名单状态[$timestamp]: ${responseData['data']}');
        return responseData['data'] as bool;
      } else {
        throw Exception(responseData['message'] ?? '检查黑名单状态失败');
      }
    } else {
      throw Exception(
        HttpUtils.extractErrorMessage(response, defaultMessage: '检查黑名单状态请求失败'),
      );
    }
  } catch (e) {
    debugPrint('检查黑名单状态时出错: $e');
    throw Exception('检查黑名单状态时出错: $e');
  }
}

// 添加一个新的Provider，用于获取用户在特定会议中的角色
final userMeetingRoleProvider = FutureProvider.family<
  MeetingPermission,
  Map<String, String>
>((ref, params) async {
  final meetingId = params['meetingId'];
  final userId = params['userId'];

  if (meetingId == null ||
      userId == null ||
      meetingId.isEmpty ||
      userId.isEmpty) {
    return MeetingPermission.participant;
  }

  try {
    // 强制刷新会议详情
    ref.invalidate(meetingDetailProvider(meetingId));

    // 获取最新的会议详情
    final meeting = await ref.watch(meetingDetailProvider(meetingId).future);

    // 记录详细日志
    debugPrint('======用户角色检查======');
    debugPrint('meetingId: $meetingId, userId: $userId');
    debugPrint('创建者ID: ${meeting.organizerId}');
    debugPrint('管理员列表: ${meeting.admins}');

    // 判断用户角色
    if (meeting.organizerId == userId) {
      debugPrint('用户是创建者');
      return MeetingPermission.creator;
    } else if (meeting.admins.contains(userId)) {
      debugPrint('用户是管理员');
      return MeetingPermission.admin;
    } else if (meeting.blacklist.contains(userId)) {
      debugPrint('用户已被封禁');
      return MeetingPermission.blocked;
    } else {
      debugPrint('用户是普通参与者');
      return MeetingPermission.participant;
    }
  } catch (e) {
    debugPrint('获取用户角色时出错: $e');
    return MeetingPermission.participant;
  }
});

// 添加缓存，避免重复请求的provider
final directUserRoleProvider = FutureProvider.family<
  MeetingPermission,
  Map<String, String>
>((ref, params) async {
  // 添加keepAlive确保结果被缓存
  ref.keepAlive();

  final meetingId = params['meetingId'];
  final userId = params['userId'];

  // 添加防重复请求标记
  final cacheKey = '${meetingId}_${userId}_role';
  final cache = ref.read(globalCacheProvider);

  // 如果缓存中有数据且未超时，直接返回缓存数据
  if (cache.containsKey(cacheKey) &&
      DateTime.now().difference(cache[cacheKey]['timestamp']).inSeconds < 30) {
    debugPrint('从缓存获取用户角色: $cacheKey');
    return cache[cacheKey]['role'] as MeetingPermission;
  }

  if (meetingId == null ||
      userId == null ||
      meetingId.isEmpty ||
      userId.isEmpty) {
    return MeetingPermission.participant;
  }

  try {
    // 直接调用API获取最新会议参与者数据
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/meeting/$meetingId/participants'),
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      final responseData = HttpUtils.decodeResponse(response);

      if (responseData['code'] == 200 && responseData['data'] != null) {
        final participants = responseData['data'] as List<dynamic>;

        debugPrint('=====直接API请求参与者数据=====');
        debugPrint('会议ID: $meetingId, 用户ID: $userId');
        debugPrint('参与者数量: ${participants.length}');

        // 查找当前用户的角色
        for (final participant in participants) {
          // 将API返回的用户ID转换为字符串进行比较
          final participantId = participant['user_id'].toString();
          final role = participant['role'] as String? ?? 'PARTICIPANT';

          debugPrint('比较: API用户ID($participantId) vs 当前用户ID($userId)');

          if (participantId == userId) {
            debugPrint('找到当前用户，角色: $role');

            // 根据API返回的角色映射到枚举
            MeetingPermission permission;
            switch (role) {
              case 'HOST':
                permission = MeetingPermission.creator;
                break;
              case 'ADMIN':
                permission = MeetingPermission.admin;
                break;
              case 'PARTICIPANT':
                permission = MeetingPermission.participant;
                break;
              default:
                permission = MeetingPermission.participant;
            }

            // 将结果存入缓存
            cache[cacheKey] = {'role': permission, 'timestamp': DateTime.now()};

            return permission;
          }
        }

        debugPrint('在参与者列表中未找到当前用户');
      }
    }

    // 如果通过参与者接口没有找到角色，再尝试通过会议详情接口
    final detailResponse = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/meeting/$meetingId'),
      headers: HttpUtils.createHeaders(),
    );

    if (detailResponse.statusCode == 200) {
      final detailData = HttpUtils.decodeResponse(detailResponse);

      if (detailData['code'] == 200 && detailData['data'] != null) {
        final data = detailData['data'];

        // 获取创建者ID
        final organizerId = data['organizer_id']?.toString() ?? '';

        // 检查用户是否为创建者
        if (organizerId == userId) {
          debugPrint('用户 $userId 是会议创建者(通过会议详情API)');
          final permission = MeetingPermission.creator;

          // 将结果存入缓存
          cache[cacheKey] = {'role': permission, 'timestamp': DateTime.now()};

          return permission;
        }

        // 获取管理员列表
        final admins = data['admins'] ?? [];

        if (admins is List) {
          // 管理员可能是对象列表
          if (admins.isNotEmpty && admins.first is Map) {
            // 转换为ID列表
            final adminIds =
                admins.map((admin) => admin['user_id'].toString()).toList();
            // 检查用户是否为管理员
            if (adminIds.contains(userId)) {
              debugPrint('用户 $userId 是会议管理员(通过会议详情API)');
              final permission = MeetingPermission.admin;

              // 将结果存入缓存
              cache[cacheKey] = {
                'role': permission,
                'timestamp': DateTime.now(),
              };

              return permission;
            }
          }
          // 管理员可能是字符串列表
          else if (admins.isNotEmpty) {
            // 将所有元素转换为字符串进行比较
            final adminIds = admins.map((admin) => admin.toString()).toList();
            if (adminIds.contains(userId)) {
              debugPrint('用户 $userId 是会议管理员(通过会议详情API)');
              final permission = MeetingPermission.admin;

              // 将结果存入缓存
              cache[cacheKey] = {
                'role': permission,
                'timestamp': DateTime.now(),
              };

              return permission;
            }
          }
        }

        // 检查黑名单
        final blacklist = data['blacklist'] ?? [];
        if (blacklist is List) {
          final blacklistIds = blacklist.map((id) => id.toString()).toList();
          if (blacklistIds.contains(userId)) {
            debugPrint('用户 $userId 在黑名单中(通过会议详情API)');
            final permission = MeetingPermission.blocked;

            // 将结果存入缓存
            cache[cacheKey] = {'role': permission, 'timestamp': DateTime.now()};

            return permission;
          }
        }
      }
    }

    // 默认为参与者
    debugPrint('用户 $userId 是普通参与者(默认值)');
    final permission = MeetingPermission.participant;

    // 将结果存入缓存
    cache[cacheKey] = {'role': permission, 'timestamp': DateTime.now()};

    return permission;
  } catch (e) {
    debugPrint('直接获取用户角色失败: $e');
    return MeetingPermission.participant;
  }
});
