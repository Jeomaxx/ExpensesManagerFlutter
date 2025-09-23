import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/budget.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_router.dart';
import '../../providers/budget_providers.dart';

class BudgetDetailsPage extends ConsumerWidget {
  final BudgetWithSpending budgetWithSpending;

  const BudgetDetailsPage({super.key, required this.budgetWithSpending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = budgetWithSpending.budget;

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.addBudget,
                arguments: budget,
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
            // Budget Progress Card
            _buildBudgetProgressCard(context),
            
            const SizedBox(height: 24),
            
            // Budget Details
            _buildBudgetDetailsCard(context, ref),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _getBudgetStatusGradient(budgetWithSpending.status),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getBudgetStatusIcon(budgetWithSpending.status),
              size: 48,
              color: Colors.white,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '${budgetWithSpending.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _getBudgetStatusText(budgetWithSpending.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: budgetWithSpending.percentage / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetDetailsCard(BuildContext context, WidgetRef ref) {
    final budget = budgetWithSpending.budget;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Budget Amount
            _buildDetailRow(
              context,
              icon: Icons.account_balance_wallet,
              label: 'Budget Amount',
              value: CurrencyFormatter.format(budget.amount),
            ),
            
            const SizedBox(height: 12),
            
            // Spent Amount
            _buildDetailRow(
              context,
              icon: Icons.money_off,
              label: 'Amount Spent',
              value: CurrencyFormatter.format(budgetWithSpending.spent),
              valueColor: budgetWithSpending.status == BudgetStatus.exceeded 
                  ? Colors.red.shade700 
                  : null,
            ),
            
            const SizedBox(height: 12),
            
            // Remaining Amount
            _buildDetailRow(
              context,
              icon: Icons.savings,
              label: 'Remaining',
              value: CurrencyFormatter.format(budgetWithSpending.remaining),
              valueColor: budgetWithSpending.remaining < 0 
                  ? Colors.red.shade700 
                  : Colors.green.shade700,
            ),
            
            const SizedBox(height: 12),
            
            // Transaction Count
            _buildDetailRow(
              context,
              icon: Icons.receipt_long,
              label: 'Transactions',
              value: '${budgetWithSpending.transactionCount} transactions',
            ),
            
            const SizedBox(height: 12),
            
            // Budget Type
            _buildDetailRow(
              context,
              icon: _getBudgetTypeIcon(budget.type),
              label: 'Budget Type',
              value: _getBudgetTypeName(budget.type),
            ),
            
            const SizedBox(height: 12),
            
            // Date Range
            _buildDetailRow(
              context,
              icon: Icons.date_range,
              label: 'Period',
              value: '${DateFormat.yMd().format(budget.startDate)} - ${DateFormat.yMd().format(budget.endDate)}',
            ),
            
            if (budget.description != null && budget.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              
              // Description
              _buildDetailRow(
                context,
                icon: Icons.description,
                label: 'Description',
                value: budget.description!,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Created Date
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'Created',
              value: DateFormat.yMMMMd().format(budget.createdAt),
            ),
            
            const SizedBox(height: 12),
            
            // Status
            _buildDetailRow(
              context,
              icon: budget.isActive ? Icons.check_circle : Icons.pause_circle,
              label: 'Status',
              value: budget.isActive ? 'Active' : 'Inactive',
              valueColor: budget.isActive ? Colors.green : Colors.orange,
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
              subtitle: const Text('Add expense to this budget category'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to add transaction with budget category pre-selected
                Navigator.of(context).pushNamed(AppRouter.addTransaction);
              },
            ),
            
            const Divider(),
            
            // View Category Transactions
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
              subtitle: const Text('See all transactions in this category'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to transactions filtered by category
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
                  color: budgetWithSpending.budget.isActive ? Colors.orange.shade100 : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  budgetWithSpending.budget.isActive ? Icons.pause : Icons.play_arrow,
                  color: budgetWithSpending.budget.isActive ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
              title: Text(budgetWithSpending.budget.isActive ? 'Deactivate Budget' : 'Activate Budget'),
              subtitle: Text(budgetWithSpending.budget.isActive 
                  ? 'Stop tracking spending for this budget'
                  : 'Resume tracking spending for this budget'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _toggleBudgetStatus(context, ref);
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

  Future<void> _toggleBudgetStatus(BuildContext context, WidgetRef ref) async {
    final budget = budgetWithSpending.budget;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(budget.isActive ? 'Deactivate Budget' : 'Activate Budget'),
        content: Text(budget.isActive 
            ? 'Are you sure you want to deactivate this budget? It will stop tracking spending.'
            : 'Are you sure you want to activate this budget? It will resume tracking spending.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(budget.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetListProvider.notifier).toggleBudgetStatus(budget.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget ${budget.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to budget list
        Navigator.of(context).pop();
      }
    }
  }

  List<Color> _getBudgetStatusGradient(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return [Colors.green.shade400, Colors.green.shade600];
      case BudgetStatus.warning:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case BudgetStatus.exceeded:
        return [Colors.red.shade400, Colors.red.shade600];
    }
  }

  IconData _getBudgetStatusIcon(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return Icons.check_circle;
      case BudgetStatus.warning:
        return Icons.warning;
      case BudgetStatus.exceeded:
        return Icons.error;
    }
  }

  String _getBudgetStatusText(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.onTrack:
        return 'On Track';
      case BudgetStatus.warning:
        return 'Warning';
      case BudgetStatus.exceeded:
        return 'Exceeded';
    }
  }

  IconData _getBudgetTypeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.weekly:
        return Icons.calendar_view_week;
      case BudgetType.monthly:
        return Icons.calendar_view_month;
      case BudgetType.yearly:
        return Icons.calendar_today;
      case BudgetType.custom:
        return Icons.date_range;
    }
  }

  String _getBudgetTypeName(BudgetType type) {
    switch (type) {
      case BudgetType.weekly:
        return 'Weekly';
      case BudgetType.monthly:
        return 'Monthly';
      case BudgetType.yearly:
        return 'Yearly';
      case BudgetType.custom:
        return 'Custom';
    }
  }
}