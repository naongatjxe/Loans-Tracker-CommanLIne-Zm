import 'person.dart';

class Contract {
  final String id;
  final Person person;
  final String companyName;
  final String lenderPhone;
  final String lenderAddress;
  final DateTime creationDate;
  final String terms;

  Contract({
    required this.id,
    required this.person,
    required this.companyName,
    this.lenderPhone = '',
    this.lenderAddress = '',
    required this.creationDate,
    this.terms = '',
  });

  Contract copyWith({
    String? id,
    Person? person,
    String? companyName,
    String? lenderPhone,
    String? lenderAddress,
    DateTime? creationDate,
    String? terms,
  }) {
    return Contract(
      id: id ?? this.id,
      person: person ?? this.person,
      companyName: companyName ?? this.companyName,
      lenderPhone: lenderPhone ?? this.lenderPhone,
      lenderAddress: lenderAddress ?? this.lenderAddress,
      creationDate: creationDate ?? this.creationDate,
      terms: terms ?? this.terms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person': person.toMap(),
      'companyName': companyName,
      'lenderPhone': lenderPhone,
      'lenderAddress': lenderAddress,
      'creationDate': creationDate.millisecondsSinceEpoch,
      'terms': terms,
    };
  }

  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'],
      person: Person.fromMap(map['person']),
      companyName: map['companyName'],
      lenderPhone: map['lenderPhone'] ?? '',
      lenderAddress: map['lenderAddress'] ?? '',
      creationDate: DateTime.fromMillisecondsSinceEpoch(map['creationDate']),
      terms: map['terms'] ?? '',
    );
  }
}
