import 'package:flutter/material.dart';
import '../../models/meeting.dart';

/// 会议表单验证工具类
class MeetingFormValidators {
  /// 验证会议时间是否有效
  static bool validateMeetingTime({
    required BuildContext context,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    bool isValid = true;

    // 1. 检查结束时间是否晚于开始时间
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('结束时间必须晚于开始时间'),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    // 2. 检查会议时长是否至少15分钟
    final duration = endDate.difference(startDate);
    if (duration.inMinutes < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('会议时长至少需要15分钟'),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  /// 验证私有会议是否选择了参与用户
  static Future<bool> validatePrivateMeetingUsers({
    required BuildContext context,
    required MeetingVisibility visibility,
    required List<String> selectedUserIds,
    required String currentUserId,
    required VoidCallback showUserSelectionFunc,
  }) async {
    // 如果不是私有会议，不需要验证
    if (visibility != MeetingVisibility.private) {
      return true;
    }

    // 计算不包括当前用户的已选择用户数量
    final actualSelectedCount =
        selectedUserIds.where((id) => id != currentUserId).length;

    if (actualSelectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('私有会议必须选择至少一名其他用户'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '选择用户',
            onPressed: showUserSelectionFunc,
          ),
        ),
      );
      return false;
    }

    return true;
  }
}
