import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/loan.dart';
import '../models/investment.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/account_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/investment_repository.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

enum ExportFormat {
  json,
  csv,
  pdf,
  excel,
}

enum ImportResult {
  success,
  error,
  partialSuccess,
}

class ExportOptions {
  final ExportFormat format;
  final bool includeDeleted;
  final bool passwordProtect;
  final String? password;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? selectedCategories;
  final List<String>? selectedAccounts;

  const ExportOptions({
    required this.format,
    this.includeDeleted = false,
    this.passwordProtect = false,
    this.password,
    this.startDate,
    this.endDate,
    this.selectedCategories,
    this.selectedAccounts,
  });
}

class ImportOptions {
  final bool overwriteExisting;
  final bool validateData;
  final bool createMissingCategories;
  final bool createMissingAccounts;
  final String? defaultAccountId;
  final String? defaultCategoryId;

  const ImportOptions({
    this.overwriteExisting = false,
    this.validateData = true,
    this.createMissingCategories = true,
    this.createMissingAccounts = true,
    this.defaultAccountId,
    this.defaultCategoryId,
  });
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int itemsExported;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.itemsExported = 0,
  });
}

class ImportResultData {
  final ImportResult result;
  final int itemsImported;
  final int itemsSkipped;
  final int itemsFailed;
  final List<String> errors;
  final String? message;

  const ImportResultData({
    required this.result,
    this.itemsImported = 0,
    this.itemsSkipped = 0,
    this.itemsFailed = 0,
    this.errors = const [],
    this.message,
  });
}

class DataExportImportService {
  static final DataExportImportService _instance = DataExportImportService._internal();
  static DataExportImportService get instance => _instance;
  DataExportImportService._internal();

  // Repositories
  late TransactionRepository _transactionRepo;
  late AccountRepository _accountRepo;
  late BudgetRepository _budgetRepo;
  late GoalRepository _goalRepo;
  late LoanRepository _loanRepo;
  late InvestmentRepository _investmentRepo;

  void initialize() {
    _transactionRepo = TransactionRepository.instance;
    _accountRepo = AccountRepository.instance;
    _budgetRepo = BudgetRepository.instance;
    _goalRepo = GoalRepository.instance;
    _loanRepo = LoanRepository.instance;
    _investmentRepo = InvestmentRepository.instance;
    
    print('Data Export/Import service initialized');
  }

  // EXPORT METHODS

  Future<ExportResult> exportAllData(String userId, ExportOptions options) async {
    try {
      // Gather all data
      final data = await _gatherAllUserData(userId, options);
      
      // Export based on format
      switch (options.format) {
        case ExportFormat.json:
          return await _exportToJson(data, options);
        case ExportFormat.csv:
          return await _exportToCsv(data, options);
        case ExportFormat.pdf:
          return await _exportToPdf(data, options);
        case ExportFormat.excel:
          return await _exportToExcel(data, options);
      }
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> exportTransactions(String userId, ExportOptions options) async {
    try {
      final transactions = await _transactionRepo.getTransactionsByUserId(
        userId: userId,
        startDate: options.startDate,
        endDate: options.endDate,
      );

      final filteredTransactions = transactions.where((t) {
        if (!options.includeDeleted && t.isDeleted) return false;
        if (options.selectedCategories != null && 
            !options.selectedCategories!.contains(t.categoryId)) return false;
        if (options.selectedAccounts != null && 
            !options.selectedAccounts!.contains(t.accountId)) return false;
        return true;
      }).toList();

      switch (options.format) {
        case ExportFormat.json:
          return await _exportTransactionsToJson(filteredTransactions, options);
        case ExportFormat.csv:
          return await _exportTransactionsToCsv(filteredTransactions, options);
        case ExportFormat.pdf:
          return await _exportTransactionsToPdf(filteredTransactions, options);
        case ExportFormat.excel:
          return await _exportTransactionsToExcel(filteredTransactions, options);
      }
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'Transaction export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> _exportToJson(Map<String, dynamic> data, ExportOptions options) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'finance_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      if (options.passwordProtect && options.password != null) {
        // In a real implementation, you would encrypt the data here
        // For now, we'll just add a header indicating it should be encrypted
        await file.writeAsString('ENCRYPTED:${options.password}\n$jsonString');
      } else {
        await file.writeAsString(jsonString);
      }

      return ExportResult(
        success: true,
        filePath: file.path,
        itemsExported: _countItemsInData(data),
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'JSON export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> _exportTransactionsToCsv(List<Transaction> transactions, ExportOptions options) async {
    try {
      final csvData = <List<dynamic>>[
        // Headers
        ['Date', 'Description', 'Category', 'Account', 'Type', 'Amount', 'Notes'],
        // Data rows
        ...transactions.map((t) => [
          DateFormatter.formatDate(t.date),
          t.description,
          t.categoryId,
          t.accountId,
          t.type.name,
          t.amount,
          t.notes ?? '',
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvString);

      return ExportResult(
        success: true,
        filePath: file.path,
        itemsExported: transactions.length,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'CSV export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> _exportTransactionsToJson(List<Transaction> transactions, ExportOptions options) async {
    try {
      final data = {
        'export_info': {
          'type': 'transactions',
          'created_at': DateTime.now().toIso8601String(),
          'version': '1.0',
          'count': transactions.length,
        },
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

      return await _exportToJson(data, options);
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'JSON transaction export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> _exportToCsv(Map<String, dynamic> data, ExportOptions options) async {
    // For full data export to CSV, we'll create multiple CSV files in a folder
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/finance_export_${DateTime.now().millisecondsSinceEpoch}');
      await exportDir.create();

      int totalItems = 0;

      // Export transactions
      if (data['transactions'] != null) {
        final transactions = (data['transactions'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList();
        await _exportTransactionsToCsv(transactions, options.copyWith(
          filePath: '${exportDir.path}/transactions.csv'
        ));
        totalItems += transactions.length;
      }

      // Export accounts, budgets, goals, etc. similarly...

      return ExportResult(
        success: true,
        filePath: exportDir.path,
        itemsExported: totalItems,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: 'CSV export failed: ${e.toString()}',
      );
    }
  }

  Future<ExportResult> _exportToPdf(Map<String, dynamic> data, ExportOptions options) async {
    // PDF export would use the financial reports service
    return ExportResult(
      success: false,
      error: 'PDF export not yet implemented for full data',
    );
  }

  Future<ExportResult> _exportTransactionsToPdf(List<Transaction> transactions, ExportOptions options) async {
    // This would use the financial reports service to generate a PDF
    return ExportResult(
      success: false,
      error: 'PDF export not yet implemented for transactions',
    );
  }

  Future<ExportResult> _exportToExcel(Map<String, dynamic> data, ExportOptions options) async {
    return ExportResult(
      success: false,
      error: 'Excel export not yet implemented',
    );
  }

  Future<ExportResult> _exportTransactionsToExcel(List<Transaction> transactions, ExportOptions options) async {
    return ExportResult(
      success: false,
      error: 'Excel export not yet implemented',
    );
  }

  // IMPORT METHODS

  Future<ImportResultData> importFromFile(String userId, ImportOptions options) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result == null || result.files.isEmpty) {
        return const ImportResultData(
          result: ImportResult.error,
          errors: ['No file selected'],
        );
      }

      final file = File(result.files.first.path!);
      final extension = result.files.first.extension?.toLowerCase();

      switch (extension) {
        case 'json':
          return await _importFromJson(file, userId, options);
        case 'csv':
          return await _importFromCsv(file, userId, options);
        default:
          return const ImportResultData(
            result: ImportResult.error,
            errors: ['Unsupported file format'],
          );
      }
    } catch (e) {
      return ImportResultData(
        result: ImportResult.error,
        errors: ['Import failed: ${e.toString()}'],
      );
    }
  }

  Future<ImportResultData> _importFromJson(File file, String userId, ImportOptions options) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Check if it's encrypted
      if (content.startsWith('ENCRYPTED:')) {
        return const ImportResultData(
          result: ImportResult.error,
          errors: ['Encrypted files not yet supported'],
        );
      }

      int imported = 0;
      int skipped = 0;
      int failed = 0;
      final errors = <String>[];

      // Import transactions
      if (data['transactions'] != null) {
        final result = await _importTransactions(
          (data['transactions'] as List).cast<Map<String, dynamic>>(),
          userId,
          options,
        );
        imported += result.itemsImported;
        skipped += result.itemsSkipped;
        failed += result.itemsFailed;
        errors.addAll(result.errors);
      }

      // Import other data types similarly...

      return ImportResultData(
        result: failed == 0 ? ImportResult.success : ImportResult.partialSuccess,
        itemsImported: imported,
        itemsSkipped: skipped,
        itemsFailed: failed,
        errors: errors,
        message: 'Imported $imported items successfully',
      );

    } catch (e) {
      return ImportResultData(
        result: ImportResult.error,
        errors: ['JSON import failed: ${e.toString()}'],
      );
    }
  }

  Future<ImportResultData> _importFromCsv(File file, String userId, ImportOptions options) async {
    try {
      final content = await file.readAsString();
      final csvData = const CsvToListConverter().convert(content);

      if (csvData.isEmpty) {
        return const ImportResultData(
          result: ImportResult.error,
          errors: ['CSV file is empty'],
        );
      }

      // Assume it's transactions CSV based on headers
      final headers = csvData.first.map((h) => h.toString().toLowerCase()).toList();
      
      if (!headers.contains('amount') || !headers.contains('date')) {
        return const ImportResultData(
          result: ImportResult.error,
          errors: ['CSV file does not appear to contain transaction data'],
        );
      }

      final transactions = <Map<String, dynamic>>[];
      
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final transaction = <String, dynamic>{};
        
        for (int j = 0; j < headers.length && j < row.length; j++) {
          transaction[headers[j]] = row[j];
        }
        
        transactions.add(transaction);
      }

      return await _importTransactions(transactions, userId, options);

    } catch (e) {
      return ImportResultData(
        result: ImportResult.error,
        errors: ['CSV import failed: ${e.toString()}'],
      );
    }
  }

  Future<ImportResultData> _importTransactions(
    List<Map<String, dynamic>> transactionData,
    String userId,
    ImportOptions options,
  ) async {
    int imported = 0;
    int skipped = 0;
    int failed = 0;
    final errors = <String>[];

    for (final data in transactionData) {
      try {
        // Validate and transform data
        final transaction = _mapToTransaction(data, userId, options);
        
        if (transaction == null) {
          skipped++;
          continue;
        }

        // Check if transaction already exists
        if (!options.overwriteExisting) {
          final existing = await _transactionRepo.getTransactionById(transaction.id);
          if (existing != null) {
            skipped++;
            continue;
          }
        }

        // Import the transaction
        await _transactionRepo.createTransaction(transaction);
        imported++;

      } catch (e) {
        failed++;
        errors.add('Failed to import transaction: ${e.toString()}');
      }
    }

    return ImportResultData(
      result: failed == 0 ? ImportResult.success : ImportResult.partialSuccess,
      itemsImported: imported,
      itemsSkipped: skipped,
      itemsFailed: failed,
      errors: errors,
    );
  }

  // HELPER METHODS

  Future<Map<String, dynamic>> _gatherAllUserData(String userId, ExportOptions options) async {
    final data = <String, dynamic>{
      'export_info': {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'options': {
          'include_deleted': options.includeDeleted,
          'start_date': options.startDate?.toIso8601String(),
          'end_date': options.endDate?.toIso8601String(),
        },
      },
    };

    // Gather transactions
    final transactions = await _transactionRepo.getTransactionsByUserId(
      userId: userId,
      startDate: options.startDate,
      endDate: options.endDate,
    );
    data['transactions'] = transactions
        .where((t) => options.includeDeleted || !t.isDeleted)
        .map((t) => t.toJson())
        .toList();

    // Gather accounts
    final accounts = await _accountRepo.getAccountsByUserId(userId);
    data['accounts'] = accounts
        .where((a) => options.includeDeleted || !a.isDeleted)
        .map((a) => a.toJson())
        .toList();

    // Gather budgets
    final budgets = await _budgetRepo.getBudgetsByUserId(userId);
    data['budgets'] = budgets.map((b) => b.toJson()).toList();

    // Gather goals
    final goals = await _goalRepo.getGoalsByUserId(userId);
    data['goals'] = goals.map((g) => g.toJson()).toList();

    // Gather loans
    final loans = await _loanRepo.getLoansByUserId(userId);
    data['loans'] = loans.map((l) => l.toJson()).toList();

    // Gather investments
    final investments = await _investmentRepo.getInvestmentsByUserId(userId);
    data['investments'] = investments.map((i) => i.toJson()).toList();

    return data;
  }

  Transaction? _mapToTransaction(Map<String, dynamic> data, String userId, ImportOptions options) {
    try {
      // This is a simplified mapping - in reality, you'd need more robust parsing
      return Transaction(
        id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        accountId: data['account_id']?.toString() ?? options.defaultAccountId ?? '',
        categoryId: data['category_id']?.toString() ?? options.defaultCategoryId ?? '',
        amount: double.parse(data['amount'].toString()),
        description: data['description']?.toString() ?? '',
        notes: data['notes']?.toString(),
        date: DateTime.parse(data['date'].toString()),
        type: TransactionType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => TransactionType.expense,
        ),
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        isDeleted: false,
      );
    } catch (e) {
      print('Error mapping transaction: $e');
      return null;
    }
  }

  int _countItemsInData(Map<String, dynamic> data) {
    int count = 0;
    if (data['transactions'] != null) count += (data['transactions'] as List).length;
    if (data['accounts'] != null) count += (data['accounts'] as List).length;
    if (data['budgets'] != null) count += (data['budgets'] as List).length;
    if (data['goals'] != null) count += (data['goals'] as List).length;
    if (data['loans'] != null) count += (data['loans'] as List).length;
    if (data['investments'] != null) count += (data['investments'] as List).length;
    return count;
  }
}

// Extension to add missing copyWith method to ExportOptions
extension ExportOptionsExtension on ExportOptions {
  ExportOptions copyWith({
    ExportFormat? format,
    bool? includeDeleted,
    bool? passwordProtect,
    String? password,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedCategories,
    List<String>? selectedAccounts,
    String? filePath,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      passwordProtect: passwordProtect ?? this.passwordProtect,
      password: password ?? this.password,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedAccounts: selectedAccounts ?? this.selectedAccounts,
    );
  }
}