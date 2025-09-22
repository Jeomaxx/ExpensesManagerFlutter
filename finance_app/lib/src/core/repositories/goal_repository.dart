import '../models/goal.dart';
import '../services/database_service.dart';

class GoalRepository {
  final DatabaseService _databaseService;
  static const String _tableName = 'goals';

  GoalRepository(this._databaseService);

  static final GoalRepository _instance = GoalRepository(DatabaseService.instance);
  static GoalRepository get instance => _instance;

  // Create a new goal
  Future<Goal> createGoal(Goal goal) async {
    final db = await _databaseService.database;
    final goalData = _goalToMap(goal);
    await db.insert(_tableName, goalData);
    return goal;
  }

  // Get all goals for a user
  Future<List<Goal>> getGoalsByUserId(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'target_date ASC',
    );

    return List.generate(maps.length, (i) {
      return _goalFromMap(maps[i]);
    });
  }

  // Get active goals for a user
  Future<List<Goal>> getActiveGoals(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_completed = 0 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'target_date ASC',
    );

    return List.generate(maps.length, (i) {
      return _goalFromMap(maps[i]);
    });
  }

  // Get completed goals for a user
  Future<List<Goal>> getCompletedGoals(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND is_completed = 1 AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'last_modified DESC',
    );

    return List.generate(maps.length, (i) {
      return _goalFromMap(maps[i]);
    });
  }

  // Get goal by ID
  Future<Goal?> getGoalById(String goalId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [goalId],
    );

    if (maps.isNotEmpty) {
      return _goalFromMap(maps.first);
    }
    return null;
  }

  // Update goal
  Future<Goal> updateGoal(Goal goal) async {
    final db = await _databaseService.database;
    final goalData = _goalToMap(goal);
    await db.update(
      _tableName,
      goalData,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    return goal;
  }

  // Add contribution to goal
  Future<Goal> addContribution(String goalId, double amount, {String? note}) async {
    final goal = await getGoalById(goalId);
    if (goal == null) throw Exception('Goal not found');

    final newContribution = GoalContribution(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: DateTime.now(),
      notes: note,
    );

    final updatedContributions = List<GoalContribution>.from(goal.contributions)
      ..add(newContribution);

    final updatedGoal = goal.copyWith(
      contributions: updatedContributions,
      currentAmount: goal.currentAmount + amount,
      lastModified: DateTime.now(),
      isCompleted: (goal.currentAmount + amount) >= goal.targetAmount,
    );

    return await updateGoal(updatedGoal);
  }

  // Remove contribution from goal
  Future<Goal> removeContribution(String goalId, String contributionId) async {
    final goal = await getGoalById(goalId);
    if (goal == null) throw Exception('Goal not found');

    final contributionToRemove = goal.contributions
        .where((c) => c.id == contributionId)
        .isNotEmpty ? goal.contributions.where((c) => c.id == contributionId).first : null;

    if (contributionToRemove == null) throw Exception('Contribution not found');

    final updatedContributions = goal.contributions
        .where((c) => c.id != contributionId)
        .toList();

    final updatedGoal = goal.copyWith(
      contributions: updatedContributions,
      currentAmount: goal.currentAmount - contributionToRemove.amount,
      lastModified: DateTime.now(),
      isCompleted: false, // Reset completion if removing contribution
    );

    return await updateGoal(updatedGoal);
  }

  // Mark goal as completed
  Future<Goal> markGoalCompleted(String goalId) async {
    final goal = await getGoalById(goalId);
    if (goal == null) throw Exception('Goal not found');

    final updatedGoal = goal.copyWith(
      isCompleted: true,
      lastModified: DateTime.now(),
    );

    return await updateGoal(updatedGoal);
  }

  // Delete goal (soft delete)
  Future<void> deleteGoal(String goalId) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      {
        'is_deleted': 1,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // Get goals by linked account
  Future<List<Goal>> getGoalsByAccountId(String userId, String accountId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND linked_account_id = ? AND is_deleted = 0',
      whereArgs: [userId, accountId],
      orderBy: 'target_date ASC',
    );

    return List.generate(maps.length, (i) {
      return _goalFromMap(maps[i]);
    });
  }

  // Get overdue goals
  Future<List<Goal>> getOverdueGoals(String userId) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'user_id = ? AND target_date < ? AND is_completed = 0 AND is_deleted = 0',
      whereArgs: [userId, now],
      orderBy: 'target_date ASC',
    );

    return List.generate(maps.length, (i) {
      return _goalFromMap(maps[i]);
    });
  }

  // Get goals summary for dashboard
  Future<Map<String, dynamic>> getGoalsSummary(String userId) async {
    final db = await _databaseService.database;
    
    // Total goals count
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );
    final totalGoals = (totalResult.first['count'] as num?)?.toInt() ?? 0;

    // Active goals count
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ? AND is_completed = 0 AND is_deleted = 0',
      [userId],
    );
    final activeGoals = (activeResult.first['count'] as num?)?.toInt() ?? 0;

    // Completed goals count
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ? AND is_completed = 1 AND is_deleted = 0',
      [userId],
    );
    final completedGoals = (completedResult.first['count'] as num?)?.toInt() ?? 0;

    // Total target amount
    final targetAmountResult = await db.rawQuery(
      'SELECT SUM(target_amount) as total FROM $_tableName WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );
    final totalTargetAmount = (targetAmountResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Total saved amount
    final savedAmountResult = await db.rawQuery(
      'SELECT SUM(current_amount) as total FROM $_tableName WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );
    final totalSavedAmount = (savedAmountResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return {
      'totalGoals': totalGoals,
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
      'totalTargetAmount': totalTargetAmount,
      'totalSavedAmount': totalSavedAmount,
      'overallProgress': totalTargetAmount > 0 ? (totalSavedAmount / totalTargetAmount * 100) : 0.0,
    };
  }

  // Convert Goal to database map
  Map<String, dynamic> _goalToMap(Goal goal) {
    return {
      'id': goal.id,
      'user_id': goal.userId,
      'title': goal.title,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'target_date': goal.targetDate.toIso8601String(),
      'linked_account_id': goal.linkedAccountId,
      'contributions': goal.contributions.map((c) => c.toJson()).toList().toString(),
      'is_completed': goal.isCompleted ? 1 : 0,
      'created_at': goal.createdAt.toIso8601String(),
      'last_modified': goal.lastModified.toIso8601String(),
    };
  }

  // Convert database map to Goal
  Goal _goalFromMap(Map<String, dynamic> map) {
    // Parse contributions from string (simplified for now)
    List<GoalContribution> contributions = [];
    // TODO: Implement proper JSON parsing for contributions

    return Goal(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      targetAmount: map['target_amount']?.toDouble() ?? 0.0,
      currentAmount: map['current_amount']?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(map['target_date'] ?? DateTime.now().toIso8601String()),
      linkedAccountId: map['linked_account_id'],
      contributions: contributions,
      isCompleted: (map['is_completed'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      lastModified: DateTime.parse(map['last_modified'] ?? DateTime.now().toIso8601String()),
    );
  }
}