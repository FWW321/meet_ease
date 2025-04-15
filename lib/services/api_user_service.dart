import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import 'user_service.dart';

/// API用户服务实现
class ApiUserService implements UserService {
  final http.Client _client = http.Client();

  @override
  Future<User?> getCurrentUser() async {
    return getUserFromLocal();
  }

  @override
  Future<User> getUserById(String userId) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.apiBaseUrl}/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      return User(
        id: userData['id'],
        name: userData['username'],
        email: userData['email'],
        phoneNumber: userData['phone'],
      );
    } else {
      throw Exception('获取用户信息失败: ${response.statusCode}');
    }
  }

  @override
  Future<User> updateUserInfo(User user) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.apiBaseUrl}/user/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user.name,
        'email': user.email,
        'phone': user.phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final updatedUser = User(
        id: userData['id'],
        name: userData['username'],
        email: userData['email'],
        phoneNumber: userData['phone'],
      );
      await saveUserToLocal(updatedUser);
      return updatedUser;
    } else {
      throw Exception('更新用户信息失败: ${response.statusCode}');
    }
  }

  @override
  Future<User> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.apiBaseUrl}/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final user = User(
        id: userData['id'],
        name: userData['username'],
        email: userData['email'],
        phoneNumber: userData['phone'],
      );
      await saveUserToLocal(user);
      return user;
    } else {
      throw Exception('登录失败: ${response.statusCode}');
    }
  }

  @override
  Future<User> register(
    String username,
    String password,
    String email,
    String phone,
    int roleId,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'phone': phone,
          'roleId': roleId,
        }),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final user = User(
          id: userData['id'] ?? '',
          name: username,
          email: email,
          phoneNumber: phone,
        );
        await saveUserToLocal(user);
        return user;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? '注册失败: ${response.statusCode}',
          );
        } catch (e) {
          throw Exception('注册失败: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('无法连接到服务器(${AppConstants.apiDomain})，请检查服务器是否运行或网络连接');
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
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
