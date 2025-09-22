import 'package:flutter/material.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class DefaultDataService {
  static final DefaultDataService _instance = DefaultDataService._internal();
  static DefaultDataService get instance => _instance;
  DefaultDataService._internal();

  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  Future<void> createDefaultCategories(String userId) async {
    final defaultCategories = _getDefaultCategories(userId);
    
    for (final category in defaultCategories) {
      await _categoryRepository.createCategory(category);
    }
  }

  List<Category> _getDefaultCategories(String userId) {
    final now = DateTime.now();
    
    return [
      // Income Categories
      Category(
        id: '${userId}_cat_salary',
        userId: userId,
        name: 'Salary',
        iconName: 'work',
        color: const Color(0xFF4CAF50),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_freelance',
        userId: userId,
        name: 'Freelance',
        iconName: 'laptop',
        color: const Color(0xFF2196F3),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_investment',
        userId: userId,
        name: 'Investment Returns',
        iconName: 'trending_up',
        color: const Color(0xFF009688),
        createdAt: now,
        lastModified: now,
      ),

      // Expense Categories
      Category(
        id: '${userId}_cat_food',
        userId: userId,
        name: 'Food & Dining',
        iconName: 'restaurant',
        color: const Color(0xFFFF5722),
        budgetAmount: 800.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_transportation',
        userId: userId,
        name: 'Transportation',
        iconName: 'directions_car',
        color: const Color(0xFF3F51B5),
        budgetAmount: 600.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_shopping',
        userId: userId,
        name: 'Shopping',
        iconName: 'shopping_bag',
        color: const Color(0xFFE91E63),
        budgetAmount: 500.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_entertainment',
        userId: userId,
        name: 'Entertainment',
        iconName: 'movie',
        color: const Color(0xFF9C27B0),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_utilities',
        userId: userId,
        name: 'Utilities & Bills',
        iconName: 'receipt',
        color: const Color(0xFF607D8B),
        budgetAmount: 400.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_health',
        userId: userId,
        name: 'Health & Medical',
        iconName: 'local_hospital',
        color: const Color(0xFFF44336),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_education',
        userId: userId,
        name: 'Education',
        iconName: 'school',
        color: const Color(0xFF795548),
        budgetAmount: 150.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_travel',
        userId: userId,
        name: 'Travel',
        iconName: 'flight',
        color: const Color(0xFF00BCD4),
        budgetAmount: 1000.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_other',
        userId: userId,
        name: 'Other',
        iconName: 'category',
        color: const Color(0xFF9E9E9E),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
    ];
  }

  Future<void> createDefaultAccount(String userId) async {
    // TODO: Implement default account creation
    // This would create a default cash account for new users
  }
}