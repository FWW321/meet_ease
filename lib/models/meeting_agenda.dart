import 'package:flutter/material.dart';

/// 议程项状态
enum AgendaItemStatus {
  pending, // 待处理
  inProgress, // 进行中
  completed, // 已完成
  skipped, // 已跳过
}

/// 会议议程项
class AgendaItem {
  final String id;
  final String title;
  final String? description;
  final Duration duration; // 预计时长
  final AgendaItemStatus status;
  final String? speakerName; // 负责人
  final DateTime? startTime; // 实际开始时间
  final DateTime? endTime; // 实际结束时间

  const AgendaItem({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    this.status = AgendaItemStatus.pending,
    this.speakerName,
    this.startTime,
    this.endTime,
  });

  // 复制并修改对象的方法
  AgendaItem copyWith({
    String? id,
    String? title,
    String? description,
    Duration? duration,
    AgendaItemStatus? status,
    String? speakerName,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      speakerName: speakerName ?? this.speakerName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// 会议议程
class MeetingAgenda {
  final String meetingId;
  final List<AgendaItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeetingAgenda({
    required this.meetingId,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  // 复制并修改对象的方法
  MeetingAgenda copyWith({
    String? meetingId,
    List<AgendaItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingAgenda(
      meetingId: meetingId ?? this.meetingId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 获取议程项状态颜色
Color getAgendaItemStatusColor(AgendaItemStatus status) {
  switch (status) {
    case AgendaItemStatus.pending:
      return Colors.grey;
    case AgendaItemStatus.inProgress:
      return Colors.blue;
    case AgendaItemStatus.completed:
      return Colors.green;
    case AgendaItemStatus.skipped:
      return Colors.orange;
  }
}

// 获取议程项状态文本
String getAgendaItemStatusText(AgendaItemStatus status) {
  switch (status) {
    case AgendaItemStatus.pending:
      return '待处理';
    case AgendaItemStatus.inProgress:
      return '进行中';
    case AgendaItemStatus.completed:
      return '已完成';
    case AgendaItemStatus.skipped:
      return '已跳过';
  }
}
