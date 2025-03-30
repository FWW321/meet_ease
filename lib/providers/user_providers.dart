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
