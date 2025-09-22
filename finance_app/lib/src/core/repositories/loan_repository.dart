import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/loan.dart' as app_models;
import '../services/database_service.dart';

class LoanRepository {
  static final LoanRepository _instance = LoanRepository._internal();
  static LoanRepository get instance => _instance;
  LoanRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<List<app_models.Loan>> getLoansByUserId(String userId) async {
    final db = await _db;
    
    final maps = await db.query(
      'loans',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => _mapToLoan(map)).toList();
  }

  Future<app_models.Loan?> getLoanById(String id) async {
    final db = await _db;
    
    final maps = await db.query(
      'loans',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return _mapToLoan(maps.first);
    }
    return null;
  }

  Future<String> createLoan(app_models.Loan loan) async {
    final db = await _db;
    final loanMap = _mapFromLoan(loan);
    
    await db.insert('loans', loanMap);
    
    // Create payment schedule entries
    for (final payment in loan.schedule) {
      await _createLoanPayment(payment, loan.id);
    }
    
    return loan.id;
  }

  Future<void> updateLoan(app_models.Loan loan) async {
    final db = await _db;
    final loanMap = _mapFromLoan(loan);
    
    await db.update(
      'loans',
      loanMap,
      where: 'id = ?',
      whereArgs: [loan.id],
    );
    
    // Update payment schedule
    await _updateLoanPayments(loan);
  }

  Future<void> deleteLoan(String id) async {
    final db = await _db;
    
    await db.update(
      'loans',
      {'is_deleted': 1, 'last_modified': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Mark all related payments as deleted
    await db.update(
      'loan_payments',
      {'is_deleted': 1},
      where: 'loan_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> makePayment(String loanId, app_models.LoanPayment payment) async {
    final db = await _db;
    
    // Update the payment record
    await db.update(
      'loan_payments',
      {
        'paid_date': payment.paidDate?.toIso8601String(),
        'is_paid': payment.isPaid ? 1 : 0,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND loan_id = ?',
      whereArgs: [payment.id, loanId],
    );
  }

  Future<List<app_models.LoanPayment>> getUpcomingPayments(String userId, {int days = 30}) async {
    final db = await _db;
    final endDate = DateTime.now().add(Duration(days: days));
    
    final maps = await db.rawQuery('''
      SELECT lp.* FROM loan_payments lp
      INNER JOIN loans l ON lp.loan_id = l.id
      WHERE l.user_id = ? 
      AND lp.is_paid = 0 
      AND lp.is_deleted = 0
      AND l.is_deleted = 0
      AND lp.due_date <= ?
      ORDER BY lp.due_date ASC
    ''', [userId, endDate.toIso8601String()]);
    
    return maps.map((map) => _mapToLoanPayment(map)).toList();
  }

  Future<List<app_models.LoanPayment>> getOverduePayments(String userId) async {
    final db = await _db;
    final today = DateTime.now();
    
    final maps = await db.rawQuery('''
      SELECT lp.* FROM loan_payments lp
      INNER JOIN loans l ON lp.loan_id = l.id
      WHERE l.user_id = ? 
      AND lp.is_paid = 0 
      AND lp.is_deleted = 0
      AND l.is_deleted = 0
      AND lp.due_date < ?
      ORDER BY lp.due_date ASC
    ''', [userId, today.toIso8601String()]);
    
    return maps.map((map) => _mapToLoanPayment(map)).toList();
  }

  Future<double> getTotalOutstandingBalance(String userId) async {
    final loans = await getLoansByUserId(userId);
    return loans.where((loan) => loan.isActive).fold(0.0, (sum, loan) => sum + loan.remainingBalance);
  }

  Future<double> getMonthlyPaymentTotal(String userId) async {
    final loans = await getLoansByUserId(userId);
    return loans.where((loan) => loan.isActive).fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }

  Future<void> _createLoanPayment(app_models.LoanPayment payment, String loanId) async {
    final db = await _db;
    
    await db.insert('loan_payments', {
      'id': payment.id,
      'loan_id': loanId,
      'payment_number': payment.paymentNumber,
      'amount': payment.amount,
      'principal': payment.principal,
      'interest': payment.interest,
      'remaining_balance': payment.remainingBalance,
      'due_date': payment.dueDate.toIso8601String(),
      'paid_date': payment.paidDate?.toIso8601String(),
      'is_paid': payment.isPaid ? 1 : 0,
      'is_deleted': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateLoanPayments(app_models.Loan loan) async {
    final db = await _db;
    
    // Delete existing payments for this loan
    await db.delete('loan_payments', where: 'loan_id = ?', whereArgs: [loan.id]);
    
    // Recreate payment schedule
    for (final payment in loan.schedule) {
      await _createLoanPayment(payment, loan.id);
    }
    
    // Add actual payments
    for (final payment in loan.payments) {
      await _createLoanPayment(payment, loan.id);
    }
  }

  app_models.Loan _mapToLoan(Map<String, dynamic> map) {
    // Get payment schedule and payments (would need separate queries in practice)
    final schedule = <app_models.LoanPayment>[];
    final payments = <app_models.LoanPayment>[];
    
    return app_models.Loan(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      lender: map['lender'] as String,
      principal: (map['principal'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      termMonths: map['term_months'] as int,
      monthlyPayment: (map['monthly_payment'] as num).toDouble(),
      firstPaymentDate: DateTime.parse(map['first_payment_date'] as String),
      schedule: schedule,
      payments: payments,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  app_models.LoanPayment _mapToLoanPayment(Map<String, dynamic> map) {
    return app_models.LoanPayment(
      id: map['id'] as String,
      paymentNumber: map['payment_number'] as int,
      amount: (map['amount'] as num).toDouble(),
      principal: (map['principal'] as num).toDouble(),
      interest: (map['interest'] as num).toDouble(),
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      paidDate: map['paid_date'] != null 
          ? DateTime.parse(map['paid_date'] as String) 
          : null,
      isPaid: (map['is_paid'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromLoan(app_models.Loan loan) {
    return {
      'id': loan.id,
      'user_id': loan.userId,
      'lender': loan.lender,
      'principal': loan.principal,
      'interest_rate': loan.interestRate,
      'start_date': loan.startDate.toIso8601String(),
      'term_months': loan.termMonths,
      'monthly_payment': loan.monthlyPayment,
      'first_payment_date': loan.firstPaymentDate.toIso8601String(),
      'is_active': loan.isActive ? 1 : 0,
      'created_at': loan.createdAt.toIso8601String(),
      'last_modified': loan.lastModified.toIso8601String(),
      'is_deleted': loan.isDeleted ? 1 : 0,
    };
  }
}