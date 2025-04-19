/// 会议列表API响应模型
class MeetingListResponse {
  final int code;
  final String message;
  final MeetingListData data;

  MeetingListResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory MeetingListResponse.fromJson(Map<String, dynamic> json) {
    return MeetingListResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data: MeetingListData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 会议列表数据
class MeetingListData {
  final List<MeetingRecord> records;
  final int total;
  final int size;
  final int current;
  final List<dynamic> orders;
  final bool optimizeCountSql;
  final bool searchCount;
  final dynamic maxLimit;
  final dynamic countId;
  final int pages;

  MeetingListData({
    required this.records,
    required this.total,
    required this.size,
    required this.current,
    required this.orders,
    required this.optimizeCountSql,
    required this.searchCount,
    this.maxLimit,
    this.countId,
    required this.pages,
  });

  factory MeetingListData.fromJson(Map<String, dynamic> json) {
    return MeetingListData(
      records:
          (json['records'] as List<dynamic>)
              .map((e) => MeetingRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: json['total'] as int,
      size: json['size'] as int,
      current: json['current'] as int,
      orders: json['orders'] as List<dynamic>,
      optimizeCountSql: json['optimizeCountSql'] as bool,
      searchCount: json['searchCount'] as bool,
      maxLimit: json['maxLimit'],
      countId: json['countId'],
      pages: json['pages'] as int,
    );
  }
}

/// 会议记录
class MeetingRecord {
  final int meetingId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int organizerId;
  final String location;
  final String status;
  final DateTime createdAt;

  MeetingRecord({
    required this.meetingId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory MeetingRecord.fromJson(Map<String, dynamic> json) {
    return MeetingRecord(
      meetingId: json['meetingId'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      organizerId: json['organizerId'] as int,
      location: json['location'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
