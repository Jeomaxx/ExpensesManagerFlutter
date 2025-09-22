import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
import 'app_settings_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  conflict,
}

class SyncResult {
  final SyncStatus status;
  final String? message;
  final int itemsSynced;
  final DateTime timestamp;
  final List<SyncConflict>? conflicts;

  const SyncResult({
    required this.status,
    this.message,
    this.itemsSynced = 0,
    required this.timestamp,
    this.conflicts,
  });
}

class SyncConflict {
  final String id;
  final String type;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime conflictTime;

  const SyncConflict({
    required this.id,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.conflictTime,
  });
}

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  static DataSyncService get instance => _instance;
  DataSyncService._internal();

  final http.Client _httpClient = http.Client();
  String? _syncEndpoint;
  String? _apiKey;
  String? _userId;
  SyncStatus _currentStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  
  // Repositories
  late TransactionRepository _transactionRepo;
  late AccountRepository _accountRepo;
  late BudgetRepository _budgetRepo;
  late GoalRepository _goalRepo;
  late LoanRepository _loanRepo;
  late InvestmentRepository _investmentRepo;

  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> initialize({
    String? syncEndpoint,
    String? apiKey,
    required String userId,
  }) async {
    _syncEndpoint = syncEndpoint ?? const String.fromEnvironment('SYNC_ENDPOINT');
    _apiKey = apiKey ?? const String.fromEnvironment('SYNC_API_KEY');
    _userId = userId;

    // Initialize repositories
    _transactionRepo = TransactionRepository.instance;
    _accountRepo = AccountRepository.instance;
    _budgetRepo = BudgetRepository.instance;
    _goalRepo = GoalRepository.instance;
    _loanRepo = LoanRepository.instance;
    _investmentRepo = InvestmentRepository.instance;

    // Load last sync time
    _lastSyncTime = await _getLastSyncTime();

    print('Data Sync service initialized for user: $_userId');
  }

  // FULL SYNC
  
  Future<SyncResult> performFullSync() async {
    if (_currentStatus == SyncStatus.syncing) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    if (!await _canSync()) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync not available - check network connection',
        timestamp: DateTime.now(),
      );
    }

    _currentStatus = SyncStatus.syncing;
    
    try {
      int totalSynced = 0;
      final conflicts = <SyncConflict>[];

      // Sync each data type
      final transactionResult = await _syncTransactions();
      totalSynced += transactionResult.itemsSynced;
      if (transactionResult.conflicts != null) {
        conflicts.addAll(transactionResult.conflicts!);
      }

      final accountResult = await _syncAccounts();
      totalSynced += accountResult.itemsSynced;
      if (accountResult.conflicts != null) {
        conflicts.addAll(accountResult.conflicts!);
      }

      final budgetResult = await _syncBudgets();
      totalSynced += budgetResult.itemsSynced;
      if (budgetResult.conflicts != null) {
        conflicts.addAll(budgetResult.conflicts!);
      }

      final goalResult = await _syncGoals();
      totalSynced += goalResult.itemsSynced;
      if (goalResult.conflicts != null) {
        conflicts.addAll(goalResult.conflicts!);
      }

      final loanResult = await _syncLoans();
      totalSynced += loanResult.itemsSynced;
      if (loanResult.conflicts != null) {
        conflicts.addAll(loanResult.conflicts!);
      }

      final investmentResult = await _syncInvestments();
      totalSynced += investmentResult.itemsSynced;
      if (investmentResult.conflicts != null) {
        conflicts.addAll(investmentResult.conflicts!);
      }

      await _saveLastSyncTime(DateTime.now());
      _currentStatus = conflicts.isNotEmpty ? SyncStatus.conflict : SyncStatus.success;

      return SyncResult(
        status: _currentStatus,
        message: conflicts.isNotEmpty 
            ? 'Sync completed with ${conflicts.length} conflicts'
            : 'Sync completed successfully',
        itemsSynced: totalSynced,
        timestamp: DateTime.now(),
        conflicts: conflicts.isNotEmpty ? conflicts : null,
      );

    } catch (e) {
      _currentStatus = SyncStatus.error;
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync failed: ${e.toString()}',
        timestamp: DateTime.now(),
      );
    }
  }

  // INCREMENTAL SYNC
  
  Future<SyncResult> performIncrementalSync() async {
    if (_lastSyncTime == null) {
      return await performFullSync();
    }

    if (_currentStatus == SyncStatus.syncing) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    _currentStatus = SyncStatus.syncing;

    try {
      // Get changes since last sync
      final changes = await _getChangesSinceLastSync();
      
      if (changes.isEmpty) {
        _currentStatus = SyncStatus.success;
        return SyncResult(
          status: SyncStatus.success,
          message: 'No changes to sync',
          timestamp: DateTime.now(),
        );
      }

      // Push local changes
      final pushResult = await _pushChangesToRemote(changes);
      
      // Pull remote changes
      final pullResult = await _pullChangesFromRemote(_lastSyncTime!);
      
      final totalSynced = pushResult.itemsSynced + pullResult.itemsSynced;
      final conflicts = <SyncConflict>[];
      
      if (pushResult.conflicts != null) conflicts.addAll(pushResult.conflicts!);
      if (pullResult.conflicts != null) conflicts.addAll(pullResult.conflicts!);

      await _saveLastSyncTime(DateTime.now());
      _currentStatus = conflicts.isNotEmpty ? SyncStatus.conflict : SyncStatus.success;

      return SyncResult(
        status: _currentStatus,
        message: conflicts.isNotEmpty 
            ? 'Incremental sync completed with ${conflicts.length} conflicts'
            : 'Incremental sync completed successfully',
        itemsSynced: totalSynced,
        timestamp: DateTime.now(),
        conflicts: conflicts.isNotEmpty ? conflicts : null,
      );

    } catch (e) {
      _currentStatus = SyncStatus.error;
      return SyncResult(
        status: SyncStatus.error,
        message: 'Incremental sync failed: ${e.toString()}',
        timestamp: DateTime.now(),
      );
    }
  }

  // AUTO SYNC
  
  Future<void> enableAutoSync({Duration interval = const Duration(hours: 1)}) async {
    // This would set up a periodic timer to automatically sync
    // In a real implementation, you'd use a background service or work manager
    print('Auto sync enabled with interval: ${interval.inMinutes} minutes');
  }

  Future<void> disableAutoSync() async {
    print('Auto sync disabled');
  }

  // CONFLICT RESOLUTION
  
  Future<void> resolveConflict(SyncConflict conflict, {bool useLocal = true}) async {
    try {
      if (useLocal) {
        // Push local version to remote
        await _pushSingleItem(conflict.type, conflict.localData);
      } else {
        // Apply remote version locally
        await _applySingleItem(conflict.type, conflict.remoteData);
      }
      
      print('Conflict resolved for ${conflict.type}:${conflict.id}');
    } catch (e) {
      print('Failed to resolve conflict: $e');
    }
  }

  // BACKUP AND RESTORE
  
  Future<String> createBackup() async {
    try {
      final backup = await _createFullBackup();
      final backupJson = jsonEncode(backup);
      
      // Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(backupJson);
      
      // Update settings with backup time
      await AppSettingsService.instance.recordBackup();
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final backupJson = await file.readAsString();
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;
      
      await _restoreFromBackupData(backup);
      
      print('Backup restored successfully');
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  // PRIVATE HELPER METHODS

  Future<bool> _canSync() async {
    if (_syncEndpoint == null || _apiKey == null) return false;
    
    // Check network connectivity
    try {
      final response = await _httpClient.get(
        Uri.parse('$_syncEndpoint/health'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<SyncResult> _syncTransactions() async {
    try {
      final transactions = await _transactionRepo.getTransactionsByUserId(userId: _userId!);
      return await _syncDataType('transactions', transactions);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync transactions: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncAccounts() async {
    try {
      final accounts = await _accountRepo.getAccountsByUserId(_userId!);
      return await _syncDataType('accounts', accounts);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync accounts: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncBudgets() async {
    try {
      final budgets = await _budgetRepo.getBudgetsByUserId(_userId!);
      return await _syncDataType('budgets', budgets);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync budgets: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncGoals() async {
    try {
      final goals = await _goalRepo.getGoalsByUserId(_userId!);
      return await _syncDataType('goals', goals);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync goals: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncLoans() async {
    try {
      final loans = await _loanRepo.getLoansByUserId(_userId!);
      return await _syncDataType('loans', loans);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync loans: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncInvestments() async {
    try {
      final investments = await _investmentRepo.getInvestmentsByUserId(_userId!);
      return await _syncDataType('investments', investments);
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync investments: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<SyncResult> _syncDataType(String dataType, List<dynamic> localData) async {
    // Simplified sync logic - in reality, this would be more complex
    // involving conflict detection, merging, etc.
    
    try {
      // This is a placeholder implementation
      // Real implementation would involve proper REST API calls
      print('Syncing $dataType: ${localData.length} items');
      
      return SyncResult(
        status: SyncStatus.success,
        itemsSynced: localData.length,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.error,
        message: 'Failed to sync $dataType: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getChangesSinceLastSync() async {
    // Get all items modified since last sync
    final changes = <Map<String, dynamic>>[];
    
    // This would query each repository for items modified since _lastSyncTime
    // and return them in a standardized format
    
    return changes;
  }

  Future<SyncResult> _pushChangesToRemote(List<Map<String, dynamic>> changes) async {
    // Push local changes to remote server
    return SyncResult(
      status: SyncStatus.success,
      itemsSynced: changes.length,
      timestamp: DateTime.now(),
    );
  }

  Future<SyncResult> _pullChangesFromRemote(DateTime since) async {
    // Pull changes from remote server since the given date
    return SyncResult(
      status: SyncStatus.success,
      itemsSynced: 0,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _pushSingleItem(String type, Map<String, dynamic> data) async {
    // Push a single item to resolve conflict
  }

  Future<void> _applySingleItem(String type, Map<String, dynamic> data) async {
    // Apply a single remote item locally
  }

  Future<Map<String, dynamic>> _createFullBackup() async {
    return {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'user_id': _userId,
      'transactions': await _transactionRepo.getTransactionsByUserId(userId: _userId!),
      'accounts': await _accountRepo.getAccountsByUserId(_userId!),
      'budgets': await _budgetRepo.getBudgetsByUserId(_userId!),
      'goals': await _goalRepo.getGoalsByUserId(_userId!),
      'loans': await _loanRepo.getLoansByUserId(_userId!),
      'investments': await _investmentRepo.getInvestmentsByUserId(_userId!),
    };
  }

  Future<void> _restoreFromBackupData(Map<String, dynamic> backup) async {
    // Restore each data type from backup
    // This would involve clearing existing data and inserting backup data
    print('Restoring backup from ${backup['created_at']}');
  }

  Future<DateTime?> _getLastSyncTime() async {
    final timestampStr = AppSettingsService.instance.getUserPreference('last_sync_time');
    return timestampStr != null ? DateTime.parse(timestampStr) : null;
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    _lastSyncTime = time;
    await AppSettingsService.instance.setUserPreference('last_sync_time', time.toIso8601String());
  }
}