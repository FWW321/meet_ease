import 'meeting.dart';

/// 推荐会议模型
class MeetingRecommendation {
  final double matchScore;
  final Meeting meeting;

  MeetingRecommendation({required this.matchScore, required this.meeting});

  factory MeetingRecommendation.fromJson(Map<String, dynamic> json) {
    final meetingData = json['meeting'] as Map<String, dynamic>;

    // 创建Meeting对象
    final meeting = Meeting(
      id: meetingData['meetingId'].toString(),
      title: meetingData['title'] as String,
      startTime: DateTime.parse(meetingData['startTime'] as String),
      endTime: DateTime.parse(meetingData['endTime'] as String),
      location: meetingData['location'] as String,
      status: _parseStatus(meetingData['status'] as String),
      type: _parseType(meetingData['meetingType'] as String),
      visibility: _parseVisibility(meetingData['visibility'] as String),
      organizerId: meetingData['organizerId'].toString(),
      organizerName: '', // API返回中无此字段
      description: meetingData['description'] as String?,
      createdAt:
          meetingData['createdAt'] != null
              ? DateTime.parse(meetingData['createdAt'] as String)
              : null,
      password: meetingData['joinPassword'] as String?,
    );

    return MeetingRecommendation(
      matchScore: json['matchScore'] as double,
      meeting: meeting,
    );
  }
}

// 辅助函数：解析会议状态
MeetingStatus _parseStatus(String status) {
  switch (status) {
    case '待开始':
      return MeetingStatus.upcoming;
    case '进行中':
      return MeetingStatus.ongoing;
    case '已结束':
      return MeetingStatus.completed;
    case '已取消':
      return MeetingStatus.cancelled;
    default:
      return MeetingStatus.upcoming;
  }
}

// 辅助函数：解析会议类型
MeetingType _parseType(String type) {
  switch (type) {
    case '常规会议':
      return MeetingType.regular;
    case '培训会议':
      return MeetingType.training;
    case '面试会议':
      return MeetingType.interview;
    default:
      return MeetingType.other;
  }
}

// 辅助函数：解析会议可见性
MeetingVisibility _parseVisibility(String visibility) {
  switch (visibility) {
    case 'PUBLIC':
      return MeetingVisibility.public;
    case 'SEARCHABLE':
      return MeetingVisibility.searchable;
    case 'PRIVATE':
      return MeetingVisibility.private;
    default:
      return MeetingVisibility.public;
  }
}
