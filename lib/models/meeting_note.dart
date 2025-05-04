/// 会议笔记
class MeetingNote {
  final String id;
  final String meetingId;
  final String content; // 笔记内容
  final String? noteName; // 笔记名称
  final String creatorId; // 创建者ID
  final String creatorName; // 创建者姓名
  final bool isShared; // 是否共享给所有参会者
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? tags; // 标签

  const MeetingNote({
    required this.id,
    required this.meetingId,
    required this.content,
    this.noteName,
    required this.creatorId,
    required this.creatorName,
    this.isShared = false,
    required this.createdAt,
    this.updatedAt,
    this.tags,
  });

  // 复制并修改对象的方法
  MeetingNote copyWith({
    String? id,
    String? meetingId,
    String? content,
    String? noteName,
    String? creatorId,
    String? creatorName,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return MeetingNote(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      content: content ?? this.content,
      noteName: noteName ?? this.noteName,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }
}
