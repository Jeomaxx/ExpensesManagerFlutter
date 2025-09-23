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
        categoryId: categories.firstWhere((c) => c.name.contains('Salary'), orElse: () => categories.first).id,
        amount: 8500.0,
        type: TransactionType.income,
        notes: 'Monthly salary',
        date: DateTime(now.year, now.month, 1),
        tags: ['salary', 'income'],
        createdAt: now,
        lastModified: now,
      ),
      
      // Expense transactions
      Transaction(
        id: '${userId}_txn_grocery_${now.millisecondsSinceEpoch + 1}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name.contains('Food'), orElse: () => categories.first).id,
        amount: 250.0,
        type: TransactionType.expense,
        notes: 'Weekly groceries',
        date: now.subtract(const Duration(days: 1)),
        tags: ['grocery', 'food'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_gas_${now.millisecondsSinceEpoch + 2}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name.contains('Transportation'), orElse: () => categories.first).id,
        amount: 120.0,
        type: TransactionType.expense,
        notes: 'Gas station fill-up',
        date: now.subtract(const Duration(days: 2)),
        tags: ['gas', 'transport'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_coffee_${now.millisecondsSinceEpoch + 3}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name.contains('Food'), orElse: () => categories.first).id,
        amount: 25.0,
        type: TransactionType.expense,
        notes: 'Coffee shop',
        date: now.subtract(const Duration(days: 3)),
        tags: ['coffee', 'food'],
        createdAt: now,
        lastModified: now,
      ),
      
      Transaction(
        id: '${userId}_txn_utilities_${now.millisecondsSinceEpoch + 4}',
        userId: userId,
        accountId: defaultAccountId,
        categoryId: categories.firstWhere((c) => c.name.contains('Utilities'), orElse: () => categories.first).id,
        amount: 450.0,
        type: TransactionType.expense,
        notes: 'Monthly electricity bill',
        date: DateTime(now.year, now.month, 5),
        tags: ['utilities', 'bills'],
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