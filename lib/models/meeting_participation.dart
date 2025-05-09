import '../models/meeting.dart';

// 会议参与历史模型
class MeetingParticipation {
  final int meetingId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final int organizerId;
  final List<int>? participantIds;
  final String visibility;
  final String? meetingType;
  final List<int>? adminIds;
  final String? joinPassword;
  final String signInStatus;
  final DateTime joinTime;
  final DateTime? leaveTime;
  final int duration;
  final String durationDisplay;

  MeetingParticipation({
    required this.meetingId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizerId,
    this.participantIds,
    required this.visibility,
    this.meetingType,
    this.adminIds,
    this.joinPassword,
    required this.signInStatus,
    required this.joinTime,
    this.leaveTime,
    required this.duration,
    required this.durationDisplay,
  });

  factory MeetingParticipation.fromJson(Map<String, dynamic> json) {
    return MeetingParticipation(
      meetingId: json['meetingId'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String,
      organizerId: json['organizerId'] as int,
      participantIds: json['participantIds'] as List<int>?,
      visibility: json['visibility'] as String,
      meetingType: json['meetingType'] as String?,
      adminIds: json['adminIds'] as List<int>?,
      joinPassword: json['joinPassword'] as String?,
      signInStatus: json['signInStatus'] as String,
      joinTime: DateTime.parse(json['joinTime'] as String),
      leaveTime:
          json['leaveTime'] != null
              ? DateTime.parse(json['leaveTime'] as String)
              : null,
      duration: json['duration'] as int,
      durationDisplay: json['durationDisplay'] as String,
    );
  }

  // 转换为 Meeting 模型
  Meeting toMeeting() {
    // 创建参与信息映射
    final Map<String, dynamic> participationMap = {
      'joinTime': joinTime.toString(),
      'leaveTime': leaveTime?.toString() ?? '',
      'duration': duration,
      'durationDisplay': durationDisplay,
    };

    // 只有私有会议才添加签到状态信息
    if (visibility == "PRIVATE") {
      participationMap['signInStatus'] = signInStatus;
    }

    return Meeting(
      id: meetingId.toString(),
      title: title,
      startTime: startTime,
      endTime: endTime,
      location: location,
      status: _getMeetingStatus(),
      type: _getMeetingType(),
      visibility: _getMeetingVisibility(),
      organizerId: organizerId.toString(),
      organizerName: "组织者", // 这里可能需要从其他地方获取
      description: description,
      isSignedIn: visibility == "PRIVATE" && signInStatus == "已签到",
      participationInfo: participationMap,
    );
  }

  // 获取会议状态
  MeetingStatus _getMeetingStatus() {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return MeetingStatus.upcoming;
    } else if (now.isAfter(endTime)) {
      return MeetingStatus.completed;
    } else {
      return MeetingStatus.ongoing;
    }
  }

  // 获取会议类型
  MeetingType _getMeetingType() {
    switch (meetingType) {
      case "常规会议":
        return MeetingType.regular;
      case "培训会议":
        return MeetingType.training;
      case "面试会议":
        return MeetingType.interview;
      default:
        return MeetingType.other;
    }
  }

  // 获取会议可见性
  MeetingVisibility _getMeetingVisibility() {
    switch (visibility) {
      case "PUBLIC":
        return MeetingVisibility.public;
      case "PRIVATE":
        return MeetingVisibility.private;
      default:
        return MeetingVisibility.public;
    }
  }
}

// 会议参与历史响应模型
class MeetingParticipationResponse {
  final int code;
  final String message;
  final List<MeetingParticipation> data;

  MeetingParticipationResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory MeetingParticipationResponse.fromJson(Map<String, dynamic> json) {
    return MeetingParticipationResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data:
          (json['data'] as List<dynamic>)
              .map(
                (e) => MeetingParticipation.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
