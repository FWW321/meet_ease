import 'package:flutter/material.dart';

/// 会议状态枚举
enum MeetingStatus {
  upcoming, // 即将开始
  ongoing, // 进行中
  completed, // 已结束
  cancelled, // 已取消
}

/// 会议类型枚举
enum MeetingType {
  regular, // 常规会议
  training, // 培训会议
  interview, // 面试会议
  other, // 其他
}

/// 会议模型
class Meeting {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final MeetingStatus status;
  final MeetingType type;
  final String organizerId;
  final String organizerName;
  final String? description;
  final bool isSignedIn;
  final List<String> participants;
  final int participantCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Meeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.status,
    required this.type,
    required this.organizerId,
    required this.organizerName,
    this.description,
    this.isSignedIn = false,
    this.participants = const [],
    this.participantCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  // 复制并修改对象的方法
  Meeting copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    MeetingStatus? status,
    MeetingType? type,
    String? organizerId,
    String? organizerName,
    String? description,
    bool? isSignedIn,
    List<String>? participants,
    int? participantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      type: type ?? this.type,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      description: description ?? this.description,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 获取会议状态对应的颜色
Color getMeetingStatusColor(MeetingStatus status) {
  switch (status) {
    case MeetingStatus.upcoming:
      return Colors.blue;
    case MeetingStatus.ongoing:
      return Colors.green;
    case MeetingStatus.completed:
      return Colors.grey;
    case MeetingStatus.cancelled:
      return Colors.red;
  }
}

// 获取会议状态文本
String getMeetingStatusText(MeetingStatus status) {
  switch (status) {
    case MeetingStatus.upcoming:
      return '即将开始';
    case MeetingStatus.ongoing:
      return '进行中';
    case MeetingStatus.completed:
      return '已结束';
    case MeetingStatus.cancelled:
      return '已取消';
  }
}

// 获取会议类型文本
String getMeetingTypeText(MeetingType type) {
  switch (type) {
    case MeetingType.regular:
      return '常规会议';
    case MeetingType.training:
      return '培训会议';
    case MeetingType.interview:
      return '面试会议';
    case MeetingType.other:
      return '其他';
  }
}
