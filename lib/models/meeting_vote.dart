/// 投票状态枚举
enum VoteStatus {
  pending, // 待开始
  active, // 进行中
  closed, // 已结束
}

/// 投票类型枚举
enum VoteType {
  singleChoice, // 单选
  multipleChoice, // 多选
  rating, // 评分
}

/// 投票选项
class VoteOption {
  final String id;
  final String text;
  final int votesCount; // 票数
  final List<String>? voterIds; // 投票者ID列表

  const VoteOption({
    required this.id,
    required this.text,
    this.votesCount = 0,
    this.voterIds,
  });

  // 复制并修改对象的方法
  VoteOption copyWith({
    String? id,
    String? text,
    int? votesCount,
    List<String>? voterIds,
  }) {
    return VoteOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votesCount: votesCount ?? this.votesCount,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}

/// 投票
class MeetingVote {
  final String id;
  final String meetingId;
  final String title;
  final String? description;
  final VoteType type;
  final VoteStatus status;
  final bool isAnonymous; // 是否匿名
  final DateTime? startTime;
  final DateTime? endTime;
  final List<VoteOption> options;
  final int totalVotes; // 总票数
  final String creatorId; // 创建者ID
  final String creatorName; // 创建者姓名
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MeetingVote({
    required this.id,
    required this.meetingId,
    required this.title,
    this.description,
    required this.type,
    this.status = VoteStatus.pending,
    this.isAnonymous = false,
    this.startTime,
    this.endTime,
    required this.options,
    this.totalVotes = 0,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.updatedAt,
  });

  // 复制并修改对象的方法
  MeetingVote copyWith({
    String? id,
    String? meetingId,
    String? title,
    String? description,
    VoteType? type,
    VoteStatus? status,
    bool? isAnonymous,
    DateTime? startTime,
    DateTime? endTime,
    List<VoteOption>? options,
    int? totalVotes,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingVote(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      options: options ?? this.options,
      totalVotes: totalVotes ?? this.totalVotes,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 获取投票状态文本
String getVoteStatusText(VoteStatus status) {
  switch (status) {
    case VoteStatus.pending:
      return '待开始';
    case VoteStatus.active:
      return '进行中';
    case VoteStatus.closed:
      return '已结束';
  }
}

// 获取投票类型文本
String getVoteTypeText(VoteType type) {
  switch (type) {
    case VoteType.singleChoice:
      return '单选';
    case VoteType.multipleChoice:
      return '多选';
    case VoteType.rating:
      return '评分';
  }
}
