/// 用户模型
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? department;
  final String? position;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.department,
    this.position,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  // 复制并修改对象的方法
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? department,
    String? position,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      department: department ?? this.department,
      position: position ?? this.position,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// API用户响应模型
class ApiUser {
  final String userId;
  final String username;
  final String? password;
  final String? email;
  final String? phone;
  final String? createdAt;
  final int? deleted;

  const ApiUser({
    required this.userId,
    required this.username,
    this.password,
    this.email,
    this.phone,
    this.createdAt,
    this.deleted,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      userId: json['userId'].toString(),
      username: json['username'] as String,
      password: json['password'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['createdAt'] as String?,
      deleted: json['deleted'] as int?,
    );
  }

  // 转换为应用内User模型
  User toUser() {
    return User(
      id: userId,
      name: username,
      email: email ?? '',
      phoneNumber: phone,
    );
  }
}

/// 用户搜索响应
class UserSearchResponse {
  final int code;
  final String message;
  final List<ApiUser> data;

  const UserSearchResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      data:
          (json['data'] as List<dynamic>)
              .map((e) => ApiUser.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
