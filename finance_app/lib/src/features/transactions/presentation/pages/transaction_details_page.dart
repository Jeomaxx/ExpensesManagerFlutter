import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/transaction.dart';
import '../../../../core/models/account.dart';
import '../../../../core/models/category.dart';
import '../../providers/transaction_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_router.dart';

class TransactionDetailsPage extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailsPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('transaction_details'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.addTransaction,
                arguments: transaction,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            _buildAmountCard(context),
            
            const SizedBox(height: 24),
            
            // Transaction Details
            _buildDetailsCard(context, ref),
            
            const SizedBox(height: 24),
            
            // Notes Section
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _buildNotesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: transaction.type == TransactionType.income
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              transaction.type == TransactionType.income
                  ? Icons.trending_up
                  : Icons.trending_down,
              size: 48,
              color: Colors.white,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              transaction.type == TransactionType.income ? 'income'.tr() : 'expense'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'transaction_details'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category
            _buildDetailRow(
              context,
              icon: Icons.category,
              label: 'category'.tr(),
              child: Consumer(
                builder: (context, ref, child) {
                  final categoryAsync = ref.watch(categoryByIdProvider(transaction.categoryId));
                  return categoryAsync.when(
                    loading: () => const Text('Loading...'),
                    error: (error, _) => const Text('Unknown Category'),
                    data: (category) {
                      if (category == null) return const Text('Unknown Category');
                      return Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Account
            _buildDetailRow(
              context,
              icon: Icons.account_balance_wallet,
              label: 'account'.tr(),
              child: Consumer(
                builder: (context, ref, child) {
                  final accountAsync = ref.watch(accountByIdProvider(transaction.accountId));
                  return accountAsync.when(
                    loading: () => const Text('Loading...'),
                    error: (error, _) => const Text('Unknown Account'),
                    data: (account) {
                      if (account == null) return const Text('Unknown Account');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            account.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Date
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'date'.tr(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMMd().format(transaction.date),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    DateFormat.jm().format(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Created/Modified info
            _buildDetailRow(
              context,
              icon: Icons.access_time,
              label: 'Created',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMd().add_jm().format(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (transaction.lastModified.difference(transaction.createdAt).inMinutes > 1)
                    Text(
                      'Modified: ${DateFormat.yMd().add_jm().format(transaction.lastModified)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'notes'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                transaction.notes!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 4),
              
              child,
            ],
          ),
        ),
      ],
    );
  }
}