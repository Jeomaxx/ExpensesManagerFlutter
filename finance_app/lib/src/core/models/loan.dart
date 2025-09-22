class LoanPayment {
  final String id;
  final int paymentNumber;
  final double amount;
  final double principal;
  final double interest;
  final double remainingBalance;
  final DateTime dueDate;
  final DateTime? paidDate;
  final bool isPaid;

  const LoanPayment({
    required this.id,
    required this.paymentNumber,
    required this.amount,
    required this.principal,
    required this.interest,
    required this.remainingBalance,
    required this.dueDate,
    this.paidDate,
    this.isPaid = false,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: json['id'] as String,
      paymentNumber: json['paymentNumber'] as int,
      amount: (json['amount'] as num).toDouble(),
      principal: (json['principal'] as num).toDouble(),
      interest: (json['interest'] as num).toDouble(),
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null 
          ? DateTime.parse(json['paidDate'] as String) 
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentNumber': paymentNumber,
      'amount': amount,
      'principal': principal,
      'interest': interest,
      'remainingBalance': remainingBalance,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
    };
  }
}

class Loan {
  final String id;
  final String userId;
  final String lender;
  final double principal;
  final double interestRate;
  final DateTime startDate;
  final int termMonths;
  final double monthlyPayment;
  final DateTime firstPaymentDate;
  final List<LoanPayment> schedule;
  final List<LoanPayment> payments;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isDeleted;

  const Loan({
    required this.id,
    required this.userId,
    required this.lender,
    required this.principal,
    required this.interestRate,
    required this.startDate,
    required this.termMonths,
    required this.monthlyPayment,
    required this.firstPaymentDate,
    this.schedule = const [],
    this.payments = const [],
    this.isActive = true,
    required this.createdAt,
    required this.lastModified,
    this.isDeleted = false,
  });

  double get remainingBalance {
    double totalPaid = payments
        .where((p) => p.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.principal);
    return principal - totalPaid;
  }

  LoanPayment? get nextPayment {
    return schedule
        .where((payment) => !payment.isPaid && payment.dueDate.isAfter(DateTime.now()))
        .isNotEmpty
        ? schedule
            .where((payment) => !payment.isPaid && payment.dueDate.isAfter(DateTime.now()))
            .reduce((a, b) => a.dueDate.isBefore(b.dueDate) ? a : b)
        : null;
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lender: json['lender'] as String,
      principal: (json['principal'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      termMonths: json['termMonths'] as int,
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      firstPaymentDate: DateTime.parse(json['firstPaymentDate'] as String),
      schedule: (json['schedule'] as List?)
          ?.map((e) => LoanPayment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      payments: (json['payments'] as List?)
          ?.map((e) => LoanPayment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
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
      'lender': lender,
      'principal': principal,
      'interestRate': interestRate,
      'startDate': startDate.toIso8601String(),
      'termMonths': termMonths,
      'monthlyPayment': monthlyPayment,
      'firstPaymentDate': firstPaymentDate.toIso8601String(),
      'schedule': schedule.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  Loan copyWith({
    String? id,
    String? userId,
    String? lender,
    double? principal,
    double? interestRate,
    DateTime? startDate,
    int? termMonths,
    double? monthlyPayment,
    DateTime? firstPaymentDate,
    List<LoanPayment>? schedule,
    List<LoanPayment>? payments,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lender: lender ?? this.lender,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      termMonths: termMonths ?? this.termMonths,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      schedule: schedule ?? this.schedule,
      payments: payments ?? this.payments,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}