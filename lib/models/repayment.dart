class Repayment {
  final String id;
  final double amount;
  final DateTime date;
  final String notes;

  Repayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory Repayment.fromMap(Map<String, dynamic> map) {
    return Repayment(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? DateTime.now().millisecondsSinceEpoch),
      notes: map['notes'] ?? '',
    );
  }
}
