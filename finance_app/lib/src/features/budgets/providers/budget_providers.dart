import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/budget.dart';
import '../../../core/models/category.dart';
import '../../../core/repositories/budget_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/providers/auth_provider.dart';

// Simple ID generator using timestamp and random numbers
String _generateBudgetId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = (DateTime.now().microsecondsSinceEpoch % 1000000);
  return 'bdg_${timestamp}_$random';
}

// Budget Form State
class BudgetFormState {
  final String name;
  final double amount;
  final String? categoryId;
  final BudgetType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final bool isActive;
  final bool isLoading;
  final String? error;
  final List<Category> availableCategories;

  const BudgetFormState({
    this.name = '',
    this.amount = 0.0,
    this.categoryId,
    this.type = BudgetType.monthly,
    this.startDate,
    this.endDate,
    this.description = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
    this.availableCategories = const [],
  });

  BudgetFormState copyWith({
    String? name,
    double? amount,
    String? categoryId,
    BudgetType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    bool? isActive,
    bool? isLoading,
    String? error,
    List<Category>? availableCategories,
  }) {
    return BudgetFormState(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }

  bool get isValid => name.isNotEmpty && amount > 0 && categoryId != null && startDate != null && endDate != null;
  
  Category? get selectedCategory {
    try {
      return availableCategories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }
}

// Budget Form Notifier
class BudgetFormNotifier extends StateNotifier<BudgetFormState> {
  final BudgetRepository _budgetRepository;
  final CategoryRepository _categoryRepository;

  BudgetFormNotifier(this._budgetRepository, this._categoryRepository) : super(const BudgetFormState());

  Future<void> loadCategories(String userId) async {
    try {
      final categories = await _categoryRepository.getCategoriesByUserId(userId);
      state = state.copyWith(availableCategories: categories);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load categories');
    }
  }

  void updateName(String name) {
    state = state.copyWith(name: name, error: null);
  }

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount, error: null);
  }

  void updateCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId, error: null);
  }

  void updateType(BudgetType type) {
    // Auto-calculate dates based on budget type
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (type) {
      case BudgetType.weekly:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        break;
      case BudgetType.monthly:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        break;
      case BudgetType.yearly:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        break;
      case BudgetType.custom:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 30)).subtract(const Duration(milliseconds: 1));
        break;
    }

    state = state.copyWith(
      type: type,
      startDate: startDate,
      endDate: endDate,
      error: null,
    );
  }

  void updateStartDate(DateTime startDate) {
    state = state.copyWith(startDate: startDate, error: null);
  }

  void updateEndDate(DateTime endDate) {
    state = state.copyWith(endDate: endDate, error: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, error: null);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive, error: null);
  }

  void reset() {
    state = const BudgetFormState();
  }

  void loadBudgetForEdit(Budget budget) {
    state = BudgetFormState(
      name: budget.name,
      amount: budget.amount,
      categoryId: budget.categoryId,
      type: budget.type,
      startDate: budget.startDate,
      endDate: budget.endDate,
      description: budget.description ?? '',
      isActive: budget.isActive,
      availableCategories: state.availableCategories,
    );
  }

  Future<bool> saveBudget(String userId, {String? editingBudgetId}) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check for overlapping budgets
      final hasOverlap = await _budgetRepository.budgetExistsForCategory(
        userId,
        state.categoryId!,
        state.startDate!,
        state.endDate!,
        excludeBudgetId: editingBudgetId,
      );

      if (hasOverlap) {
        state = state.copyWith(
          isLoading: false,
          error: 'A budget already exists for this category in the selected date range',
        );
        return false;
      }

      final now = DateTime.now();
      
      // For edits, preserve the original createdAt
      DateTime createdAt = now;
      if (editingBudgetId != null) {
        final existingBudget = await _budgetRepository.getBudgetById(editingBudgetId);
        createdAt = existingBudget?.createdAt ?? now;
      }
      
      final budget = Budget(
        id: editingBudgetId ?? _generateBudgetId(),
        userId: userId,
        categoryId: state.categoryId!,
        name: state.name,
        amount: state.amount,
        type: state.type,
        startDate: state.startDate!,
        endDate: state.endDate!,
        isActive: state.isActive,
        description: state.description.isEmpty ? null : state.description,
        createdAt: createdAt,
        lastModified: now,
      );

      if (editingBudgetId != null) {
        await _budgetRepository.updateBudget(budget);
      } else {
        await _budgetRepository.createBudget(budget);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save budget: ${e.toString()}',
      );
      return false;
    }
  }
}

// Budget List State
class BudgetListState {
  final List<BudgetWithSpending> budgets;
  final bool isLoading;
  final String? error;
  final double totalBudget;
  final double totalSpent;

  const BudgetListState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
    this.totalBudget = 0.0,
    this.totalSpent = 0.0,
  });

  BudgetListState copyWith({
    List<BudgetWithSpending>? budgets,
    bool? isLoading,
    String? error,
    double? totalBudget,
    double? totalSpent,
  }) {
    return BudgetListState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }
}

// Budget List Notifier
class BudgetListNotifier extends StateNotifier<BudgetListState> {
  final BudgetRepository _budgetRepository;
  final Ref _ref;

  BudgetListNotifier(this._budgetRepository, this._ref) : super(const BudgetListState());

  Future<void> loadBudgets(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final budgets = await _budgetRepository.getBudgetsWithSpending(userId);
      
      final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.budget.amount);
      final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);

      state = state.copyWith(
        budgets: budgets,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetRepository.deleteBudget(budgetId);
      
      // Remove from local state
      final updatedBudgets = state.budgets
          .where((budget) => budget.budget.id != budgetId)
          .toList();
      
      // Recalculate totals
      final totalBudget = updatedBudgets.fold(0.0, (sum, b) => sum + b.budget.amount);
      final totalSpent = updatedBudgets.fold(0.0, (sum, b) => sum + b.spent);
      
      state = state.copyWith(
        budgets: updatedBudgets,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete budget');
    }
  }

  Future<void> toggleBudgetStatus(String budgetId) async {
    try {
      final budgetIndex = state.budgets.indexWhere((b) => b.budget.id == budgetId);
      if (budgetIndex == -1) return;

      final budget = state.budgets[budgetIndex].budget;
      final updatedBudget = budget.copyWith(
        isActive: !budget.isActive,
        lastModified: DateTime.now(),
      );

      await _budgetRepository.updateBudget(updatedBudget);

      // Update local state - reload to get fresh spending data
      final authState = _ref.read(authProvider);
      if (authState.user != null) {
        await loadBudgets(authState.user!.id);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update budget status');
    }
  }
}

// Providers
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository.instance;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository.instance;
});

final budgetFormProvider = StateNotifierProvider<BudgetFormNotifier, BudgetFormState>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return BudgetFormNotifier(budgetRepo, categoryRepo);
});

final budgetListProvider = StateNotifierProvider<BudgetListNotifier, BudgetListState>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  return BudgetListNotifier(budgetRepo, ref);
});

// Auto-load budgets when user changes
final budgetListDataProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authProvider);
  final budgetListNotifier = ref.read(budgetListProvider.notifier);

  if (authState.isAuthenticated && authState.user != null) {
    await budgetListNotifier.loadBudgets(authState.user!.id);
  }
});

// Get single budget with spending by ID
final budgetByIdProvider = FutureProvider.family<BudgetWithSpending?, String>((ref, budgetId) async {
  final authState = ref.watch(authProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  
  if (authState.user != null) {
    return await budgetRepo.getBudgetWithSpending(budgetId, authState.user!.id);
  }
  return null;
});

// Get budget alerts (over-budget warnings)
final budgetAlertsProvider = FutureProvider<List<BudgetWithSpending>>((ref) async {
  final authState = ref.watch(authProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  
  if (authState.user != null) {
    return await budgetRepo.getBudgetAlerts(authState.user!.id);
  }
  return [];
});

