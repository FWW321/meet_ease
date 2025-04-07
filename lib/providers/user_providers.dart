import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

part 'user_providers.g.dart';

/// 用户服务提供者 - 用于获取用户服务实例
final userServiceProvider = Provider<UserService>((ref) {
  // 目前返回模拟服务，后续可替换为真实API服务
  return MockUserService();
});

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
String currentUserId(Ref ref) {
  // 目前返回固定值，实际应用中应该从本地存储或会话中获取
  return 'user1';
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
  Future<void> login(String email, String password) async {
    state = false; // 临时设置为未登录状态

    try {
      final userService = ref.read(userServiceProvider);
      await userService.login(email, password);

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
    // 首先尝试从本地获取
    final userService = ref.watch(userServiceProvider);
    User? user = await userService.getUserFromLocal();

    // 如果本地没有，尝试从远程获取
    if (user == null) {
      user = await userService.getCurrentUser();
      // 如果获取到用户，保存到本地
      if (user != null) {
        await userService.saveUserToLocal(user);
      }
    }

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
