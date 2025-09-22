import 'package:flutter/material.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final String? parentId;
  final String iconName;
  final Color color;
  final double? budgetAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.parentId,
    required this.iconName,
    required this.color,
    this.budgetAmount,
    this.isActive = true,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      iconName: json['iconName'] as String,
      color: Color(json['color'] as int),
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'parentId': parentId,
      'iconName': iconName,
      'color': color.value,
      'budgetAmount': budgetAmount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? parentId,
    String? iconName,
    Color? color,
    double? budgetAmount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}