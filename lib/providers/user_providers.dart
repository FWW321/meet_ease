import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

part 'user_providers.g.dart';

/// 用户服务提供者 - 用于获取用户服务实例
final userServiceProvider = Provider<UserService>((ref) {
  // 使用服务提供者中定义的API服务
  return ApiUserService();
});

/// 当前登录用户ID，用于在搜索和选择时排除
final currentLoggedInUserIdProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final userService = ref.watch(userServiceProvider);
  final user = await userService.getUserFromLocal();
  return user?.id ?? '';
});

/// 用户搜索提供者
@riverpod
Future<List<User>> searchUsers(
  Ref ref, {
  String? username,
  String? email,
  String? phone,
  String? userId,
}) async {
  final userService = ref.watch(userServiceProvider);
  return userService.searchUsers(
    username: username,
    email: email,
    phone: phone,
    userId: userId,
  );
}

/// 用户搜索状态提供者
@riverpod
class UserSearch extends _$UserSearch {
  @override
  FutureOr<List<User>> build() {
    return const []; // 初始为空列表
  }

  // 搜索用户
  Future<void> search({
    String? username,
    String? email,
    String? phone,
    String? userId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final userService = ref.read(userServiceProvider);
      final users = await userService.searchUsers(
        username: username,
        email: email,
        phone: phone,
        userId: userId,
      );
      state = AsyncValue.data(users);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 清空搜索结果
  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// 当前用户提供者
@riverpod
Future<User?> currentUser(Ref ref) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getCurrentUser();
}

/// 用户详情提供者
@riverpod
Future<User> user(Ref ref, String userId) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserById(userId);
}

/// 当前用户ID提供者 (通常从本地存储或会话中获取)
@riverpod
Future<String> currentUserId(Ref ref) async {
  final userService = ref.watch(userServiceProvider);
  final user = await userService.getUserFromLocal();
  // 如果找不到用户，返回空字符串
  return user?.id ?? '';
}

/// 用户登录状态提供者
@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() {
    // 初始状态，通常从本地存储中加载
    return false;
  }

  // 登录方法
  Future<void> login(String username, String password) async {
    state = false; // 临时设置为未登录状态

    try {
      final userService = ref.read(userServiceProvider);
      await userService.login(username, password);

      // 登录成功
      state = true;

      // 刷新当前用户信息
      ref.invalidate(currentUserProvider);
    } catch (e) {
      // 登录失败
      rethrow;
    }
  }

  // 登出方法
  Future<void> logout() async {
    try {
      final userService = ref.read(userServiceProvider);
      await userService.logout();

      // 登出成功
      state = false;
    } catch (e) {
      // 登出失败
      rethrow;
    }
  }
}

/// 用户信息提供者
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  FutureOr<User?> build() async {
    // 监听认证状态变化
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) {
        // 如果认证状态发生变化，刷新用户数据
        ref.invalidateSelf();
      }
    });

    // 首先尝试从本地获取
    final userService = ref.watch(userServiceProvider);
    User? user = await userService.getUserFromLocal();

    return user;
  }

  // 更新用户信息
  Future<void> updateUser(User updatedUser) async {
    state = const AsyncValue.loading();

    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.updateUserInfo(updatedUser);

      // 更新本地存储
      await userService.saveUserToLocal(user);

      // 更新状态
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // 清除用户信息
  Future<void> clearUser() async {
    state = const AsyncValue.loading();

    try {
      final userService = ref.read(userServiceProvider);
      await userService.clearUserFromLocal();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// 用户名提供者 - 通过用户ID获取用户名
@riverpod
Future<String> userName(Ref ref, String userId) async {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserNameById(userId);
}
