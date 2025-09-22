import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/loan.dart';
import '../../../core/repositories/loan_repository.dart';

// Repository provider
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository.instance;
});

// Loans list provider
final loansProvider = FutureProvider.family<List<Loan>, String>((ref, userId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getLoansByUserId(userId);
});

// Single loan provider
final loanProvider = FutureProvider.family<Loan?, String>((ref, loanId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getLoanById(loanId);
});

// Upcoming payments provider
final upcomingPaymentsProvider = FutureProvider.family<List<LoanPayment>, UpcomingPaymentsParams>((ref, params) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getUpcomingPayments(params.userId, days: params.days);
});

// Overdue payments provider
final overduePaymentsProvider = FutureProvider.family<List<LoanPayment>, String>((ref, userId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getOverduePayments(userId);
});

// Total outstanding balance provider
final totalOutstandingBalanceProvider = FutureProvider.family<double, String>((ref, userId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getTotalOutstandingBalance(userId);
});

// Monthly payment total provider
final monthlyPaymentTotalProvider = FutureProvider.family<double, String>((ref, userId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getMonthlyPaymentTotal(userId);
});

// Loan management notifier
final loanManagementProvider = StateNotifierProvider<LoanManagementNotifier, LoanManagementState>((ref) {
  final repository = ref.watch(loanRepositoryProvider);
  return LoanManagementNotifier(repository);
});

class UpcomingPaymentsParams {
  final String userId;
  final int days;

  UpcomingPaymentsParams({required this.userId, required this.days});
}

class LoanManagementState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const LoanManagementState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  LoanManagementState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return LoanManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LoanManagementNotifier extends StateNotifier<LoanManagementState> {
  final LoanRepository _repository;

  LoanManagementNotifier(this._repository) : super(const LoanManagementState());

  Future<void> createLoan(Loan loan) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.createLoan(loan);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateLoan(Loan loan) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.updateLoan(loan);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteLoan(String loanId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.deleteLoan(loanId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> makePayment(String loanId, LoanPayment payment) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.makePayment(loanId, payment);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearState() {
    state = const LoanManagementState();
  }
}