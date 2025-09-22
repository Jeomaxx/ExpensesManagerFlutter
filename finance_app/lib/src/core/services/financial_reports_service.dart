import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/loan.dart';
import '../models/investment.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';

class FinancialReportsService {
  static final FinancialReportsService _instance = FinancialReportsService._internal();
  static FinancialReportsService get instance => _instance;
  FinancialReportsService._internal();

  // CHART DATA GENERATION
  
  Map<String, double> generateCategorySpendingChart(List<Transaction> transactions, {int days = 30}) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final filteredTransactions = transactions
        .where((t) => t.type == TransactionType.expense && t.date.isAfter(startDate))
        .toList();

    final categoryTotals = <String, double>{};
    for (final transaction in filteredTransactions) {
      categoryTotals[transaction.categoryId] = 
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  List<Map<String, dynamic>> generateMonthlyTrendChart(List<Transaction> transactions, {int months = 12}) {
    final trends = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      
      final monthTransactions = transactions.where((t) => 
          t.date.isAfter(month) && t.date.isBefore(nextMonth)).toList();
      
      final income = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final expenses = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      trends.add({
        'month': DateFormatter.formatMonth(month),
        'income': income,
        'expenses': expenses,
        'net': income - expenses,
        'date': month,
      });
    }

    return trends;
  }

  Map<String, double> generateAccountBalanceChart(List<Account> accounts) {
    final balances = <String, double>{};
    for (final account in accounts.where((a) => !a.isDeleted)) {
      balances[account.name] = account.balance;
    }
    return balances;
  }

  List<Map<String, dynamic>> generateBudgetPerformanceChart(List<Budget> budgets, List<Transaction> transactions) {
    final performance = <Map<String, dynamic>>[];
    
    for (final budget in budgets.where((b) => b.isActive)) {
      final spent = transactions
          .where((t) => t.categoryId == budget.categoryId && 
                       t.type == TransactionType.expense &&
                       t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0;
      
      performance.add({
        'category': budget.categoryId,
        'budgeted': budget.amount,
        'spent': spent,
        'remaining': budget.amount - spent,
        'percentage': percentage,
        'status': percentage <= 80 ? 'good' : percentage <= 100 ? 'warning' : 'over',
      });
    }

    return performance;
  }

  Map<String, double> generateInvestmentAllocationChart(List<Investment> investments) {
    final allocation = <String, double>{};
    for (final investment in investments.where((i) => !i.isDeleted)) {
      allocation[investment.type.name] = 
          (allocation[investment.type.name] ?? 0) + (investment.currentValue ?? investment.amount);
    }
    return allocation;
  }

  List<Map<String, dynamic>> generateDebtPayoffChart(List<Loan> loans) {
    final projections = <Map<String, dynamic>>[];
    
    for (final loan in loans.where((l) => l.isActive)) {
      double remainingBalance = loan.remainingBalance;
      DateTime currentDate = DateTime.now();
      
      while (remainingBalance > 0 && projections.length < 60) { // Max 5 years projection
        final monthlyInterest = (remainingBalance * (loan.interestRate / 100)) / 12;
        final monthlyPrincipal = loan.monthlyPayment - monthlyInterest;
        remainingBalance = (remainingBalance - monthlyPrincipal).clamp(0.0, double.infinity);
        
        projections.add({
          'date': currentDate,
          'balance': remainingBalance,
          'payment': loan.monthlyPayment,
          'principal': monthlyPrincipal,
          'interest': monthlyInterest,
          'lender': loan.lender,
        });
        
        currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      }
    }

    return projections;
  }

  // REPORT GENERATION
  
  Map<String, dynamic> generateMonthlyReport(
    List<Transaction> transactions,
    List<Account> accounts,
    List<Budget> budgets,
    List<Goal> goals,
    {DateTime? month}
  ) {
    final reportMonth = month ?? DateTime.now();
    final startDate = DateTime(reportMonth.year, reportMonth.month, 1);
    final endDate = DateTime(reportMonth.year, reportMonth.month + 1, 0);
    
    final monthTransactions = transactions.where((t) => 
        t.date.isAfter(startDate) && t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    
    final totalIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalBalance = accounts
        .where((a) => !a.isDeleted)
        .fold(0.0, (sum, a) => sum + a.balance);
    
    final budgetPerformance = generateBudgetPerformanceChart(budgets, monthTransactions);
    final categorySpending = generateCategorySpendingChart(monthTransactions, days: 30);
    
    final netSavings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0;
    
    return {
      'period': '${DateFormatter.formatMonth(reportMonth)} ${reportMonth.year}',
      'summary': {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netSavings': netSavings,
        'savingsRate': savingsRate,
        'totalBalance': totalBalance,
        'transactionCount': monthTransactions.length,
      },
      'categoryBreakdown': categorySpending,
      'budgetPerformance': budgetPerformance,
      'topExpenses': monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount))
          ..take(10)
          .map((t) => {
            'description': t.description,
            'amount': t.amount,
            'date': t.date,
            'category': t.categoryId,
          }).toList(),
      'goalProgress': goals
          .where((g) => g.isActive)
          .map((g) => {
            'name': g.name,
            'progress': g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) * 100 : 0,
            'current': g.currentAmount,
            'target': g.targetAmount,
          }).toList(),
    };
  }

  Map<String, dynamic> generateYearlyReport(
    List<Transaction> transactions,
    List<Account> accounts,
    List<Investment> investments,
    List<Loan> loans,
    {int? year}
  ) {
    final reportYear = year ?? DateTime.now().year;
    final startDate = DateTime(reportYear, 1, 1);
    final endDate = DateTime(reportYear, 12, 31);
    
    final yearTransactions = transactions.where((t) => 
        t.date.isAfter(startDate) && t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    
    final monthlyTrends = generateMonthlyTrendChart(yearTransactions, months: 12);
    final totalIncome = yearTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalExpenses = yearTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalAssets = accounts.where((a) => !a.isDeleted).fold(0.0, (sum, a) => sum + a.balance);
    final totalInvestments = investments.fold(0.0, (sum, i) => sum + (i.currentValue ?? i.amount));
    final totalDebt = loans.where((l) => l.isActive).fold(0.0, (sum, l) => sum + l.remainingBalance);
    
    final netWorth = totalAssets + totalInvestments - totalDebt;
    
    return {
      'year': reportYear,
      'summary': {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netSavings': totalIncome - totalExpenses,
        'savingsRate': totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0,
        'netWorth': netWorth,
        'totalAssets': totalAssets + totalInvestments,
        'totalDebt': totalDebt,
      },
      'monthlyTrends': monthlyTrends,
      'investmentPerformance': investments.map((i) => {
        'name': i.name,
        'type': i.type.name,
        'invested': i.amount,
        'current': i.currentValue ?? i.amount,
        'roi': i.roi,
        'profitLoss': i.profitLoss,
      }).toList(),
      'debtSummary': loans.where((l) => l.isActive).map((l) => {
        'lender': l.lender,
        'balance': l.remainingBalance,
        'payment': l.monthlyPayment,
        'interestRate': l.interestRate,
      }).toList(),
    };
  }

  // PDF EXPORT
  
  Future<Uint8List> exportMonthlyReportToPDF(Map<String, dynamic> report) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Monthly Financial Report - ${report['period']}',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Income:'),
                      pw.Text(CurrencyFormatter.formatAmount(report['summary']['totalIncome']),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Expenses:'),
                      pw.Text(CurrencyFormatter.formatAmount(report['summary']['totalExpenses']),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Net Savings:'),
                      pw.Text(CurrencyFormatter.formatAmount(report['summary']['netSavings']),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Savings Rate:'),
                      pw.Text('${report['summary']['savingsRate'].toStringAsFixed(1)}%',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Top Expenses
            pw.Text('Top Expenses', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...List.generate(
                  (report['topExpenses'] as List).length.clamp(0, 10),
                  (index) {
                    final expense = report['topExpenses'][index];
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(expense['description'])),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(CurrencyFormatter.formatAmount(expense['amount']))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(DateFormatter.formatDate(expense['date']))),
                      ],
                    );
                  },
                ),
              ],
            ),
          ];
        },
      ),
    );
    
    return pdf.save();
  }

  // CSV EXPORT
  
  String exportTransactionsToCSV(List<Transaction> transactions) {
    final headers = ['Date', 'Description', 'Category', 'Type', 'Amount', 'Account'];
    final rows = transactions.map((t) => [
      DateFormatter.formatDate(t.date),
      t.description,
      t.categoryId,
      t.type.name,
      t.amount.toString(),
      t.accountId,
    ]).toList();
    
    final csvData = [headers, ...rows];
    return csvData.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
  }

  String exportBudgetsToCSV(List<Budget> budgets, List<Transaction> transactions) {
    final headers = ['Category', 'Budgeted Amount', 'Spent Amount', 'Remaining', 'Status'];
    final performance = generateBudgetPerformanceChart(budgets, transactions);
    
    final rows = performance.map((p) => [
      p['category'],
      p['budgeted'].toString(),
      p['spent'].toString(),
      p['remaining'].toString(),
      p['status'],
    ]).toList();
    
    final csvData = [headers, ...rows];
    return csvData.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
  }

  // ANALYTICS
  
  Map<String, dynamic> calculateFinancialKPIs(
    List<Transaction> transactions,
    List<Account> accounts,
    List<Investment> investments,
    List<Loan> loans,
  ) {
    final now = DateTime.now();
    final lastMonth = transactions.where((t) => 
        t.date.isAfter(DateTime(now.year, now.month - 1, 1)) &&
        t.date.isBefore(DateTime(now.year, now.month, 1))).toList();
    
    final monthlyIncome = lastMonth
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = lastMonth
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalAssets = accounts.where((a) => !a.isDeleted).fold(0.0, (sum, a) => sum + a.balance);
    final totalInvestments = investments.fold(0.0, (sum, i) => sum + (i.currentValue ?? i.amount));
    final totalDebt = loans.where((l) => l.isActive).fold(0.0, (sum, l) => sum + l.remainingBalance);
    final monthlyDebtPayments = loans.where((l) => l.isActive).fold(0.0, (sum, l) => sum + l.monthlyPayment);
    
    final netWorth = totalAssets + totalInvestments - totalDebt;
    final savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100 : 0;
    final debtToIncomeRatio = monthlyIncome > 0 ? (monthlyDebtPayments / monthlyIncome) * 100 : 0;
    final emergencyFundMonths = monthlyExpenses > 0 ? totalAssets / monthlyExpenses : 0;
    
    return {
      'netWorth': netWorth,
      'savingsRate': savingsRate,
      'debtToIncomeRatio': debtToIncomeRatio,
      'emergencyFundMonths': emergencyFundMonths,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'totalAssets': totalAssets + totalInvestments,
      'totalDebt': totalDebt,
      'investmentROI': investments.isNotEmpty 
          ? investments.fold(0.0, (sum, i) => sum + i.roi) / investments.length 
          : 0,
    };
  }
}