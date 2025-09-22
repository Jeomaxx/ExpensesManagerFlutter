import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/investment.dart' as app_models;
import '../services/database_service.dart';

class InvestmentRepository {
  static final InvestmentRepository _instance = InvestmentRepository._internal();
  static InvestmentRepository get instance => _instance;
  InvestmentRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<List<app_models.Investment>> getInvestmentsByUserId(String userId) async {
    final db = await _db;
    
    final maps = await db.query(
      'investments',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _mapToInvestment(map)).toList();
  }

  Future<app_models.Investment?> getInvestmentById(String id) async {
    final db = await _db;
    
    final maps = await db.query(
      'investments',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return _mapToInvestment(maps.first);
    }
    return null;
  }

  Future<String> createInvestment(app_models.Investment investment) async {
    final db = await _db;
    final investmentMap = _mapFromInvestment(investment);
    
    await db.insert('investments', investmentMap);
    return investment.id;
  }

  Future<void> updateInvestment(app_models.Investment investment) async {
    final db = await _db;
    final investmentMap = _mapFromInvestment(investment);
    
    await db.update(
      'investments',
      investmentMap,
      where: 'id = ?',
      whereArgs: [investment.id],
    );
  }

  Future<void> deleteInvestment(String id) async {
    final db = await _db;
    
    await db.update(
      'investments',
      {'is_deleted': 1, 'last_modified': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<app_models.Investment>> getInvestmentsByType(
    String userId, 
    app_models.InvestmentType type
  ) async {
    final db = await _db;
    
    final maps = await db.query(
      'investments',
      where: 'user_id = ? AND type = ? AND is_deleted = 0',
      whereArgs: [userId, type.name],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _mapToInvestment(map)).toList();
  }

  Future<double> getTotalInvestmentValue(String userId) async {
    final investments = await getInvestmentsByUserId(userId);
    return investments.fold(0.0, (sum, investment) => sum + investment.amount);
  }

  Future<double> getTotalCurrentValue(String userId) async {
    final investments = await getInvestmentsByUserId(userId);
    return investments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? investment.amount));
  }

  Future<double> getTotalROI(String userId) async {
    final investments = await getInvestmentsByUserId(userId);
    final totalInvested = investments.fold(0.0, (sum, investment) => sum + investment.amount);
    final totalCurrent = investments.fold(0.0, (sum, investment) => sum + (investment.currentValue ?? investment.amount));
    
    if (totalInvested <= 0) return 0.0;
    return ((totalCurrent - totalInvested) / totalInvested) * 100;
  }

  Future<Map<app_models.InvestmentType, double>> getInvestmentsByTypeBreakdown(String userId) async {
    final investments = await getInvestmentsByUserId(userId);
    final breakdown = <app_models.InvestmentType, double>{};
    
    for (final investment in investments) {
      breakdown[investment.type] = (breakdown[investment.type] ?? 0) + investment.amount;
    }
    
    return breakdown;
  }

  Future<List<app_models.Investment>> getTopPerformingInvestments(String userId, {int limit = 10}) async {
    final investments = await getInvestmentsByUserId(userId);
    
    investments.sort((a, b) => b.roi.compareTo(a.roi));
    return investments.take(limit).toList();
  }

  Future<List<app_models.Investment>> getWorstPerformingInvestments(String userId, {int limit = 10}) async {
    final investments = await getInvestmentsByUserId(userId);
    
    investments.sort((a, b) => a.roi.compareTo(b.roi));
    return investments.take(limit).toList();
  }

  app_models.Investment _mapToInvestment(Map<String, dynamic> map) {
    return app_models.Investment(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: app_models.InvestmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => app_models.InvestmentType.other,
      ),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      currentValue: (map['current_value'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromInvestment(app_models.Investment investment) {
    return {
      'id': investment.id,
      'user_id': investment.userId,
      'name': investment.name,
      'type': investment.type.name,
      'amount': investment.amount,
      'date': investment.date.toIso8601String(),
      'current_value': investment.currentValue,
      'notes': investment.notes,
      'created_at': investment.createdAt.toIso8601String(),
      'last_modified': investment.lastModified.toIso8601String(),
      'is_deleted': investment.isDeleted ? 1 : 0,
    };
  }
}