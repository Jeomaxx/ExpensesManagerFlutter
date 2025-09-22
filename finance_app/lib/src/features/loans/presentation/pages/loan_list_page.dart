import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/loan_providers.dart';

class LoanListPage extends ConsumerWidget {
  const LoanListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user ID from auth provider
    final authState = ref.watch(authProvider);
    
    if (authState.user?.id == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view loans')),
      );
    }

    final userId = authState.user!.id;
    final loansAsync = ref.watch(loansProvider(userId));
    final totalBalanceAsync = ref.watch(totalOutstandingBalanceProvider(userId));
    final monthlyPaymentAsync = ref.watch(monthlyPaymentTotalProvider(userId));
    final upcomingPaymentsAsync = ref.watch(upcomingPaymentsProvider(
      UpcomingPaymentsParams(userId: userId, days: 30)
    ));
    final overduePaymentsAsync = ref.watch(overduePaymentsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/add-loan');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loansProvider(userId));
          ref.invalidate(totalOutstandingBalanceProvider(userId));
          ref.invalidate(monthlyPaymentTotalProvider(userId));
          ref.invalidate(upcomingPaymentsProvider(
            UpcomingPaymentsParams(userId: userId, days: 30)
          ));
          ref.invalidate(overduePaymentsProvider(userId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummaryCards(
                context,
                totalBalanceAsync,
                monthlyPaymentAsync,
                upcomingPaymentsAsync,
                overduePaymentsAsync,
              ),
              
              const SizedBox(height: 24),
              
              // Loans List
              _buildLoansSection(context, ref, loansAsync, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncValue<double> totalBalanceAsync,
    AsyncValue<double> monthlyPaymentAsync,
    AsyncValue<List<LoanPayment>> upcomingPaymentsAsync,
    AsyncValue<List<LoanPayment>> overduePaymentsAsync,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Outstanding',
                totalBalanceAsync.when(
                  data: (balance) => CurrencyFormatter.formatAmount(balance),
                  loading: () => 'Loading...',
                  error: (_, __) => 'Error',
                ),
                Icons.account_balance,
                Colors.red.shade100,
                Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Monthly Payment',
                monthlyPaymentAsync.when(
                  data: (payment) => CurrencyFormatter.formatAmount(payment),
                  loading: () => 'Loading...',
                  error: (_, __) => 'Error',
                ),
                Icons.payment,
                Colors.blue.shade100,
                Colors.blue.shade600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Upcoming (30 days)',
                upcomingPaymentsAsync.when(
                  data: (payments) => '${payments.length} payments',
                  loading: () => 'Loading...',
                  error: (_, __) => 'Error',
                ),
                Icons.schedule,
                Colors.orange.shade100,
                Colors.orange.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overdue',
                overduePaymentsAsync.when(
                  data: (payments) => '${payments.length} payments',
                  loading: () => 'Loading...',
                  error: (_, __) => 'Error',
                ),
                Icons.warning,
                Colors.red.shade100,
                Colors.red.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Loan>> loansAsync,
    String userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Loans',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        loansAsync.when(
          data: (loans) {
            if (loans.isEmpty) {
              return _buildEmptyState(context);
            }
            
            return Column(
              children: loans.map((loan) => _buildLoanCard(context, loan)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              children: [
                Icon(Icons.error, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading loans',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(loansProvider(userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.account_balance,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No loans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first loan to start tracking payments',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/add-loan');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(BuildContext context, Loan loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/loan-details', arguments: loan.id);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.lender,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: loan.isActive ? Colors.green.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loan.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: loan.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(loan.remainingBalance),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(loan.monthlyPayment),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              if (loan.nextPayment != null) ...[
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Next payment: ${DateFormatter.formatDate(loan.nextPayment!.dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}