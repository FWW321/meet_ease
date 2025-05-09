import '../models/meeting.dart';

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
      return '其他类型';
  }
}

// 获取会议可见性文本
String getMeetingVisibilityText(MeetingVisibility visibility) {
  switch (visibility) {
    case MeetingVisibility.public:
      return '公开会议';
    case MeetingVisibility.private:
      return '私有会议';
  }
}

// 获取会议可见性说明文本
String getMeetingVisibilityDescription(MeetingVisibility visibility) {
  switch (visibility) {
    case MeetingVisibility.public:
      return '公开会议对所有人可见，所有人可参加';
    case MeetingVisibility.private:
      return '私有会议只对特定人员可见，需要选择参与人员';
  }
}
