import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/loan.dart';
import '../models/investment.dart';

class AIInsightsService {
  static final AIInsightsService _instance = AIInsightsService._internal();
  static AIInsightsService get instance => _instance;
  AIInsightsService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;
    
    final key = apiKey ?? const String.fromEnvironment('GOOGLE_AI_API_KEY');
    if (key.isEmpty) {
      print('Google AI API key not provided - AI insights will be disabled');
      return;
    }
    
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 32,
          topP: 1,
          maxOutputTokens: 2048,
        ),
      );
      _isInitialized = true;
      print('AI Insights service initialized successfully');
    } catch (e) {
      print('Failed to initialize AI Insights service: $e');
    }
  }

  Future<String> generateSpendingAnalysis(List<Transaction> transactions, List<Budget> budgets) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final spendingData = _prepareSpendingData(transactions, budgets);
      final prompt = '''
As a financial advisor AI, analyze the following spending data and provide insights:

$spendingData

Please provide:
1. Spending pattern analysis
2. Budget adherence assessment
3. Recommendations for improvement
4. Potential savings opportunities
5. Financial health score (1-10)

Keep the response concise and actionable.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate analysis at this time.';
    } catch (e) {
      print('Error generating spending analysis: $e');
      return 'Error generating analysis. Please try again later.';
    }
  }

  Future<String> generateInvestmentAdvice(List<Investment> investments, double totalBalance) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final investmentData = _prepareInvestmentData(investments, totalBalance);
      final prompt = '''
As a financial advisor AI, analyze the following investment portfolio:

$investmentData

Please provide:
1. Portfolio diversification analysis
2. Risk assessment
3. Performance evaluation
4. Rebalancing suggestions
5. Investment recommendations

Keep the response practical and tailored to the data provided.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate investment advice at this time.';
    } catch (e) {
      print('Error generating investment advice: $e');
      return 'Error generating advice. Please try again later.';
    }
  }

  Future<String> generateBudgetRecommendations(List<Transaction> transactions, List<Budget> budgets, double income) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final budgetData = _prepareBudgetData(transactions, budgets, income);
      final prompt = '''
As a financial advisor AI, analyze the following budget and spending data:

$budgetData

Please provide:
1. Budget optimization suggestions
2. Category-wise spending recommendations
3. Emergency fund assessment
4. Debt-to-income ratio analysis
5. Actionable next steps

Focus on practical, achievable recommendations.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate budget recommendations at this time.';
    } catch (e) {
      print('Error generating budget recommendations: $e');
      return 'Error generating recommendations. Please try again later.';
    }
  }

  Future<String> generateGoalStrategy(List<Goal> goals, double currentBalance, double monthlyIncome) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final goalData = _prepareGoalData(goals, currentBalance, monthlyIncome);
      final prompt = '''
As a financial advisor AI, analyze the following financial goals:

$goalData

Please provide:
1. Goal prioritization strategy
2. Timeline feasibility assessment
3. Monthly savings recommendations
4. Risk considerations
5. Alternative approaches

Provide specific, actionable advice for achieving these goals.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate goal strategy at this time.';
    } catch (e) {
      print('Error generating goal strategy: $e');
      return 'Error generating strategy. Please try again later.';
    }
  }

  Future<String> generateDebtManagementPlan(List<Loan> loans, double monthlyIncome) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final debtData = _prepareDebtData(loans, monthlyIncome);
      final prompt = '''
As a financial advisor AI, analyze the following debt situation:

$debtData

Please provide:
1. Debt payoff strategy (avalanche vs snowball)
2. Payment prioritization
3. Consolidation opportunities
4. Interest rate optimization
5. Timeline for debt freedom

Focus on practical steps to reduce debt burden efficiently.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate debt management plan at this time.';
    } catch (e) {
      print('Error generating debt management plan: $e');
      return 'Error generating plan. Please try again later.';
    }
  }

  Future<String> generateFinancialHealthReport(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<Investment> investments,
    List<Goal> goals,
    List<Loan> loans,
    double totalAssets,
  ) async {
    if (!_isInitialized || _model == null) {
      return 'AI insights are not available. Please check your API key configuration.';
    }

    try {
      final financialData = _prepareFinancialHealthData(
        transactions, budgets, investments, goals, loans, totalAssets
      );
      
      final prompt = '''
As a financial advisor AI, provide a comprehensive financial health assessment:

$financialData

Please provide:
1. Overall financial health score (1-10) with explanation
2. Strengths in current financial situation
3. Areas needing immediate attention
4. Risk assessment
5. 3-month action plan
6. Long-term financial outlook

Provide a balanced, honest assessment with specific improvement steps.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate financial health report at this time.';
    } catch (e) {
      print('Error generating financial health report: $e');
      return 'Error generating report. Please try again later.';
    }
  }

  String _prepareSpendingData(List<Transaction> transactions, List<Budget> budgets) {
    final now = DateTime.now();
    final thisMonth = transactions.where((t) => 
      t.date.month == now.month && t.date.year == now.year
    ).toList();
    
    final categorySums = <String, double>{};
    for (final transaction in thisMonth) {
      if (transaction.type == TransactionType.expense) {
        categorySums[transaction.categoryId] = 
          (categorySums[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    
    final budgetComparison = budgets.map((budget) {
      final spent = categorySums[budget.categoryId] ?? 0;
      final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0;
      return 'Category: ${budget.categoryId}, Budget: ${budget.amount}, Spent: $spent, Usage: ${percentage.toStringAsFixed(1)}%';
    }).join('\n');
    
    return '''
Monthly Spending Summary:
Total Categories: ${categorySums.length}
Total Spent: ${categorySums.values.fold(0.0, (a, b) => a + b)}

Budget vs Actual:
$budgetComparison

Recent transactions: ${thisMonth.take(10).map((t) => '${t.description}: ${t.amount}').join(', ')}
''';
  }

  String _prepareInvestmentData(List<Investment> investments, double totalBalance) {
    final totalInvested = investments.fold(0.0, (sum, inv) => sum + inv.amount);
    final totalCurrent = investments.fold(0.0, (sum, inv) => sum + (inv.currentValue ?? inv.amount));
    final totalROI = totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested) * 100 : 0;
    
    final typeBreakdown = <InvestmentType, double>{};
    for (final investment in investments) {
      typeBreakdown[investment.type] = (typeBreakdown[investment.type] ?? 0) + investment.amount;
    }
    
    return '''
Investment Portfolio Summary:
Total Invested: $totalInvested
Current Value: $totalCurrent
Overall ROI: ${totalROI.toStringAsFixed(2)}%
Cash Available: $totalBalance

Asset Allocation:
${typeBreakdown.entries.map((e) => '${e.key.name}: ${e.value} (${((e.value / totalInvested) * 100).toStringAsFixed(1)}%)').join('\n')}

Top Performers: ${investments.where((i) => i.roi > 0).take(3).map((i) => '${i.name}: ${i.roi.toStringAsFixed(1)}%').join(', ')}
''';
  }

  String _prepareBudgetData(List<Transaction> transactions, List<Budget> budgets, double income) {
    final monthlyExpenses = transactions
      .where((t) => t.type == TransactionType.expense && 
                   t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
    
    return '''
Budget Analysis:
Monthly Income: $income
Total Budget: $totalBudget
Actual Expenses: $monthlyExpenses
Budget Utilization: ${totalBudget > 0 ? ((monthlyExpenses / totalBudget) * 100).toStringAsFixed(1) : 0}%
Savings Rate: ${income > 0 ? (((income - monthlyExpenses) / income) * 100).toStringAsFixed(1) : 0}%

Budget Categories: ${budgets.length}
Active Budgets: ${budgets.where((b) => b.isActive).length}
''';
  }

  String _prepareGoalData(List<Goal> goals, double currentBalance, double monthlyIncome) {
    final activeGoals = goals.where((g) => g.isActive && !g.isCompleted).toList();
    final totalGoalAmount = activeGoals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = activeGoals.fold(0.0, (sum, g) => sum + g.currentAmount);
    
    return '''
Financial Goals Summary:
Active Goals: ${activeGoals.length}
Total Target: $totalGoalAmount
Total Saved: $totalSaved
Progress: ${totalGoalAmount > 0 ? ((totalSaved / totalGoalAmount) * 100).toStringAsFixed(1) : 0}%
Current Balance: $currentBalance
Monthly Income: $monthlyIncome

Goals Details:
${activeGoals.map((g) => '${g.name}: ${g.currentAmount}/${g.targetAmount} (${g.targetDate != null ? 'Target: ${g.targetDate}' : 'No deadline'})').join('\n')}
''';
  }

  String _prepareDebtData(List<Loan> loans, double monthlyIncome) {
    final activeLoans = loans.where((l) => l.isActive).toList();
    final totalDebt = activeLoans.fold(0.0, (sum, l) => sum + l.remainingBalance);
    final totalMonthlyPayment = activeLoans.fold(0.0, (sum, l) => sum + l.monthlyPayment);
    final debtToIncomeRatio = monthlyIncome > 0 ? (totalMonthlyPayment / monthlyIncome) * 100 : 0;
    
    return '''
Debt Analysis:
Active Loans: ${activeLoans.length}
Total Debt: $totalDebt
Monthly Payments: $totalMonthlyPayment
Debt-to-Income: ${debtToIncomeRatio.toStringAsFixed(1)}%
Monthly Income: $monthlyIncome

Loan Details:
${activeLoans.map((l) => '${l.lender}: ${l.remainingBalance} (${l.interestRate}% APR, ${l.monthlyPayment}/month)').join('\n')}
''';
  }

  String _prepareFinancialHealthData(
    List<Transaction> transactions,
    List<Budget> budgets,
    List<Investment> investments,
    List<Goal> goals,
    List<Loan> loans,
    double totalAssets,
  ) {
    final monthlyIncome = transactions
      .where((t) => t.type == TransactionType.income &&
                   t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = transactions
      .where((t) => t.type == TransactionType.expense &&
                   t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
      .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalDebt = loans.where((l) => l.isActive).fold(0.0, (sum, l) => sum + l.remainingBalance);
    final netWorth = totalAssets - totalDebt;
    
    return '''
Comprehensive Financial Overview:
Net Worth: $netWorth
Total Assets: $totalAssets
Total Debt: $totalDebt
Monthly Income: $monthlyIncome
Monthly Expenses: $monthlyExpenses
Monthly Savings: ${monthlyIncome - monthlyExpenses}

Account Summary:
- Active Budgets: ${budgets.where((b) => b.isActive).length}
- Investment Portfolio: ${investments.length} investments
- Financial Goals: ${goals.where((g) => g.isActive).length} active
- Active Loans: ${loans.where((l) => l.isActive).length}

Key Ratios:
- Savings Rate: ${monthlyIncome > 0 ? (((monthlyIncome - monthlyExpenses) / monthlyIncome) * 100).toStringAsFixed(1) : 0}%
- Emergency Fund: ${monthlyExpenses > 0 ? (totalAssets / monthlyExpenses).toStringAsFixed(1) : 0} months
''';
  }
}