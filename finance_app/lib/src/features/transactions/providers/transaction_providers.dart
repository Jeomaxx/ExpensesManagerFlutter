import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/account.dart';
import '../../../core/models/category.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/account_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/providers/auth_provider.dart';

// Simple ID generator using timestamp and random numbers
String _generateId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = (DateTime.now().microsecondsSinceEpoch % 1000000);
  return '${timestamp}_$random';
}

// Transaction Form State
class TransactionFormState {
  final double amount;
  final TransactionType type;
  final String? selectedAccountId;
  final String? selectedCategoryId;
  final DateTime date;
  final String notes;
  final bool isLoading;
  final String? error;

  TransactionFormState({
    this.amount = 0.0,
    this.type = TransactionType.expense,
    this.selectedAccountId,
    this.selectedCategoryId,
    DateTime? date,
    this.notes = '',
    this.isLoading = false,
    this.error,
  }) : date = date ?? DateTime.now();

  TransactionFormState copyWith({
    double? amount,
    TransactionType? type,
    String? selectedAccountId,
    String? selectedCategoryId,
    DateTime? date,
    String? notes,
    bool? isLoading,
    String? error,
  }) {
    return TransactionFormState(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      date: date ?? this.date ?? DateTime.now(),
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid => 
    amount > 0 && 
    selectedAccountId != null && 
    selectedCategoryId != null;
}

// Transaction Form Notifier
class TransactionFormNotifier extends StateNotifier<TransactionFormState> {
  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  TransactionFormNotifier(this._transactionRepository, this._accountRepository)
      : super(TransactionFormState(date: DateTime.now()));

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount, error: null);
  }

  void updateType(TransactionType type) {
    state = state.copyWith(type: type, error: null);
  }

  void updateAccount(String accountId) {
    state = state.copyWith(selectedAccountId: accountId, error: null);
  }

  void updateCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId, error: null);
  }

  void updateDate(DateTime date) {
    state = state.copyWith(date: date, error: null);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes, error: null);
  }

  void reset() {
    state = TransactionFormState(date: DateTime.now());
  }

  void loadTransactionForEdit(Transaction transaction) {
    state = TransactionFormState(
      amount: transaction.amount,
      type: transaction.type,
      selectedAccountId: transaction.accountId,
      selectedCategoryId: transaction.categoryId,
      date: transaction.date,
      notes: transaction.notes ?? '',
    );
  }

  Future<bool> saveTransaction(String userId, {String? editingTransactionId}) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      
      // For edits, preserve the original createdAt; for new transactions, use current time
      DateTime createdAt = now;
      if (editingTransactionId != null) {
        final existingTransaction = await _transactionRepository.getTransactionById(editingTransactionId);
        createdAt = existingTransaction?.createdAt ?? now;
      }
      
      final transaction = Transaction(
        id: editingTransactionId ?? _generateId(),
        userId: userId,
        accountId: state.selectedAccountId!,
        amount: state.amount,
        type: state.type,
        categoryId: state.selectedCategoryId!,
        date: state.date,
        notes: state.notes.isEmpty ? null : state.notes,
        createdAt: createdAt,
        lastModified: now,
      );

      if (editingTransactionId != null) {
        await _transactionRepository.updateTransaction(transaction);
      } else {
        await _transactionRepository.createTransaction(transaction);
      }

      // Update account balance
      await _updateAccountBalance(transaction, editingTransactionId);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save transaction: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _updateAccountBalance(Transaction transaction, String? editingTransactionId) async {
    // For new transactions, simply apply the balance change
    if (editingTransactionId == null) {
      await _applyBalanceChange(transaction.accountId, transaction);
      return;
    }

    // For edits, we need to handle potential account changes and reverse old effects
    final oldTransaction = await _transactionRepository.getTransactionById(editingTransactionId);
    if (oldTransaction == null) {
      // Old transaction not found, treat as new
      await _applyBalanceChange(transaction.accountId, transaction);
      return;
    }

    // If account changed, reverse old effect and apply new effect
    if (oldTransaction.accountId != transaction.accountId) {
      // Reverse old transaction effect on old account
      await _reverseBalanceChange(oldTransaction.accountId, oldTransaction);
      // Apply new transaction effect on new account
      await _applyBalanceChange(transaction.accountId, transaction);
    } else {
      // Same account, calculate the net difference
      final oldEffect = oldTransaction.type == TransactionType.income 
          ? oldTransaction.amount 
          : -oldTransaction.amount;
      
      final newEffect = transaction.type == TransactionType.income 
          ? transaction.amount 
          : -transaction.amount;
      
      final netChange = newEffect - oldEffect;
      
      if (netChange != 0) {
        final account = await _accountRepository.getAccountById(transaction.accountId);
        if (account != null) {
          await _accountRepository.updateAccountBalance(
            account.id, 
            account.balance + netChange
          );
        }
      }
    }
  }

  Future<void> _applyBalanceChange(String accountId, Transaction transaction) async {
    final account = await _accountRepository.getAccountById(accountId);
    if (account == null) return;

    final balanceChange = transaction.type == TransactionType.income 
        ? transaction.amount 
        : -transaction.amount;

    await _accountRepository.updateAccountBalance(
      account.id, 
      account.balance + balanceChange
    );
  }

  Future<void> _reverseBalanceChange(String accountId, Transaction transaction) async {
    final account = await _accountRepository.getAccountById(accountId);
    if (account == null) return;

    // Reverse the effect of the transaction
    final balanceChange = transaction.type == TransactionType.income 
        ? -transaction.amount  // Reverse income effect
        : transaction.amount;  // Reverse expense effect

    await _accountRepository.updateAccountBalance(
      account.id, 
      account.balance + balanceChange
    );
  }
}

// Transaction List State
class TransactionListState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

// Transaction List Notifier
class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionRepository _transactionRepository;
  static const int _pageSize = 20;

  TransactionListNotifier(this._transactionRepository) 
      : super(const TransactionListState());

  Future<void> loadTransactions(String userId, {bool refresh = false}) async {
    if (state.isLoading) return;
    
    if (refresh) {
      state = const TransactionListState();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = refresh ? 0 : state.transactions.length;
      final newTransactions = await _transactionRepository.getTransactionsByUserId(
        userId: userId,
        limit: _pageSize,
        offset: offset,
      );

      final allTransactions = refresh 
          ? newTransactions
          : [...state.transactions, ...newTransactions];

      state = state.copyWith(
        transactions: allTransactions,
        isLoading: false,
        hasMore: newTransactions.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionRepository.deleteTransaction(transactionId);
      
      // Remove from local state
      final updatedTransactions = state.transactions
          .where((t) => t.id != transactionId)
          .toList();
      
      state = state.copyWith(transactions: updatedTransactions);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete transaction');
    }
  }
}

// Providers
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository.instance;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository.instance;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository.instance;
});

final transactionFormProvider = StateNotifierProvider<TransactionFormNotifier, TransactionFormState>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  return TransactionFormNotifier(transactionRepo, accountRepo);
});

final transactionListProvider = StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return TransactionListNotifier(transactionRepo);
});

// Auto-load transactions when user changes
final transactionListDataProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authProvider);
  final transactionListNotifier = ref.read(transactionListProvider.notifier);

  if (authState.isAuthenticated && authState.user != null) {
    await transactionListNotifier.loadTransactions(authState.user!.id, refresh: true);
  }
});

// Get accounts for dropdowns
final userAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final authState = ref.watch(authProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  
  if (authState.user != null) {
    return await accountRepo.getAccountsByUserId(authState.user!.id);
  }
  return [];
});

// Get categories for dropdowns
final userCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final authState = ref.watch(authProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  
  if (authState.user != null) {
    return await categoryRepo.getCategoriesByUserId(authState.user!.id);
  }
  return [];
});

// Get single category by ID (for details page)
final categoryByIdProvider = FutureProvider.family<Category?, String>((ref, categoryId) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return await categoryRepo.getCategoryById(categoryId);
});

// Get single account by ID (for details page)  
final accountByIdProvider = FutureProvider.family<Account?, String>((ref, accountId) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return await accountRepo.getAccountById(accountId);
});