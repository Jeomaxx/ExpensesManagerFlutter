import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart' as app_models;
import '../services/database_service.dart';

class TransactionRepository {
  static final TransactionRepository _instance = TransactionRepository._internal();
  static TransactionRepository get instance => _instance;
  TransactionRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<List<app_models.Transaction>> getTransactionsByUserId({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
    TransactionType? type,
  }) async {
    final db = await _db;
    
    String whereClause = 'user_id = ? AND is_deleted = 0';
    List<dynamic> whereArgs = [userId];
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (accountId != null) {
      whereClause += ' AND account_id = ?';
      whereArgs.add(accountId);
    }
    
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }
    
    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.name);
    }

    final maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _mapToTransaction(map)).toList();
  }

  Future<app_models.Transaction?> getTransactionById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'transactions',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToTransaction(maps.first);
    }
    return null;
  }

  Future<String> createTransaction(app_models.Transaction transaction) async {
    final db = await _db;
    final transactionMap = _mapFromTransaction(transaction);
    
    await db.insert('transactions', transactionMap);
    return transaction.id;
  }

  Future<void> updateTransaction(app_models.Transaction transaction) async {
    final db = await _db;
    final transactionMap = _mapFromTransaction(transaction);
    
    await db.update(
      'transactions',
      transactionMap,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    
    await db.update(
      'transactions',
      {
        'is_deleted': 1,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalByType({
    required String userId,
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    final db = await _db;
    
    String whereClause = 'user_id = ? AND type = ? AND is_deleted = 0';
    List<dynamic> whereArgs = [userId, type.name];
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause',
      whereArgs,
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals({
    required String userId,
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    
    String whereClause = 'user_id = ? AND type = ? AND is_deleted = 0';
    List<dynamic> whereArgs = [userId, type.name];
    
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery(
      'SELECT category_id, SUM(amount) as total FROM transactions WHERE $whereClause GROUP BY category_id',
      whereArgs,
    );
    
    final Map<String, double> categoryTotals = {};
    for (final row in result) {
      categoryTotals[row['category_id'] as String] = (row['total'] as num).toDouble();
    }
    
    return categoryTotals;
  }

  Future<double> getCurrentBalance(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as balance
      FROM transactions 
      WHERE user_id = ? AND is_deleted = 0
      ''',
      [userId],
    );
    
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT c.name as category_name, SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? 
        AND t.type = 'expense' 
        AND t.date >= ? 
        AND t.date <= ? 
        AND t.is_deleted = 0
      GROUP BY t.category_id, c.name
      ORDER BY total DESC
      ''',
      [userId, startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final result = <String, double>{};
    for (final map in maps) {
      final categoryName = map['category_name'] as String? ?? 'Other';
      final total = (map['total'] as num?)?.toDouble() ?? 0.0;
      result[categoryName] = total;
    }
    return result;
  }

  app_models.Transaction _mapToTransaction(Map<String, dynamic> map) {
    return app_models.Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      receiptUrl: map['receipt_url'] as String?,
      recurringId: map['recurring_id'] as String?,
      tags: map['tags'] != null 
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      splitData: map['split_data'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['split_data'] as String))
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromTransaction(app_models.Transaction transaction) {
    return {
      'id': transaction.id,
      'user_id': transaction.userId,
      'account_id': transaction.accountId,
      'amount': transaction.amount,
      'type': transaction.type.name,
      'category_id': transaction.categoryId,
      'date': transaction.date.toIso8601String(),
      'notes': transaction.notes,
      'receipt_url': transaction.receiptUrl,
      'recurring_id': transaction.recurringId,
      'tags': jsonEncode(transaction.tags),
      'split_data': transaction.splitData != null 
          ? jsonEncode(transaction.splitData!)
          : null,
      'created_at': transaction.createdAt.toIso8601String(),
      'last_modified': transaction.lastModified.toIso8601String(),
      'is_deleted': transaction.isDeleted ? 1 : 0,
    };
  }
}