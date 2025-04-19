import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

/// 用户服务接口
abstract class UserService {
  /// 获取当前用户信息
  Future<User?> getCurrentUser();

  /// 根据ID获取用户信息
  Future<User> getUserById(String userId);

  /// 更新用户信息
  Future<User> updateUserInfo(User user);

  /// 用户登录
  Future<User> login(String email, String password);

  /// 用户注册
  Future<User> register(
    String username,
    String password,
    String email,
    String phone,
  );

  /// 用户登出
  Future<void> logout();

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

  // 模拟多个用户
  final List<User> _users = [
    User(
      id: 'user1',
      name: '张三',
      email: 'zhangsan@example.com',
      department: '技术部',
      position: '开发工程师',
    ),
    User(
      id: 'user2',
      name: '李四',
      email: 'lisi@example.com',
      department: '产品部',
      position: '产品经理',
    ),
    User(
      id: 'user3',
      name: '王五',
      email: 'wangwu@example.com',
      department: '设计部',
      position: 'UI设计师',
    ),
    User(
      id: 'user4',
      name: '赵六',
      email: 'zhaoliu@example.com',
      department: '市场部',
      position: '市场专员',
    ),
    User(
      id: 'user5',
      name: '孙七',
      email: 'sunqi@example.com',
      department: '人事部',
      position: 'HR专员',
    ),
    User(
      id: 'user6',
      name: '周八',
      email: 'zhouba@example.com',
      department: '技术部',
      position: '测试工程师',
    ),
    User(
      id: 'user7',
      name: '吴九',
      email: 'wujiu@example.com',
      department: '技术部',
      position: '架构师',
    ),
    User(
      id: 'user8',
      name: '郑十',
      email: 'zhengshi@example.com',
      department: '财务部',
      position: '会计',
    ),
  ];

  @override
  Future<User?> getCurrentUser() async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockUser;
  }

  @override
  Future<User> getUserById(String userId) async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 查找用户
    final user = _users.firstWhere(
      (user) => user.id == userId,
      orElse: () => throw Exception('用户不存在'),
    );

    return user;
  }

  @override
  Future<User> updateUserInfo(User user) async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 1000));
    // 返回更新后的用户信息
    return user.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<User> login(String email, String password) async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 1000));

    // 模拟登录验证
    if (email.isEmpty || password.isEmpty) {
      throw Exception('邮箱或密码不能为空');
    }

    // 模拟找到对应用户
    final user = _users.firstWhere(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('用户不存在'),
    );

    // 保存到本地
    await saveUserToLocal(user);

    return user;
  }

  @override
  Future<User> register(
    String username,
    String password,
    String email,
    String phone,
  ) async {
    // Implementation needed
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 清除本地用户信息
    await clearUserFromLocal();
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
