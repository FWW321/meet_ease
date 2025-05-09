import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import '../models/leave.dart';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';

// 会议请假列表Provider
final meetingLeavesProvider = FutureProvider.family<List<Leave>, String>((
  ref,
  meetingId,
) async {
  final url = '${AppConstants.apiBaseUrl}/leave/list/$meetingId';
  developer.log('正在请求请假列表: $url', name: 'LeavesProvider');

  final response = await http.get(
    Uri.parse(url),
    headers: HttpUtils.createHeaders(),
  );

  developer.log('请假列表响应状态码: ${response.statusCode}', name: 'LeavesProvider');

  if (response.statusCode == 200) {
    // 使用HttpUtils处理UTF-8编码响应
    final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
      response,
    );

    developer.log('请假列表响应数据: $responseData', name: 'LeavesProvider');

    if (responseData['code'] == 200) {
      final List<dynamic> leaveList = responseData['data'];
      developer.log('获取到 ${leaveList.length} 个请假申请', name: 'LeavesProvider');
      return leaveList.map((leaveJson) => Leave.fromJson(leaveJson)).toList();
    } else {
      final errorMsg = responseData['message'] ?? '获取请假列表失败';
      developer.log('获取请假列表失败: $errorMsg', name: 'LeavesProvider');
      throw Exception(errorMsg);
    }
  } else {
    // 使用HttpUtils提取错误信息
    final errorMsg = HttpUtils.extractErrorMessage(
      response,
      defaultMessage: '获取请假列表失败',
    );
    developer.log('请求请假列表失败: $errorMsg', name: 'LeavesProvider');
    throw Exception(errorMsg);
  }
});

// 请假服务类
class LeaveService {
  // 审批通过请假申请
  Future<void> approveLeave(String leaveId) async {
    final url = '${AppConstants.apiBaseUrl}/leave/approve/$leaveId';
    developer.log('正在通过请假申请: $url', name: 'LeaveService');

    final response = await http.post(
      Uri.parse(url),
      headers: HttpUtils.createHeaders(),
    );

    developer.log('通过请假申请响应状态码: ${response.statusCode}', name: 'LeaveService');

    if (response.statusCode == 200) {
      // 使用HttpUtils处理UTF-8编码响应
      final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
        response,
      );

      developer.log('通过请假申请响应数据: $responseData', name: 'LeaveService');

      if (responseData['code'] != 200) {
        final errorMsg = responseData['message'] ?? '通过请假申请失败';
        developer.log('通过请假申请失败: $errorMsg', name: 'LeaveService');
        throw Exception(errorMsg);
      }
    } else {
      // 使用HttpUtils提取错误信息
      final errorMsg = HttpUtils.extractErrorMessage(
        response,
        defaultMessage: '通过请假申请失败',
      );
      developer.log('通过请假申请请求失败: $errorMsg', name: 'LeaveService');
      throw Exception(errorMsg);
    }
  }

  // 拒绝请假申请
  Future<void> rejectLeave(String leaveId) async {
    final url = '${AppConstants.apiBaseUrl}/leave/reject/$leaveId';
    developer.log('正在拒绝请假申请: $url', name: 'LeaveService');

    final response = await http.post(
      Uri.parse(url),
      headers: HttpUtils.createHeaders(),
    );

    developer.log('拒绝请假申请响应状态码: ${response.statusCode}', name: 'LeaveService');

    if (response.statusCode == 200) {
      // 使用HttpUtils处理UTF-8编码响应
      final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
        response,
      );

      developer.log('拒绝请假申请响应数据: $responseData', name: 'LeaveService');

      if (responseData['code'] != 200) {
        final errorMsg = responseData['message'] ?? '拒绝请假申请失败';
        developer.log('拒绝请假申请失败: $errorMsg', name: 'LeaveService');
        throw Exception(errorMsg);
      }
    } else {
      // 使用HttpUtils提取错误信息
      final errorMsg = HttpUtils.extractErrorMessage(
        response,
        defaultMessage: '拒绝请假申请失败',
      );
      developer.log('拒绝请假申请请求失败: $errorMsg', name: 'LeaveService');
      throw Exception(errorMsg);
    }
  }
}

// 请假服务Provider
final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService();
});
