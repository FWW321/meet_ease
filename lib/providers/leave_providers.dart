import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/leave.dart';
import '../constants/app_constants.dart';
import '../utils/http_utils.dart';

// 会议请假列表Provider
final meetingLeavesProvider = FutureProvider.family<List<Leave>, String>((
  ref,
  meetingId,
) async {
  final response = await http.get(
    Uri.parse('${AppConstants.apiBaseUrl}/leave/list/$meetingId'),
    headers: HttpUtils.createHeaders(),
  );

  if (response.statusCode == 200) {
    // 使用HttpUtils处理UTF-8编码响应
    final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
      response,
    );

    if (responseData['code'] == 200) {
      final List<dynamic> leaveList = responseData['data'];
      return leaveList.map((leaveJson) => Leave.fromJson(leaveJson)).toList();
    } else {
      throw Exception(responseData['message'] ?? '获取请假列表失败');
    }
  } else {
    // 使用HttpUtils提取错误信息
    throw Exception(
      HttpUtils.extractErrorMessage(response, defaultMessage: '获取请假列表失败'),
    );
  }
});

// 请假服务类
class LeaveService {
  // 审批通过请假申请
  Future<void> approveLeave(String leaveId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/leave/approve/$leaveId'),
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      // 使用HttpUtils处理UTF-8编码响应
      final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
        response,
      );

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '通过请假申请失败');
      }
    } else {
      // 使用HttpUtils提取错误信息
      throw Exception(
        HttpUtils.extractErrorMessage(response, defaultMessage: '通过请假申请失败'),
      );
    }
  }

  // 拒绝请假申请
  Future<void> rejectLeave(String leaveId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/leave/reject/$leaveId'),
      headers: HttpUtils.createHeaders(),
    );

    if (response.statusCode == 200) {
      // 使用HttpUtils处理UTF-8编码响应
      final Map<String, dynamic> responseData = HttpUtils.decodeResponse(
        response,
      );

      if (responseData['code'] != 200) {
        throw Exception(responseData['message'] ?? '拒绝请假申请失败');
      }
    } else {
      // 使用HttpUtils提取错误信息
      throw Exception(
        HttpUtils.extractErrorMessage(response, defaultMessage: '拒绝请假申请失败'),
      );
    }
  }
}

// 请假服务Provider
final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService();
});
