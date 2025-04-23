import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';
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
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      final userData = HttpUtils.decodeResponse(response);
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

  /// 搜索用户
  @override
  Future<List<User>> searchUsers({
    String? username,
    String? email,
    String? phone,
    String? userId,
  }) async {
    // 构建查询参数
    final queryParameters = <String, String>{};
    if (username != null && username.isNotEmpty) {
      queryParameters['username'] = username;
    }
    if (email != null && email.isNotEmpty) {
      queryParameters['email'] = email;
    }
    if (phone != null && phone.isNotEmpty) {
      queryParameters['phone'] = phone;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParameters['userId'] = userId;
    }

    // 构建请求URL
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/user/search',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        uri,
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final userResponse = UserSearchResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );

        // 转换为应用内用户模型列表
        return userResponse.data.map((apiUser) => apiUser.toUser()).toList();
      } else {
        developer.log('搜索用户失败: ${response.statusCode}, ${response.body}');
        throw Exception('搜索用户失败: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('搜索用户异常: $e');
      throw Exception('搜索用户异常: $e');
    }
  }

  @override
  Future<User> updateUserInfo(User user) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.apiBaseUrl}/user/${user.id}'),
      headers: HttpUtils.createHeaders(),
      body: jsonEncode({
        'username': user.name,
        'email': user.email,
        'phone': user.phoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      final userData = HttpUtils.decodeResponse(response);
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
  Future<User> login(String username, String password) async {
    try {
      developer.log('开始登录请求: $username');
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/user/login'),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      );

      developer.log('收到响应: ${response.statusCode}');
      developer.log('响应体: ${response.body}');

      // 处理响应
      final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
        response,
      );
      developer.log('解析后的响应数据类型: ${responseData.runtimeType}');
      developer.log('解析后的响应数据: $responseData');

      // 判断成功条件：有code字段且值为200
      final code = responseData['code'];
      if (code == 200) {
        // 获取用户数据，处理响应格式
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final userData = responseData['data'];
          developer.log('用户数据: $userData');

          // 创建用户对象，使用正确的字段名
          final user = User(
            id: _safeGetString(userData, 'userId') ?? '',
            name: _safeGetString(userData, 'username') ?? username,
            email: _safeGetString(userData, 'email') ?? '',
            phoneNumber: _safeGetString(userData, 'phone') ?? '',
          );

          developer.log('创建的用户对象: ${user.id}, ${user.name}, ${user.email}');
          await saveUserToLocal(user);
          return user;
        } else {
          throw Exception('登录成功但未返回用户数据');
        }
      } else {
        final message = responseData['message']?.toString();
        throw Exception(message ?? '登录失败: 服务器返回码 ${code ?? "未知"}');
      }
    } catch (e) {
      developer.log('登录异常: ${e.toString()}', error: e);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('无法连接到服务器(${AppConstants.apiDomain})，请检查服务器是否运行或网络连接');
      }
      rethrow;
    }
  }

  /// 安全获取字符串值，处理可能的空值和类型转换
  String? _safeGetString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    return value.toString();
  }

  @override
  Future<User> register(
    String username,
    String password,
    String email,
    String phone,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/user/register'),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final userData = HttpUtils.decodeResponse(response);
        final user = User(
          id: userData['id'] ?? '',
          name: username,
          email: email,
          phoneNumber: phone,
        );
        await saveUserToLocal(user);
        return user;
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '注册失败'),
        );
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

  @override
  Future<String> getUserNameById(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.apiBaseUrl}/user/getname/$userId'),
        headers: HttpUtils.createHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);
        if (responseData['code'] == 200 && responseData['data'] != null) {
          return responseData['data'] as String;
        } else {
          developer.log('获取用户名失败: ${responseData['message']}');
          return '未知用户';
        }
      } else {
        developer.log('获取用户名失败: ${response.statusCode}, ${response.body}');
        return '未知用户';
      }
    } catch (e) {
      developer.log('获取用户名异常: $e');
      return '未知用户';
    }
  }

  @override
  Future<bool> updatePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}/user/updatePassword'),
        headers: HttpUtils.createHeaders(),
        body: jsonEncode({
          'userId': userId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = HttpUtils.decodeResponse(response);
        if (responseData['code'] == 200) {
          return true;
        } else {
          throw Exception(responseData['message'] ?? '修改密码失败');
        }
      } else {
        throw Exception(
          HttpUtils.extractErrorMessage(response, defaultMessage: '修改密码失败'),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('无法连接到服务器(${AppConstants.apiDomain})，请检查服务器是否运行或网络连接');
      }
      rethrow;
    }
  }
}
