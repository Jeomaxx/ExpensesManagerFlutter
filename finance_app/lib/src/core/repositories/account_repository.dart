import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../services/database_service.dart';

class AccountRepository {
  static final AccountRepository _instance = AccountRepository._internal();
  static AccountRepository get instance => _instance;
  AccountRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<List<Account>> getAccountsByUserId(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'accounts',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _mapToAccount(map)).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'accounts',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToAccount(maps.first);
    }
    return null;
  }

  Future<String> createAccount(Account account) async {
    final db = await _db;
    final accountMap = _mapFromAccount(account);
    
    await db.insert('accounts', accountMap);
    return account.id;
  }

  Future<void> updateAccount(Account account) async {
    final db = await _db;
    final accountMap = _mapFromAccount(account);
    
    await db.update(
      'accounts',
      accountMap,
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> updateAccountBalance(String accountId, double newBalance) async {
    final db = await _db;
    
    await db.update(
      'accounts',
      {
        'balance': newBalance,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _db;
    
    await db.update(
      'accounts',
      {
        'is_deleted': 1,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalBalance(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(balance) as total FROM accounts WHERE user_id = ? AND is_deleted = 0 AND is_active = 1',
      [userId],
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Account _mapToAccount(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.cash,
      ),
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromAccount(Account account) {
    return {
      'id': account.id,
      'user_id': account.userId,
      'name': account.name,
      'type': account.type.name,
      'currency': account.currency,
      'balance': account.balance,
      'description': account.description,
      'is_active': account.isActive ? 1 : 0,
      'created_at': account.createdAt.toIso8601String(),
      'last_modified': account.lastModified.toIso8601String(),
      'is_deleted': account.isDeleted ? 1 : 0,
    };
  }
}