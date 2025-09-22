enum InvestmentType {
  stock,
  crypto,
  realEstate,
  bond,
  mutualFund,
  etf,
  commodity,
  other,
}

class Investment {
  final String id;
  final String userId;
  final String name;
  final InvestmentType type;
  final double amount;
  final DateTime date;
  final double? currentValue;
  final String? notes;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Investment({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.amount,
    required this.date,
    this.currentValue,
    this.notes,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  double get roi {
    if (currentValue == null || amount <= 0) return 0.0;
    return ((currentValue! - amount) / amount) * 100;
  }

  double get profitLoss {
    if (currentValue == null) return 0.0;
    return currentValue! - amount;
  }

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: InvestmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InvestmentType.other,
      ),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      currentValue: (json['currentValue'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'currentValue': currentValue,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Investment copyWith({
    String? id,
    String? userId,
    String? name,
    InvestmentType? type,
    double? amount,
    DateTime? date,
    double? currentValue,
    String? notes,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Investment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      currentValue: currentValue ?? this.currentValue,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}