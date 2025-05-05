import 'package:flutter/material.dart';

// 请假申请模型类
class Leave {
  final String leaveId;
  final String userId;
  final String meetingId;
  final String reason;
  final String status; // "待审批", "通过", "拒绝"
  final DateTime createdAt;

  Leave({
    required this.leaveId,
    required this.userId,
    required this.meetingId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  // 从JSON创建请假申请对象
  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      leaveId: json['leaveId'].toString(),
      userId: json['userId'].toString(),
      meetingId: json['meetingId'].toString(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // 获取状态颜色
  Color getStatusColor() {
    switch (status) {
      case '待审批':
        return Colors.orange;
      case '通过':
        return Colors.green;
      case '拒绝':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
