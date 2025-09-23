import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Localization removed for web compatibility

import '../../../../shared/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/transaction.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final user = authState.user;

    // Auto-load dashboard data when component builds
    ref.listen<AsyncValue<void>>(dashboardDataProvider, (previous, next) {
      // Handle any loading errors
      next.whenOrNull(
        error: (error, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $error')),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, user?.name ?? 'Guest'),
            
            const SizedBox(height: 24),
            
            // Balance Overview Card
            _buildBalanceOverview(context, dashboardState),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(context),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            _buildRecentTransactions(context, dashboardState),
            
            const SizedBox(height: 24),
            
            // Monthly Summary
            _buildMonthlySummary(context, dashboardState),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.addTransaction);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String userName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your finances today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceOverview(BuildContext context, dynamic dashboardState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              CurrencyFormatter.format(
                dashboardState.totalBalance ?? 0.0,
                context: context,
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBalanceItem(
                  context,
                  'Monthly Income',
                  dashboardState.monthlyIncome ?? 0.0,
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildBalanceItem(
                  context,
                  'Monthly Expenses',
                  dashboardState.monthlyExpenses ?? 0.0,
                  Icons.trending_down,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount, context: context),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionButton(
                  context,
                  'Add Income',
                  Icons.add_circle_outline,
                  Colors.green,
                  () => Navigator.of(context).pushNamed(
                    AppRouter.addTransaction,
                    arguments: {'type': 'income'},
                  ),
                ),
                _buildActionButton(
                  context,
                  'Add Expense',
                  Icons.remove_circle_outline,
                  Colors.red,
                  () => Navigator.of(context).pushNamed(
                    AppRouter.addTransaction,
                    arguments: {'type': 'expense'},
                  ),
                ),
                _buildActionButton(
                  context,
                  'View Accounts',
                  Icons.account_balance_wallet,
                  Colors.blue,
                  () => Navigator.of(context).pushNamed(AppRouter.accounts),
                ),
                _buildActionButton(
                  context,
                  'Scan Receipt',
                  Icons.camera_alt,
                  Colors.orange,
                  () {
                    // TODO: Implement receipt scanning
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt scanning coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, dynamic dashboardState) {
    final recentTransactions = dashboardState.recentTransactions ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.transactionsList);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent transactions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentTransactions
                  .take(5)
                  .map((transaction) => _buildTransactionItem(context, transaction))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic transaction) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red : Colors.green;
    final icon = isExpense ? Icons.trending_down : Icons.trending_up;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(transaction.notes ?? 'Transaction'),
      subtitle: Text(
        DateFormat('MMM d, yyyy').format(transaction.date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, context: context)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(BuildContext context, dynamic dashboardState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (dashboardState.monthlyData == null || 
                dashboardState.monthlyData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data this month',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Chart visualization will be added here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}