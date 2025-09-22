import '../models/budget.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';

class BudgetRepository {
  final DatabaseService _databaseService;

  static const String _tableName = 'budgets';

  BudgetRepository(this._databaseService);

  static final BudgetRepository _instance = BudgetRepository(DatabaseService.instance);
  static BudgetRepository get instance => _instance;


  // Create a new budget
  Future<Budget> createBudget(Budget budget) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, budget.toMap());
    return budget;
  }

  // Get all budgets for a user
  Future<List<Budget>> getBudgetsByUserId(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get active budgets for a user
  Future<List<Budget>> getActiveBudgetsByUserId(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get budgets by category
  Future<List<Budget>> getBudgetsByCategory(String categoryId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category_id = ? AND is_active = 1',
      whereArgs: [categoryId],
      orderBy: 'start_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get current active budgets (within date range)
  Future<List<Budget>> getCurrentActiveBudgets(String userId) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_active = 1 AND start_date <= ? AND end_date >= ?',
      whereArgs: [userId, now, now],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get budget by ID
  Future<Budget?> getBudgetById(String budgetId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [budgetId],
    );

    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  // Update budget
  Future<Budget> updateBudget(Budget budget) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    return budget;
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    final db = await _databaseService.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  // Calculate spending for a budget within its date range
  Future<double> getBudgetSpending(String userId, String categoryId, DateTime startDate, DateTime endDate) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT SUM(amount) as total 
         FROM transactions 
         WHERE user_id = ? 
           AND category_id = ? 
           AND type = ? 
           AND date >= ? 
           AND date <= ?
           AND is_deleted = 0''',
      [
        userId, 
        categoryId, 
        'expense',
        startDate.toIso8601String(),
        endDate.toIso8601String()
      ],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get budget spending count (number of transactions)
  Future<int> getBudgetTransactionCount(String userId, String categoryId, DateTime startDate, DateTime endDate) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT COUNT(*) as count 
         FROM transactions 
         WHERE user_id = ? 
           AND category_id = ? 
           AND type = ? 
           AND date >= ? 
           AND date <= ?
           AND is_deleted = 0''',
      [
        userId, 
        categoryId, 
        'expense',
        startDate.toIso8601String(),
        endDate.toIso8601String()
      ],
    );

    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  // Get budget with spending data
  Future<BudgetWithSpending?> getBudgetWithSpending(String budgetId, String userId) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) return null;

    final spent = await getBudgetSpending(
      userId, 
      budget.categoryId, 
      budget.startDate, 
      budget.endDate
    );

    final transactionCount = await getBudgetTransactionCount(
      userId, 
      budget.categoryId, 
      budget.startDate, 
      budget.endDate
    );

    return BudgetWithSpending.fromBudget(budget, spent, transactionCount);
  }

  // Get all budgets with spending data
  Future<List<BudgetWithSpending>> getBudgetsWithSpending(String userId) async {
    final budgets = await getActiveBudgetsByUserId(userId);
    final List<BudgetWithSpending> budgetsWithSpending = [];

    for (final budget in budgets) {
      final spent = await getBudgetSpending(
        userId, 
        budget.categoryId, 
        budget.startDate, 
        budget.endDate
      );

      final transactionCount = await getBudgetTransactionCount(
        userId, 
        budget.categoryId, 
        budget.startDate, 
        budget.endDate
      );

      budgetsWithSpending.add(
        BudgetWithSpending.fromBudget(budget, spent, transactionCount)
      );
    }

    return budgetsWithSpending;
  }

  // Check if budget exists for category in date range
  Future<bool> budgetExistsForCategory(String userId, String categoryId, DateTime startDate, DateTime endDate, {String? excludeBudgetId}) async {
    final db = await _databaseService.database;
    
    String where = 'user_id = ? AND category_id = ? AND is_active = 1 AND ((start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?))';
    List<dynamic> whereArgs = [
      userId, 
      categoryId, 
      startDate.toIso8601String(), startDate.toIso8601String(),
      endDate.toIso8601String(), endDate.toIso8601String(),
      startDate.toIso8601String(), endDate.toIso8601String(),
    ];

    if (excludeBudgetId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeBudgetId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
    );

    return maps.isNotEmpty;
  }

  // Get over-budget alerts (budgets that exceeded 80% or 100%)
  Future<List<BudgetWithSpending>> getBudgetAlerts(String userId) async {
    final budgetsWithSpending = await getBudgetsWithSpending(userId);
    return budgetsWithSpending.where((budget) => 
      budget.status == BudgetStatus.warning || budget.status == BudgetStatus.exceeded
    ).toList();
  }
}