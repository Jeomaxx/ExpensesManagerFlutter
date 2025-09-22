import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/category_repository.dart';
import 'auth_provider.dart';

// Dashboard State
class DashboardState {
  final double currentBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final List<Transaction> recentTransactions;
  final Map<String, double> expensesByCategory;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.currentBalance = 0.0,
    this.monthlyIncome = 0.0,
    this.monthlyExpenses = 0.0,
    this.recentTransactions = const [],
    this.expensesByCategory = const {},
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    double? currentBalance,
    double? monthlyIncome,
    double? monthlyExpenses,
    List<Transaction>? recentTransactions,
    Map<String, double>? expensesByCategory,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      currentBalance: currentBalance ?? this.currentBalance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get monthlySavings => monthlyIncome - monthlyExpenses;
  double get savingsRate => monthlyIncome > 0 ? (monthlySavings / monthlyIncome) * 100 : 0.0;
}

// Dashboard Provider
class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  DashboardNotifier(this._transactionRepository, this._categoryRepository)
      : super(const DashboardState());

  Future<void> loadDashboardData(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Load all dashboard data in parallel
      final results = await Future.wait([
        _transactionRepository.getCurrentBalance(userId),
        _transactionRepository.getTotalByType(
          userId: userId,
          type: TransactionType.income,
          startDate: startOfMonth,
          endDate: endOfMonth,
        ),
        _transactionRepository.getTotalByType(
          userId: userId,
          type: TransactionType.expense,
          startDate: startOfMonth,
          endDate: endOfMonth,
        ),
        _transactionRepository.getTransactionsByUserId(
          userId: userId,
          limit: 5,
        ),
        _transactionRepository.getExpensesByCategory(userId, startOfMonth, endOfMonth),
      ]);

      state = state.copyWith(
        currentBalance: results[0] as double,
        monthlyIncome: results[1] as double,
        monthlyExpenses: results[2] as double,
        recentTransactions: results[3] as List<Transaction>,
        expensesByCategory: results[4] as Map<String, double>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> refreshData(String userId) async {
    await loadDashboardData(userId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return DashboardNotifier(transactionRepo, categoryRepo);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository.instance;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository.instance;
});

// Auto-load dashboard data when user changes
final dashboardDataProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authProvider);
  final dashboardNotifier = ref.read(dashboardProvider.notifier);

  if (authState.isAuthenticated && authState.user != null) {
    await dashboardNotifier.loadDashboardData(authState.user!.id);
  }
});