/// 资料类型枚举
enum MaterialType {
  document, // 文档
  image, // 图片
  video, // 视频
  presentation, // 演示文稿
  other, // 其他
}

/// 会议资料项
class MaterialItem {
  final String id;
  final String title;
  final String? description;
  final MaterialType type;
  final String url; // 资料链接
  final String? thumbnailUrl; // 缩略图链接
  final int? fileSize; // 文件大小（字节）
  final String? uploaderId; // 上传者ID
  final String? uploaderName; // 上传者姓名
  final DateTime? uploadTime; // 上传时间

  const MaterialItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.fileSize,
    this.uploaderId,
    this.uploaderName,
    this.uploadTime,
  });

  // 复制并修改对象的方法
  MaterialItem copyWith({
    String? id,
    String? title,
    String? description,
    MaterialType? type,
    String? url,
    String? thumbnailUrl,
    int? fileSize,
    String? uploaderId,
    String? uploaderName,
    DateTime? uploadTime,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      uploadTime: uploadTime ?? this.uploadTime,
    );
  }
}

/// 会议资料集合
class MeetingMaterials {
  final String meetingId;
  final List<MaterialItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeetingMaterials({
    required this.meetingId,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  // 复制并修改对象的方法
  MeetingMaterials copyWith({
    String? meetingId,
    List<MaterialItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeetingMaterials(
      meetingId: meetingId ?? this.meetingId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 获取资料类型文本
String getMaterialTypeText(MaterialType type) {
  switch (type) {
    case MaterialType.document:
      return '文档';
    case MaterialType.image:
      return '图片';
    case MaterialType.video:
      return '视频';
    case MaterialType.presentation:
      return '演示文稿';
    case MaterialType.other:
      return '其他';
  }
}

// 获取文件大小可读文本
String getReadableFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
