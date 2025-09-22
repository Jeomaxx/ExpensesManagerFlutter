import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/account.dart';
import '../../../core/repositories/account_repository.dart';
import '../../../core/providers/auth_provider.dart';

// Simple ID generator using timestamp and random numbers
String _generateAccountId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = (DateTime.now().microsecondsSinceEpoch % 1000000);
  return 'acc_${timestamp}_$random';
}

// Account Form State
class AccountFormState {
  final String name;
  final AccountType type;
  final String currency;
  final double balance;
  final String description;
  final bool isActive;
  final bool isLoading;
  final String? error;

  const AccountFormState({
    this.name = '',
    this.type = AccountType.cash,
    this.currency = 'USD',
    this.balance = 0.0,
    this.description = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  AccountFormState copyWith({
    String? name,
    AccountType? type,
    String? currency,
    double? balance,
    String? description,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return AccountFormState(
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isValid => name.isNotEmpty && balance >= 0;
}

// Account Form Notifier
class AccountFormNotifier extends StateNotifier<AccountFormState> {
  final AccountRepository _accountRepository;

  AccountFormNotifier(this._accountRepository) : super(const AccountFormState());

  void updateName(String name) {
    state = state.copyWith(name: name, error: null);
  }

  void updateType(AccountType type) {
    state = state.copyWith(type: type, error: null);
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency, error: null);
  }

  void updateBalance(double balance) {
    state = state.copyWith(balance: balance, error: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, error: null);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive, error: null);
  }

  void reset() {
    state = const AccountFormState();
  }

  void loadAccountForEdit(Account account) {
    state = AccountFormState(
      name: account.name,
      type: account.type,
      currency: account.currency,
      balance: account.balance,
      description: account.description ?? '',
      isActive: account.isActive,
    );
  }

  Future<bool> saveAccount(String userId, {String? editingAccountId}) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      
      // For edits, preserve the original createdAt
      DateTime createdAt = now;
      if (editingAccountId != null) {
        final existingAccount = await _accountRepository.getAccountById(editingAccountId);
        createdAt = existingAccount?.createdAt ?? now;
      }
      
      final account = Account(
        id: editingAccountId ?? _generateAccountId(),
        userId: userId,
        name: state.name,
        type: state.type,
        currency: state.currency,
        balance: state.balance,
        description: state.description.isEmpty ? null : state.description,
        isActive: state.isActive,
        createdAt: createdAt,
        lastModified: now,
      );

      if (editingAccountId != null) {
        await _accountRepository.updateAccount(account);
      } else {
        await _accountRepository.createAccount(account);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save account: ${e.toString()}',
      );
      return false;
    }
  }
}

// Account List State
class AccountListState {
  final List<Account> accounts;
  final bool isLoading;
  final String? error;
  final double totalBalance;

  const AccountListState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
    this.totalBalance = 0.0,
  });

  AccountListState copyWith({
    List<Account>? accounts,
    bool? isLoading,
    String? error,
    double? totalBalance,
  }) {
    return AccountListState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }
}

// Account List Notifier
class AccountListNotifier extends StateNotifier<AccountListState> {
  final AccountRepository _accountRepository;

  AccountListNotifier(this._accountRepository) : super(const AccountListState());

  Future<void> loadAccounts(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final accounts = await _accountRepository.getAccountsByUserId(userId);
      final totalBalance = await _accountRepository.getTotalBalance(userId);

      state = state.copyWith(
        accounts: accounts,
        totalBalance: totalBalance,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _accountRepository.deleteAccount(accountId);
      
      // Remove from local state
      final updatedAccounts = state.accounts
          .where((account) => account.id != accountId)
          .toList();
      
      // Recalculate total balance
      final totalBalance = updatedAccounts
          .where((account) => account.isActive)
          .fold(0.0, (sum, account) => sum + account.balance);
      
      state = state.copyWith(
        accounts: updatedAccounts,
        totalBalance: totalBalance,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete account');
    }
  }

  Future<void> toggleAccountStatus(String accountId) async {
    try {
      final accountIndex = state.accounts.indexWhere((a) => a.id == accountId);
      if (accountIndex == -1) return;

      final account = state.accounts[accountIndex];
      final updatedAccount = account.copyWith(
        isActive: !account.isActive,
        lastModified: DateTime.now(),
      );

      await _accountRepository.updateAccount(updatedAccount);

      // Update local state
      final updatedAccounts = [...state.accounts];
      updatedAccounts[accountIndex] = updatedAccount;

      // Recalculate total balance
      final totalBalance = updatedAccounts
          .where((account) => account.isActive)
          .fold(0.0, (sum, account) => sum + account.balance);

      state = state.copyWith(
        accounts: updatedAccounts,
        totalBalance: totalBalance,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update account status');
    }
  }
}

// Providers
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository.instance;
});

final accountFormProvider = StateNotifierProvider<AccountFormNotifier, AccountFormState>((ref) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return AccountFormNotifier(accountRepo);
});

final accountListProvider = StateNotifierProvider<AccountListNotifier, AccountListState>((ref) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return AccountListNotifier(accountRepo);
});

// Auto-load accounts when user changes
final accountListDataProvider = FutureProvider.autoDispose<void>((ref) async {
  final authState = ref.watch(authProvider);
  final accountListNotifier = ref.read(accountListProvider.notifier);

  if (authState.isAuthenticated && authState.user != null) {
    await accountListNotifier.loadAccounts(authState.user!.id);
  }
});

// Get single account by ID (for details page)
final accountByIdProvider = FutureProvider.family<Account?, String>((ref, accountId) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return await accountRepo.getAccountById(accountId);
});

// Get active accounts for dropdowns (reused in transactions)
final activeAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final authState = ref.watch(authProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);
  
  if (authState.user != null) {
    final allAccounts = await accountRepo.getAccountsByUserId(authState.user!.id);
    return allAccounts.where((account) => account.isActive).toList();
  }
  return [];
});