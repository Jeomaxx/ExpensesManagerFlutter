enum AccountType {
  cash,
  bankCard,
  mobileWallet,
  savings,
  checking,
  credit,
}

class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final String currency;
  final double balance;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.cash,
      ),
      currency: json['currency'] as String,
      balance: (json['balance'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
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
      'currency': currency,
      'balance': balance,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    String? currency,
    double? balance,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}