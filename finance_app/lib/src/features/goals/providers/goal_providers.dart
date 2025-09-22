import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/goal.dart';
import '../../../core/repositories/goal_repository.dart';
import '../../../core/repositories/account_repository.dart';
import '../../../core/providers/auth_provider.dart';

// Goal list state
class GoalListState {
  final List<Goal> goals;
  final bool isLoading;
  final String? error;
  final double totalTargetAmount;
  final double totalSavedAmount;
  final double overallProgress;

  const GoalListState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
    this.totalTargetAmount = 0.0,
    this.totalSavedAmount = 0.0,
    this.overallProgress = 0.0,
  });

  GoalListState copyWith({
    List<Goal>? goals,
    bool? isLoading,
    String? error,
    double? totalTargetAmount,
    double? totalSavedAmount,
    double? overallProgress,
  }) {
    return GoalListState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalTargetAmount: totalTargetAmount ?? this.totalTargetAmount,
      totalSavedAmount: totalSavedAmount ?? this.totalSavedAmount,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}

// Goal form state
class GoalFormState {
  final String title;
  final double targetAmount;
  final DateTime targetDate;
  final String? linkedAccountId;
  final String? description;
  final bool isLoading;
  final String? error;

  const GoalFormState({
    this.title = '',
    this.targetAmount = 0.0,
    required this.targetDate,
    this.linkedAccountId,
    this.description,
    this.isLoading = false,
    this.error,
  });

  GoalFormState copyWith({
    String? title,
    double? targetAmount,
    DateTime? targetDate,
    String? linkedAccountId,
    String? description,
    bool? isLoading,
    String? error,
  }) {
    return GoalFormState(
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      description: description ?? this.description,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Goal list notifier
class GoalListNotifier extends StateNotifier<GoalListState> {
  final GoalRepository _goalRepository;
  final Ref _ref;

  GoalListNotifier(this._goalRepository, this._ref) : super(const GoalListState());

  Future<void> loadGoals(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final goals = await _goalRepository.getGoalsByUserId(userId);
      final summary = await _goalRepository.getGoalsSummary(userId);

      state = state.copyWith(
        goals: goals,
        totalTargetAmount: summary['totalTargetAmount'],
        totalSavedAmount: summary['totalSavedAmount'],
        overallProgress: summary['overallProgress'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalRepository.deleteGoal(goalId);
      
      // Remove from local state
      final updatedGoals = state.goals.where((goal) => goal.id != goalId).toList();
      
      // Recalculate totals
      final totalTargetAmount = updatedGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
      final totalSavedAmount = updatedGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
      final overallProgress = totalTargetAmount > 0 ? (totalSavedAmount / totalTargetAmount * 100) : 0.0;
      
      state = state.copyWith(
        goals: updatedGoals,
        totalTargetAmount: totalTargetAmount,
        totalSavedAmount: totalSavedAmount,
        overallProgress: overallProgress,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete goal');
    }
  }

  Future<void> toggleGoalCompletion(String goalId) async {
    try {
      final goalIndex = state.goals.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) return;

      final goal = state.goals[goalIndex];
      
      if (!goal.isCompleted) {
        await _goalRepository.markGoalCompleted(goalId);
      } else {
        // Reopen goal
        final updatedGoal = goal.copyWith(
          isCompleted: false,
          lastModified: DateTime.now(),
        );
        await _goalRepository.updateGoal(updatedGoal);
      }

      // Reload goals to get fresh data
      final authState = _ref.read(authProvider);
      if (authState.user != null) {
        await loadGoals(authState.user!.id);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update goal');
    }
  }

  Future<void> addContribution(String goalId, double amount, {String? note}) async {
    try {
      await _goalRepository.addContribution(goalId, amount, note: note);

      // Reload goals to get updated data
      final authState = _ref.read(authProvider);
      if (authState.user != null) {
        await loadGoals(authState.user!.id);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add contribution');
    }
  }
}

// Goal form notifier
class GoalFormNotifier extends StateNotifier<GoalFormState> {
  final GoalRepository _goalRepository;
  final AccountRepository _accountRepository;
  
  GoalFormNotifier(this._goalRepository, this._accountRepository) 
      : super(GoalFormState(targetDate: DateTime.now().add(const Duration(days: 365))));

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateTargetAmount(double amount) {
    state = state.copyWith(targetAmount: amount);
  }

  void updateTargetDate(DateTime date) {
    state = state.copyWith(targetDate: date);
  }

  void updateLinkedAccount(String? accountId) {
    state = state.copyWith(linkedAccountId: accountId);
  }

  void updateDescription(String? description) {
    state = state.copyWith(description: description);
  }

  void resetForm() {
    state = GoalFormState(targetDate: DateTime.now().add(const Duration(days: 365)));
  }

  Future<bool> saveGoal(String userId, {Goal? existingGoal}) async {
    if (state.title.isEmpty || state.targetAmount <= 0) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (existingGoal != null) {
        // Update existing goal
        final updatedGoal = existingGoal.copyWith(
          title: state.title,
          targetAmount: state.targetAmount,
          targetDate: state.targetDate,
          linkedAccountId: state.linkedAccountId,
          description: state.description,
          lastModified: DateTime.now(),
        );
        await _goalRepository.updateGoal(updatedGoal);
      } else {
        // Create new goal
        final newGoal = Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          title: state.title,
          targetAmount: state.targetAmount,
          targetDate: state.targetDate,
          linkedAccountId: state.linkedAccountId,
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        await _goalRepository.createGoal(newGoal);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void loadGoal(Goal goal) {
    state = state.copyWith(
      title: goal.title,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      linkedAccountId: goal.linkedAccountId,
      description: null, // Goal model doesn't have description field yet
    );
  }
}

// Providers
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository.instance;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository.instance;
});

final goalFormProvider = StateNotifierProvider<GoalFormNotifier, GoalFormState>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  return GoalFormNotifier(goalRepo, accountRepo);
});

final goalListProvider = StateNotifierProvider<GoalListNotifier, GoalListState>((ref) {
  final goalRepo = ref.watch(goalRepositoryProvider);
  return GoalListNotifier(goalRepo, ref);
});

// Auto-load goals when user changes
final goalListDataProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authProvider);
  final goalListNotifier = ref.read(goalListProvider.notifier);

  if (authState.isAuthenticated && authState.user != null) {
    await goalListNotifier.loadGoals(authState.user!.id);
  }
});

// Get single goal by ID
final goalByIdProvider = FutureProvider.family<Goal?, String>((ref, goalId) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  return await goalRepo.getGoalById(goalId);
});

// Get overdue goals
final overdueGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final authState = ref.watch(authProvider);
  final goalRepo = ref.watch(goalRepositoryProvider);
  
  if (authState.user != null) {
    return await goalRepo.getOverdueGoals(authState.user!.id);
  }
  return [];
});

// Get active goals
final activeGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final authState = ref.watch(authProvider);
  final goalRepo = ref.watch(goalRepositoryProvider);
  
  if (authState.user != null) {
    return await goalRepo.getActiveGoals(authState.user!.id);
  }
  return [];
});

// Get completed goals
final completedGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final authState = ref.watch(authProvider);
  final goalRepo = ref.watch(goalRepositoryProvider);
  
  if (authState.user != null) {
    return await goalRepo.getCompletedGoals(authState.user!.id);
  }
  return [];
});