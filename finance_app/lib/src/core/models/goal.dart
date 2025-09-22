class GoalContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  const GoalContribution({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}

class Goal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String? linkedAccountId;
  final List<GoalContribution> contributions;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.linkedAccountId,
    this.contributions = const [],
    this.isCompleted = false,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.parse(json['targetDate'] as String),
      linkedAccountId: json['linkedAccountId'] as String?,
      contributions: (json['contributions'] as List?)
          ?.map((e) => GoalContribution.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'linkedAccountId': linkedAccountId,
      'contributions': contributions.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? linkedAccountId,
    List<GoalContribution>? contributions,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      contributions: contributions ?? this.contributions,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}