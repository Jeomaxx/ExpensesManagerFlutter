import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/models/account.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_router.dart';
import '../../providers/account_providers.dart';

class AccountDetailsPage extends ConsumerWidget {
  final Account account;

  const AccountDetailsPage({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.addAccount,
                arguments: account,
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
            // Balance Card
            _buildBalanceCard(context),
            
            const SizedBox(height: 24),
            
            // Account Details
            _buildDetailsCard(context, ref),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _getAccountTypeColor(account.type),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getAccountTypeIcon(account.type),
              size: 48,
              color: Colors.white,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              CurrencyFormatter.format(account.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              account.currency,
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
              'Account Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Account Type
            _buildDetailRow(
              context,
              icon: _getAccountTypeIcon(account.type),
              label: 'Account Type',
              value: _getAccountTypeName(account.type),
            ),
            
            const SizedBox(height: 12),
            
            // Currency
            _buildDetailRow(
              context,
              icon: Icons.attach_money,
              label: 'Currency',
              value: account.currency,
            ),
            
            const SizedBox(height: 12),
            
            // Status
            _buildDetailRow(
              context,
              icon: account.isActive ? Icons.check_circle : Icons.pause_circle,
              label: 'Status',
              value: account.isActive ? 'Active' : 'Inactive',
              valueColor: account.isActive ? Colors.green : Colors.orange,
            ),
            
            if (account.description != null && account.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              
              // Description
              _buildDetailRow(
                context,
                icon: Icons.description,
                label: 'Description',
                value: account.description!,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Created Date
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'Created',
              value: DateFormat.yMMMMd().format(account.createdAt),
            ),
            
            const SizedBox(height: 12),
            
            // Last Modified
            _buildDetailRow(
              context,
              icon: Icons.update,
              label: 'Last Modified',
              value: DateFormat.yMd().add_jm().format(account.lastModified),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add Transaction
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.blue.shade700,
                ),
              ),
              title: const Text('Add Transaction'),
              subtitle: const Text('Add income or expense to this account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.addTransaction);
              },
            ),
            
            const Divider(),
            
            // View Transactions
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.list,
                  color: Colors.green.shade700,
                ),
              ),
              title: const Text('View Transactions'),
              subtitle: const Text('See all transactions for this account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.transactionsList);
              },
            ),
            
            const Divider(),
            
            // Toggle Status
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: account.isActive ? Colors.orange.shade100 : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  account.isActive ? Icons.pause : Icons.play_arrow,
                  color: account.isActive ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
              title: Text(account.isActive ? 'Deactivate Account' : 'Activate Account'),
              subtitle: Text(account.isActive 
                  ? 'Hide this account from transaction lists'
                  : 'Show this account in transaction lists'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _toggleAccountStatus(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
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
              
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleAccountStatus(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account.isActive ? 'Deactivate Account' : 'Activate Account'),
        content: Text(account.isActive 
            ? 'Are you sure you want to deactivate this account? It will be hidden from transaction lists.'
            : 'Are you sure you want to activate this account? It will appear in transaction lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(account.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(accountListProvider.notifier).toggleAccountStatus(account.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${account.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }
    }
  }

  List<Color> _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return [Colors.green.shade400, Colors.green.shade600];
      case AccountType.bankCard:
        return [Colors.blue.shade400, Colors.blue.shade600];
      case AccountType.mobileWallet:
        return [Colors.purple.shade400, Colors.purple.shade600];
      case AccountType.savings:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case AccountType.checking:
        return [Colors.teal.shade400, Colors.teal.shade600];
      case AccountType.credit:
        return [Colors.red.shade400, Colors.red.shade600];
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.money;
      case AccountType.bankCard:
        return Icons.credit_card;
      case AccountType.mobileWallet:
        return Icons.phone_android;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.credit:
        return Icons.credit_score;
    }
  }

  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bankCard:
        return 'Bank Card';
      case AccountType.mobileWallet:
        return 'Mobile Wallet';
      case AccountType.savings:
        return 'Savings';
      case AccountType.checking:
        return 'Checking';
      case AccountType.credit:
        return 'Credit';
    }
  }
}