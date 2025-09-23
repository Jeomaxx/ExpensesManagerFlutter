import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/transaction.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/category.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/repositories/account_repository.dart';
import '../../../../core/repositories/category_repository.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_router.dart';
import '../../providers/transaction_providers.dart';

// Transaction List Item Widget
class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction type indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.type == TransactionType.income
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.type == TransactionType.income
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: transaction.type == TransactionType.income
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Account info
                    FutureBuilder<String>(
                      future: _getCategoryName(ref, transaction.categoryId),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Account and Date
                    Row(
                      children: [
                        FutureBuilder<String>(
                          future: _getAccountName(ref, transaction.accountId),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Loading...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                        Text(
                          ' • ${DateFormat.MMMd().format(transaction.date)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Notes if available
                    if (transaction.notes != null && transaction.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          transaction.notes!,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Amount and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.type == TransactionType.income
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getCategoryName(WidgetRef ref, String categoryId) async {
    final category = await ref.read(categoryByIdProvider(categoryId).future);
    return category?.name ?? 'Unknown Category';
  }

  Future<String> _getAccountName(WidgetRef ref, String accountId) async {
    final account = await ref.read(accountByIdProvider(accountId).future);
    return account?.name ?? 'Unknown Account';
  }
}

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more transactions when reaching bottom
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        ref.read(transactionListProvider.notifier).loadTransactions(authState.user!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionListState = ref.watch(transactionListProvider);
    final authState = ref.watch(authProvider);

    // Auto-load data on first build
    ref.listen<AsyncValue<void>>(transactionListDataProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $error')),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authState.user != null) {
            await ref
                .read(transactionListProvider.notifier)
                .loadTransactions(authState.user!.id, refresh: true);
          }
        },
        child: _buildTransactionList(transactionListState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.addTransaction);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTransactionList(TransactionListState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final authState = ref.read(authProvider);
                if (authState.user != null) {
                  ref
                      .read(transactionListProvider.notifier)
                      .loadTransactions(authState.user!.id, refresh: true);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          // Loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = state.transactions[index];
        return TransactionListItem(
          transaction: transaction,
          onTap: () => _navigateToTransactionDetails(transaction),
          onEdit: () => _navigateToEditTransaction(transaction),
          onDelete: () => _deleteTransaction(transaction),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first transaction',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.addTransaction);
            },
            icon: const Icon(Icons.add),
            label: Text('add_transaction'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTransactionDetails(Transaction transaction) {
    Navigator.of(context).pushNamed(
      AppRouter.transactionDetails,
      arguments: transaction,
    );
  }

  void _navigateToEditTransaction(Transaction transaction) {
    Navigator.of(context).pushNamed(
      AppRouter.addTransaction,
      arguments: transaction,
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(transactionListProvider.notifier)
          .deleteTransaction(transaction.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}