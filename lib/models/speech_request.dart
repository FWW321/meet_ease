import 'package:flutter/material.dart';

/// 发言申请状态枚举
enum SpeechRequestStatus {
  pending, // 待审批
  approved, // 已批准
  rejected, // 已拒绝
  completed, // 已完成
}

/// 获取发言申请状态对应的颜色
Color getSpeechRequestStatusColor(SpeechRequestStatus status) {
  switch (status) {
    case SpeechRequestStatus.pending:
      return Colors.orange;
    case SpeechRequestStatus.approved:
      return Colors.green;
    case SpeechRequestStatus.rejected:
      return Colors.red;
    case SpeechRequestStatus.completed:
      return Colors.grey;
  }
}

/// 获取发言申请状态文本
String getSpeechRequestStatusText(SpeechRequestStatus status) {
  switch (status) {
    case SpeechRequestStatus.pending:
      return '待审批';
    case SpeechRequestStatus.approved:
      return '已批准';
    case SpeechRequestStatus.rejected:
      return '已拒绝';
    case SpeechRequestStatus.completed:
      return '已完成';
  }
}

/// 发言申请模型
class SpeechRequest {
  final String id;
  final String meetingId;
  final String requesterId;
  final String requesterName;
  final String topic;
  final String? reason;
  final Duration estimatedDuration;
  final SpeechRequestStatus status;
  final DateTime requestTime;
  final DateTime? approvalTime;
  final String? approverId;
  final String? approverName;
  final DateTime? startTime;
  final DateTime? endTime;

  const SpeechRequest({
    required this.id,
    required this.meetingId,
    required this.requesterId,
    required this.requesterName,
    required this.topic,
    this.reason,
    required this.estimatedDuration,
    required this.status,
    required this.requestTime,
    this.approvalTime,
    this.approverId,
    this.approverName,
    this.startTime,
    this.endTime,
  });

  // 复制并修改对象的方法
  SpeechRequest copyWith({
    String? id,
    String? meetingId,
    String? requesterId,
    String? requesterName,
    String? topic,
    String? reason,
    Duration? estimatedDuration,
    SpeechRequestStatus? status,
    DateTime? requestTime,
    DateTime? approvalTime,
    String? approverId,
    String? approverName,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return SpeechRequest(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      topic: topic ?? this.topic,
      reason: reason ?? this.reason,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      requestTime: requestTime ?? this.requestTime,
      approvalTime: approvalTime ?? this.approvalTime,
      approverId: approverId ?? this.approverId,
      approverName: approverName ?? this.approverName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
