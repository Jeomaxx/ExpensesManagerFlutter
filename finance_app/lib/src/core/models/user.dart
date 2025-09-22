class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.settings,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}