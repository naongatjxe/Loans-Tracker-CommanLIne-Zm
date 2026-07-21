import 'repayment.dart';

class Person {
  final String id;
  final String name;
  final String phone;
  final String nrc;
  final String workplace;
  final double amount;
  final double interestRate;
  final DateTime loanDate;
  final DateTime dueDate;
  final bool isPaid;

  // Advanced Feature Fields
  final List<Repayment> repayments;
  final String interestType; // 'flat', 'simple', 'compound'
  final String interestPeriod; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final double lateFeeRate; // daily penalty percentage
  final double lateFeeFlat; // flat late fee

  Person({
    required this.id,
    required this.name,
    required this.phone,
    required this.nrc,
    required this.workplace,
    required this.amount,
    required this.interestRate,
    required this.loanDate,
    required this.dueDate,
    this.isPaid = false,
    this.repayments = const [],
    this.interestType = 'flat',
    this.interestPeriod = 'none',
    this.lateFeeRate = 0.0,
    this.lateFeeFlat = 0.0,
  });

  Person copyWith({
    String? id,
    String? name,
    String? phone,
    String? nrc,
    String? workplace,
    double? amount,
    double? interestRate,
    DateTime? loanDate,
    DateTime? dueDate,
    bool? isPaid,
    List<Repayment>? repayments,
    String? interestType,
    String? interestPeriod,
    double? lateFeeRate,
    double? lateFeeFlat,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nrc: nrc ?? this.nrc,
      workplace: workplace ?? this.workplace,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      repayments: repayments ?? this.repayments,
      interestType: interestType ?? this.interestType,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      lateFeeRate: lateFeeRate ?? this.lateFeeRate,
      lateFeeFlat: lateFeeFlat ?? this.lateFeeFlat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nrc': nrc,
      'workplace': workplace,
      'amount': amount,
      'interestRate': interestRate,
      'loanDate': loanDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'repayments': repayments.map((r) => r.toMap()).toList(),
      'interestType': interestType,
      'interestPeriod': interestPeriod,
      'lateFeeRate': lateFeeRate,
      'lateFeeFlat': lateFeeFlat,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    var rawRepayments = map['repayments'] as List<dynamic>?;
    List<Repayment> repList = rawRepayments != null
        ? rawRepayments.map((r) => Repayment.fromMap(r as Map<String, dynamic>)).toList()
        : [];

    return Person(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      nrc: map['nrc'] ?? '',
      workplace: map['workplace'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.0,
      loanDate: DateTime.fromMillisecondsSinceEpoch(map['loanDate']),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      isPaid: map['isPaid'] ?? false,
      repayments: repList,
      interestType: map['interestType'] ?? 'flat',
      interestPeriod: map['interestPeriod'] ?? 'none',
      lateFeeRate: (map['lateFeeRate'] as num?)?.toDouble() ?? 0.0,
      lateFeeFlat: (map['lateFeeFlat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double getPaidRepaymentsSum() {
    return repayments.fold(0.0, (sum, item) => sum + item.amount);
  }

  double calculatePeriods(DateTime currentDate) {
    final diff = currentDate.difference(loanDate).inDays;
    if (diff <= 0) return 0.0;

    switch (interestPeriod) {
      case 'daily':
        return diff.toDouble();
      case 'weekly':
        return diff / 7.0;
      case 'monthly':
        return diff / 30.0;
      case 'yearly':
        return diff / 365.0;
      default:
        return 1.0;
    }
  }

  double calculateStandardInterest(DateTime currentDate) {
    return amount * (interestRate / 100);
  }

  double calculateLateFees(DateTime currentDate) {
    return 0.0;
  }

  double calculateTotalExpectedDue(DateTime currentDate) {
    final interest = calculateStandardInterest(currentDate);
    final lateFees = calculateLateFees(currentDate);
    return amount + interest + lateFees;
  }

  double calculateAmountDue(DateTime currentDate) {
    if (isPaid) return 0.0;
    final totalExpected = calculateTotalExpectedDue(currentDate);
    final remaining = totalExpected - getPaidRepaymentsSum();
    return remaining < 0 ? 0.0 : remaining;
  }

  double calculateTotalAmount() {
    return calculateTotalExpectedDue(dueDate);
  }

  double interestForTerm() {
    return calculateStandardInterest(dueDate);
  }

  double totalForTerm() {
    return calculateTotalExpectedDue(dueDate);
  }
}
