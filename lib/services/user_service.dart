import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

/// 用户服务接口
abstract class UserService {
  /// 获取当前用户信息
  Future<User?> getCurrentUser();

  /// 更新用户信息
  Future<User> updateUserInfo(User user);

  /// 保存用户信息到本地
  Future<void> saveUserToLocal(User user);

  /// 从本地获取用户信息
  Future<User?> getUserFromLocal();

  /// 清除本地用户信息
  Future<void> clearUserFromLocal();
}

/// 模拟用户服务实现
class MockUserService implements UserService {
  // 模拟用户数据
  final User _mockUser = const User(
    id: 'user1',
    name: '张三',
    email: 'zhangsan@example.com',
    department: '技术部',
    position: '开发工程师',
    phoneNumber: '13800138000',
  );

  @override
  Future<User?> getCurrentUser() async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockUser;
  }

  @override
  Future<User> updateUserInfo(User user) async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 1000));
    // 返回更新后的用户信息
    return user.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<void> saveUserToLocal(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'avatarUrl': user.avatarUrl,
      'department': user.department,
      'position': user.position,
      'phoneNumber': user.phoneNumber,
    });
    await prefs.setString(AppConstants.userKey, userJson);
  }

  @override
  Future<User?> getUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;

    try {
      final Map<String, dynamic> userData = jsonDecode(userJson);
      return User(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        avatarUrl: userData['avatarUrl'],
        department: userData['department'],
        position: userData['position'],
        phoneNumber: userData['phoneNumber'],
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearUserFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
  }
}
