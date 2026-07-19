import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/contract.dart';
import 'notification_service.dart';

class LoanProvider with ChangeNotifier {
  List<Person> _people = [];
  List<Contract> _contracts = [];

  List<Person> get people => _people;
  List<Contract> get contracts => _contracts;

  LoanProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load people
    final peopleJson = prefs.getStringList('people') ?? [];
    _people = peopleJson
        .map((json) => Person.fromMap(jsonDecode(json)))
        .toList();

    // Load contracts
    final contractsJson = prefs.getStringList('contracts') ?? [];
    _contracts = contractsJson
        .map((json) => Contract.fromMap(jsonDecode(json)))
        .toList();

    notifyListeners();

    // Schedule notifications for loaded loans (if enabled)
    try {
      await rescheduleAllNotifications();
    } catch (_) {}
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save people
    final peopleJson = _people
        .map((person) => jsonEncode(person.toMap()))
        .toList();
    await prefs.setStringList('people', peopleJson);

    // Save contracts
    final contractsJson = _contracts
        .map((contract) => jsonEncode(contract.toMap()))
        .toList();
    await prefs.setStringList('contracts', contractsJson);
  }

  // Add a new person
  Future<void> addPerson(Person person) async {
    _people.add(person);
    await _saveData();
    notifyListeners();

    // Schedule notifications for this loan
    try {
      await NotificationService().scheduleLoanNotifications(person);
    } catch (_) {
      // ignore errors
    }
  }

  // Update a person
  Future<void> updatePerson(Person person) async {
    final index = _people.indexWhere((p) => p.id == person.id);
    if (index >= 0) {
      _people[index] = person;
      await _saveData();
      notifyListeners();

      // Re-schedule notifications for this loan (update)
      try {
        await NotificationService().scheduleLoanNotifications(person);
      } catch (_) {
        // ignore errors
      }
    }
  }

  // Delete a person
  Future<void> deletePerson(String id) async {
    // Cancel notifications related to this loan
    try {
      await NotificationService().cancelLoanNotifications(id);
    } catch (_) {}

    _people.removeWhere((person) => person.id == id);
    await _saveData();
    notifyListeners();
  }

  // Add a new contract
  Future<void> addContract(Contract contract) async {
    _contracts.add(contract);
    await _saveData();
    notifyListeners();
  }

  // Get a person by ID
  Person? getPersonById(String id) {
    try {
      return _people.firstWhere((person) => person.id == id);
    } catch (e) {
      return null;
    }
  }

  // Mark a loan as paid
  Future<void> markAsPaid(String personId) async {
    final index = _people.indexWhere((p) => p.id == personId);
    if (index >= 0) {
      final person = _people[index];
      _people[index] = person.copyWith(isPaid: true);
      await _saveData();
      notifyListeners();

      // Cancel scheduled notifications when loan is paid
      try {
        await NotificationService().cancelLoanNotifications(personId);
      } catch (_) {}
    }
  }

  /// Cancel notifications for all loans
  Future<void> cancelAllNotifications() async {
    for (final p in _people) {
      try {
        await NotificationService().cancelLoanNotifications(p.id);
      } catch (_) {}
    }
  }

  /// Reschedule notifications for all loans (if notifications are enabled)
  Future<void> rescheduleAllNotifications() async {
    if (!NotificationService().enabled) return;
    for (final p in _people) {
      try {
        await NotificationService().scheduleLoanNotifications(p);
      } catch (_) {}
    }
  }

  /// Mark a loan as unpaid. This reverses a previous payment action.
  Future<void> markAsUnpaid(String personId) async {
    final index = _people.indexWhere((p) => p.id == personId);
    if (index >= 0) {
      final person = _people[index];
      final updatedPerson = person.copyWith(isPaid: false);
      _people[index] = updatedPerson;
      await _saveData();
      notifyListeners();

      // Re-schedule notifications now that the loan is unpaid
      try {
        await NotificationService().scheduleLoanNotifications(updatedPerson);
      } catch (_) {}
    }
  }

  /// Import dataset from a backup file, replacing current loans and contracts.
  Future<void> importData(List<Person> importedPeople, List<Contract> importedContracts) async {
    // 1. Cancel all existing notifications
    await cancelAllNotifications();

    // 2. Overwrite local variables
    _people = importedPeople;
    _contracts = importedContracts;

    // 3. Save to SharedPreferences
    await _saveData();

    // 4. Reschedule notifications for the newly imported data
    await rescheduleAllNotifications();

    // 5. Notify UI of changes
    notifyListeners();
  }
}
