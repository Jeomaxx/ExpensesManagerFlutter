import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/transaction_list_page.dart';
import '../../features/transactions/presentation/pages/transaction_details_page.dart';
import '../../features/accounts/presentation/pages/account_list_page.dart';
import '../../features/accounts/presentation/pages/add_account_page.dart';
import '../../features/accounts/presentation/pages/account_details_page.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String addTransaction = '/add-transaction';
  static const String transactionsList = '/transactions';
  static const String transactionDetails = '/transaction-details';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String accountDetails = '/account-details';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String investments = '/investments';
  static const String loans = '/loans';
  static const String reports = '/reports';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
          settings: settings,
        );
      
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingPage(),
          settings: settings,
        );
      
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
      
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: settings,
        );
      
      case addTransaction:
        final transaction = settings.arguments as Transaction?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionPage(editingTransaction: transaction),
          settings: settings,
        );
      
      case transactionsList:
        return MaterialPageRoute(
          builder: (_) => const TransactionListPage(),
          settings: settings,
        );
      
      case transactionDetails:
        final transaction = settings.arguments as Transaction;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailsPage(transaction: transaction),
          settings: settings,
        );
      
      case accounts:
        return MaterialPageRoute(
          builder: (_) => const AccountListPage(),
          settings: settings,
        );
      
      case addAccount:
        final account = settings.arguments as Account?;
        return MaterialPageRoute(
          builder: (_) => AddAccountPage(editingAccount: account),
          settings: settings,
        );
      
      case accountDetails:
        final account = settings.arguments as Account;
        return MaterialPageRoute(
          builder: (_) => AccountDetailsPage(account: account),
          settings: settings,
        );
      
      // TODO: Add other routes as pages are implemented
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Under Development')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.construction, size: 64),
                  const SizedBox(height: 16),
                  Text('Page under development: ${settings.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(_).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}