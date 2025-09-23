import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/transaction_list_page.dart';
import '../../features/accounts/presentation/pages/account_list_page.dart';
import '../../features/budgets/presentation/pages/budget_list_page.dart';
import '../../features/goals/presentation/pages/goal_list_page.dart';
import '../pages/more_page.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> pages = [
      const DashboardPage(),
      const TransactionListPage(), 
      const AccountListPage(),
      const BudgetListPage(),
      const MorePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, currentIndex),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, int currentIndex) {
    switch (currentIndex) {
      case 1: // Transactions
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/add-transaction');
          },
          backgroundColor: Colors.blue.shade600,
          child: const Icon(Icons.add),
        );
      case 2: // Accounts
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/add-account');
          },
          backgroundColor: Colors.green.shade600,
          child: const Icon(Icons.add),
        );
      case 3: // Budgets
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/add-budget');
          },
          backgroundColor: Colors.purple.shade600,
          child: const Icon(Icons.add),
        );
      case 4: // More page - no FAB needed
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}