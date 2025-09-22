enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final String? recurringId;
  final List<String> tags;
  final Map<String, dynamic>? splitData;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.notes,
    this.receiptUrl,
    this.recurringId,
    this.tags = const [],
    this.splitData,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      accountId: json['accountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      recurringId: json['recurringId'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      splitData: json['splitData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'notes': notes,
      'receiptUrl': receiptUrl,
      'recurringId': recurringId,
      'tags': tags,
      'splitData': splitData,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? notes,
    String? receiptUrl,
    String? recurringId,
    List<String>? tags,
    Map<String, dynamic>? splitData,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      recurringId: recurringId ?? this.recurringId,
      tags: tags ?? this.tags,
      splitData: splitData ?? this.splitData,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}