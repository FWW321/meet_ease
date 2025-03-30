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
