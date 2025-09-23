import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../repositories/category_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';

class DefaultDataService {
  static final DefaultDataService _instance = DefaultDataService._internal();
  static DefaultDataService get instance => _instance;
  DefaultDataService._internal();

  final CategoryRepository _categoryRepository = CategoryRepository.instance;

  Future<void> createDefaultCategories(String userId) async {
    // Check if categories already exist for this user
    final existingCategories = await _categoryRepository.getCategoriesByUserId(userId);
    
    // Only create default categories if none exist
    if (existingCategories.isEmpty) {
      final defaultCategories = _getDefaultCategories(userId);
      
      for (final category in defaultCategories) {
        try {
          await _categoryRepository.createCategory(category);
        } catch (e) {
          print('Failed to create category ${category.name}: $e');
        }
      }
    }
  }

  List<Category> _getDefaultCategories(String userId) {
    final now = DateTime.now();
    
    return [
      // ======= فئات الدخل =======
      // Income Categories
      Category(
        id: '${userId}_cat_salary',
        userId: userId,
        name: 'راتب شهري',
        iconName: 'work',
        color: const Color(0xFF4CAF50),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_bonus',
        userId: userId,
        name: 'مكافآت وحوافز',
        iconName: 'card_giftcard',
        color: const Color(0xFF8BC34A),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_freelance',
        userId: userId,
        name: 'أعمال حرة',
        iconName: 'laptop',
        color: const Color(0xFF2196F3),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_business',
        userId: userId,
        name: 'مشروع خاص',
        iconName: 'business',
        color: const Color(0xFF3F51B5),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_investment',
        userId: userId,
        name: 'أرباح استثمارات',
        iconName: 'trending_up',
        color: const Color(0xFF009688),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_rental',
        userId: userId,
        name: 'إيجار عقارات',
        iconName: 'home',
        color: const Color(0xFF00BCD4),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_commission',
        userId: userId,
        name: 'عمولات',
        iconName: 'percent',
        color: const Color(0xFF4DD0E1),
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_gift_income',
        userId: userId,
        name: 'هدايا نقدية',
        iconName: 'redeem',
        color: const Color(0xFFFFB74D),
        createdAt: now,
        lastModified: now,
      ),

      // ======= فئات المصروفات =======
      // Expense Categories
      // الطعام والمشروبات
      Category(
        id: '${userId}_cat_food',
        userId: userId,
        name: 'طعام ومشروبات',
        iconName: 'restaurant',
        color: const Color(0xFFFF5722),
        budgetAmount: 800.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_groceries',
        userId: userId,
        name: 'بقالة ومستلزمات',
        iconName: 'shopping_cart',
        color: const Color(0xFFFF7043),
        budgetAmount: 600.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // المواصلات
      Category(
        id: '${userId}_cat_transportation',
        userId: userId,
        name: 'مواصلات',
        iconName: 'directions_car',
        color: const Color(0xFF3F51B5),
        budgetAmount: 400.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_fuel',
        userId: userId,
        name: 'وقود',
        iconName: 'local_gas_station',
        color: const Color(0xFF5C6BC0),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // الصحة والعلاج
      Category(
        id: '${userId}_cat_health',
        userId: userId,
        name: 'صحة وعلاج',
        iconName: 'local_hospital',
        color: const Color(0xFFF44336),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_pharmacy',
        userId: userId,
        name: 'أدوية وصيدلية',
        iconName: 'medical_services',
        color: const Color(0xFFE57373),
        budgetAmount: 150.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // التعليم
      Category(
        id: '${userId}_cat_education',
        userId: userId,
        name: 'تعليم ودورات',
        iconName: 'school',
        color: const Color(0xFF795548),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_books',
        userId: userId,
        name: 'كتب ومراجع',
        iconName: 'menu_book',
        color: const Color(0xFF8D6E63),
        budgetAmount: 100.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // الفواتير والخدمات
      Category(
        id: '${userId}_cat_utilities',
        userId: userId,
        name: 'فواتير وخدمات',
        iconName: 'receipt',
        color: const Color(0xFF607D8B),
        budgetAmount: 500.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_electricity',
        userId: userId,
        name: 'كهرباء ومياه',
        iconName: 'bolt',
        color: const Color(0xFF78909C),
        budgetAmount: 250.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_internet',
        userId: userId,
        name: 'إنترنت واتصالات',
        iconName: 'wifi',
        color: const Color(0xFF90A4AE),
        budgetAmount: 150.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // الترفيه والتسلية
      Category(
        id: '${userId}_cat_entertainment',
        userId: userId,
        name: 'ترفيه وتسلية',
        iconName: 'movie',
        color: const Color(0xFF9C27B0),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_sports',
        userId: userId,
        name: 'رياضة ولياقة',
        iconName: 'fitness_center',
        color: const Color(0xFFAB47BC),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // التسوق والملابس
      Category(
        id: '${userId}_cat_shopping',
        userId: userId,
        name: 'تسوق عام',
        iconName: 'shopping_bag',
        color: const Color(0xFFE91E63),
        budgetAmount: 400.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_clothing',
        userId: userId,
        name: 'ملابس وأحذية',
        iconName: 'checkroom',
        color: const Color(0xFFEC407A),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // السفر والسياحة
      Category(
        id: '${userId}_cat_travel',
        userId: userId,
        name: 'سفر وسياحة',
        iconName: 'flight',
        color: const Color(0xFF00BCD4),
        budgetAmount: 1000.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_hotels',
        userId: userId,
        name: 'فنادق وإقامة',
        iconName: 'hotel',
        color: const Color(0xFF26C6DA),
        budgetAmount: 500.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // المنزل والأسرة
      Category(
        id: '${userId}_cat_home',
        userId: userId,
        name: 'منزل وأثاث',
        iconName: 'home',
        color: const Color(0xFF8BC34A),
        budgetAmount: 300.0,
        createdAt: now,
        lastModified: now,
      ),
      Category(
        id: '${userId}_cat_family',
        userId: userId,
        name: 'أطفال وأسرة',
        iconName: 'family_restroom',
        color: const Color(0xFF9CCC65),
        budgetAmount: 400.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // الهدايا والمناسبات
      Category(
        id: '${userId}_cat_gifts',
        userId: userId,
        name: 'هدايا ومناسبات',
        iconName: 'card_giftcard',
        color: const Color(0xFFFFB74D),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // الاشتراكات والخدمات الرقمية
      Category(
        id: '${userId}_cat_subscriptions',
        userId: userId,
        name: 'اشتراكات وخدمات رقمية',
        iconName: 'subscription',
        color: const Color(0xFF673AB7),
        budgetAmount: 150.0,
        createdAt: now,
        lastModified: now,
      ),
      
      // أخرى
      Category(
        id: '${userId}_cat_other',
        userId: userId,
        name: 'متفرقات',
        iconName: 'category',
        color: const Color(0xFF9E9E9E),
        budgetAmount: 200.0,
        createdAt: now,
        lastModified: now,
      ),
    ];
  }

  Future<void> createDefaultAccount(String userId) async {
    final accountRepository = AccountRepository.instance;
    final now = DateTime.now();
    
    final defaultAccount = Account(
      id: '${userId}_acc_cash',
      userId: userId,
      name: 'Cash',
      type: AccountType.cash,
      balance: 0.0,
      currency: 'EGP',
      description: 'Default cash account',
      isActive: true,
      createdAt: now,
      lastModified: now,
    );
    
    // Check if account already exists
    final existingAccount = await accountRepository.getAccountById(defaultAccount.id);
    if (existingAccount == null) {
      await accountRepository.createAccount(defaultAccount);
    }
  }

  Future<void> createSampleTransactions(String userId) async {
    final transactionRepository = TransactionRepository.instance;
    final accountRepository = AccountRepository.instance;
    
    // Ensure default account exists
    await createDefaultAccount(userId);
    
    final accounts = await accountRepository.getAccountsByUserId(userId);
    if (accounts.isEmpty) return;
    
    final defaultAccountId = accounts.first.id;
    final categories = await _categoryRepository.getCategoriesByUserId(userId);
    
    if (categories.isEmpty) return;
    
    final now = DateTime.now();
    final sampleTransactions = [
      // Income transactions
      Transaction(
        id: '${userId}_txn_salary_${now.millisecondsSinceEpoch}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'راتب شهري', orElse: () => categories.first).id,
        amount: 8500.0,
        type: TransactionType.income,
        notes: 'راتب شهر ${now.month}',
        date: DateTime(now.year, now.month, 1),
        tags: ['راتب', 'دخل'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_freelance_${now.millisecondsSinceEpoch + 1}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'أعمال حرة', orElse: () => categories.first).id,
        amount: 1200.0,
        type: TransactionType.income,
        notes: 'مشروع تطوير موقع',
        date: now.subtract(const Duration(days: 5)),
        tags: ['أعمال حرة', 'دخل'],
        createdAt: now,
        lastModified: now,
      ),
      
      // Expense transactions
      Transaction(
        id: '${userId}_txn_grocery_${now.millisecondsSinceEpoch + 2}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'بقالة ومستلزمات', orElse: () => categories.first).id,
        amount: 250.0,
        type: TransactionType.expense,
        notes: 'تسوق أسبوعي',
        date: now.subtract(const Duration(days: 1)),
        tags: ['بقالة', 'طعام'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_gas_${now.millisecondsSinceEpoch + 3}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'وقود', orElse: () => categories.first).id,
        amount: 120.0,
        type: TransactionType.expense,
        notes: 'تعبئة وقود',
        date: now.subtract(const Duration(days: 2)),
        tags: ['وقود', 'مواصلات'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_restaurant_${now.millisecondsSinceEpoch + 4}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'طعام ومشروبات', orElse: () => categories.first).id,
        amount: 85.0,
        type: TransactionType.expense,
        notes: 'عشاء في مطعم',
        date: now.subtract(const Duration(days: 3)),
        tags: ['مطعم', 'طعام'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_electricity_${now.millisecondsSinceEpoch + 5}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'كهرباء ومياه', orElse: () => categories.first).id,
        amount: 450.0,
        type: TransactionType.expense,
        notes: 'فاتورة الكهرباء والمياه',
        date: DateTime(now.year, now.month, 5),
        tags: ['فواتير', 'خدمات'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_pharmacy_${now.millisecondsSinceEpoch + 6}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name == 'أدوية وصيدلية', orElse: () => categories.first).id,
        amount: 75.0,
        type: TransactionType.expense,
        notes: 'أدوية وفيتامينات',
        date: now.subtract(const Duration(days: 4)),
        tags: ['صيدلية', 'صحة'],
        createdAt: now,
        lastModified: now,
      ),
    ];
    
    // Check if sample transactions already exist - only create once
    final existingTransactions = await transactionRepository.getTransactionsByUserId(userId: userId, limit: 1);
    
    // Only create sample data for completely new users (no transactions at all)
    if (existingTransactions.isEmpty) {
      for (final transaction in sampleTransactions) {
        try {
          // Double-check transaction doesn't exist by ID
          final existingTxn = await transactionRepository.getTransactionById(transaction.id);
          if (existingTxn == null) {
            await transactionRepository.createTransaction(transaction);
          }
        } catch (e) {
          print('Failed to create sample transaction ${transaction.id}: $e');
        }
      }
    }
  }
}