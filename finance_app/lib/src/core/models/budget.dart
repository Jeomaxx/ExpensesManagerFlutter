enum BudgetType {
  monthly,
  weekly,
  yearly,
  custom,
}

enum BudgetStatus {
  onTrack,      // Spending is within budget
  warning,      // Spending is approaching limit (80-99%)
  exceeded,     // Spending has exceeded the budget
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final double amount;        // Budget limit amount
  final BudgetType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime lastModified;
  
  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.description,
    required this.createdAt,
    required this.lastModified,
  });

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    double? amount,
    BudgetType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'type': type.index,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      categoryId: map['category_id'] ?? '',
      name: map['name'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      type: BudgetType.values[map['type'] ?? 0],
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['end_date'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      description: map['description'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      lastModified: DateTime.parse(map['last_modified'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, amount: $amount, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Budget with spending data for display
class BudgetWithSpending {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;
  final BudgetStatus status;
  final int transactionCount;

  const BudgetWithSpending({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
    required this.transactionCount,
  });

  factory BudgetWithSpending.fromBudget(Budget budget, double spent, int transactionCount) {
    final remaining = budget.amount - spent;
    final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
    
    BudgetStatus status;
    if (percentage >= 100) {
      status = BudgetStatus.exceeded;
    } else if (percentage >= 80) {
      status = BudgetStatus.warning;
    } else {
      status = BudgetStatus.onTrack;
    }

    return BudgetWithSpending(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      status: status,
      transactionCount: transactionCount,
    );
  }
}