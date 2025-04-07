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

/// 会议可见性枚举
enum MeetingVisibility {
  public, // 公开会议，所有人可见且可参加
  searchable, // 可搜索会议，需要搜索才能显示，所有人可参加
  private, // 私有会议，只有指定人员可参加
}

/// 会议权限枚举
enum MeetingPermission {
  creator, // 创建者
  admin, // 管理员
  participant, // 普通参与者
  blocked, // 被封禁用户
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
  final MeetingVisibility visibility;
  final String organizerId;
  final String organizerName;
  final String? description;
  final bool isSignedIn;
  final List<String> participants;
  final int participantCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> admins; // 管理员 ID 列表
  final List<String> blacklist; // 黑名单 ID 列表
  final List<String> allowedUsers; // 允许参加的用户 ID 列表（仅当visibility为private时有效）
  final String? password; // 会议密码，为空表示不需要密码

  const Meeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.status,
    required this.type,
    this.visibility = MeetingVisibility.public,
    required this.organizerId,
    required this.organizerName,
    this.description,
    this.isSignedIn = false,
    this.participants = const [],
    this.participantCount = 0,
    this.createdAt,
    this.updatedAt,
    this.admins = const [],
    this.blacklist = const [],
    this.allowedUsers = const [],
    this.password,
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
    MeetingVisibility? visibility,
    String? organizerId,
    String? organizerName,
    String? description,
    bool? isSignedIn,
    List<String>? participants,
    int? participantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? admins,
    List<String>? blacklist,
    List<String>? allowedUsers,
    String? password,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      description: description ?? this.description,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      participants: participants ?? this.participants,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      admins: admins ?? this.admins,
      blacklist: blacklist ?? this.blacklist,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      password: password ?? this.password,
    );
  }

  // 检查用户权限
  MeetingPermission getUserPermission(String userId) {
    if (organizerId == userId) {
      return MeetingPermission.creator;
    } else if (admins.contains(userId)) {
      return MeetingPermission.admin;
    } else if (blacklist.contains(userId)) {
      return MeetingPermission.blocked;
    } else {
      return MeetingPermission.participant;
    }
  }

  // 检查用户是否能参加会议
  bool canUserJoin(String userId) {
    // 在黑名单中的用户不能参加
    if (blacklist.contains(userId)) {
      return false;
    }

    // 对于私有会议，检查用户是否在允许列表中
    if (visibility == MeetingVisibility.private) {
      return organizerId == userId ||
          admins.contains(userId) ||
          allowedUsers.contains(userId);
    }

    // 公开和可搜索会议所有人可参加
    return true;
  }

  // 检查用户是否可以管理会议
  bool canUserManage(String userId) {
    final userAdmins = admins;
    return organizerId == userId || userAdmins.contains(userId);
  }

  // 检查是否只有创建者才能执行的操作
  bool isCreatorOnly(String userId) {
    return organizerId == userId;
  }

  // 验证会议密码
  bool checkPassword(String? inputPassword) {
    // 如果会议没有设置密码，直接返回true
    if (password == null || password!.isEmpty) {
      return true;
    }

    // 如果会议有密码但用户没有提供密码，返回false
    if (inputPassword == null || inputPassword.isEmpty) {
      return false;
    }

    // 比较密码是否正确
    return password == inputPassword;
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

// 获取会议权限文本
String getMeetingPermissionText(MeetingPermission permission) {
  switch (permission) {
    case MeetingPermission.creator:
      return '创建者';
    case MeetingPermission.admin:
      return '管理员';
    case MeetingPermission.participant:
      return '参与者';
    case MeetingPermission.blocked:
      return '已封禁';
  }
}

// 获取会议可见性文本
String getMeetingVisibilityText(MeetingVisibility visibility) {
  switch (visibility) {
    case MeetingVisibility.public:
      return '公开会议';
    case MeetingVisibility.searchable:
      return '可搜索会议';
    case MeetingVisibility.private:
      return '私有会议';
  }
}
