import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../services/database_service.dart';

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  static CategoryRepository get instance => _instance;
  CategoryRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<List<Category>> getCategoriesByUserId(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _mapToCategory(map)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToCategory(maps.first);
    }
    return null;
  }

  Future<String> createCategory(Category category) async {
    final db = await _db;
    final categoryMap = _mapFromCategory(category);
    
    await db.insert('categories', categoryMap);
    return category.id;
  }

  Future<void> updateCategory(Category category) async {
    final db = await _db;
    final categoryMap = _mapFromCategory(category);
    
    await db.update(
      'categories',
      categoryMap,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _db;
    
    await db.update(
      'categories',
      {
        'is_deleted': 1,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Category>> getCategoriesByType(String userId, {bool hasParent = false}) async {
    final db = await _db;
    String whereClause = 'user_id = ? AND is_deleted = 0';
    
    if (hasParent) {
      whereClause += ' AND parent_id IS NOT NULL';
    } else {
      whereClause += ' AND parent_id IS NULL';
    }

    final maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return maps.map((map) => _mapToCategory(map)).toList();
  }

  Future<double> getCategorySpent(String categoryId, DateTime startDate, DateTime endDate) async {
    final db = await _db;
    
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM transactions 
      WHERE category_id = ? 
        AND type = 'expense' 
        AND date >= ? 
        AND date <= ? 
        AND is_deleted = 0
      ''',
      [categoryId, startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Category _mapToCategory(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      iconName: map['icon_name'] as String,
      color: Color(map['color'] as int),
      budgetAmount: (map['budget_amount'] as num?)?.toDouble(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromCategory(Category category) {
    return {
      'id': category.id,
      'user_id': category.userId,
      'name': category.name,
      'parent_id': category.parentId,
      'icon_name': category.iconName,
      'color': category.color.value,
      'budget_amount': category.budgetAmount,
      'is_active': category.isActive ? 1 : 0,
      'created_at': category.createdAt.toIso8601String(),
      'last_modified': category.lastModified.toIso8601String(),
      'is_deleted': category.isDeleted ? 1 : 0,
    };
  }
}