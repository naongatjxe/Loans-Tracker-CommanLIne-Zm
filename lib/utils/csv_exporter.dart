import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/person.dart';
import 'package:intl/intl.dart';

class CsvExporter {
  static Future<Directory> _getPublicLoansTrackerDir() async {
    // Write directly to the app's internal temporary directory.
    // This allows creating the file without requiring any storage permissions.
    final temp = await getTemporaryDirectory();
    final baseDir = Directory('${temp.path}/Loans Tracker');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  static Future<String> exportLoansToCsv(List<Person> loans, {String? outputDirPath}) async {
    try {
      // Create CSV data
      List<List<String>> csvData = [
        // Header row
        [
          'Name',
          'NRC',
          'Phone',
          'Loan Amount',
          'Interest Rate (%)',
          'Interest (Term)',
          'Loan Date',
          'Due Date',
          'Status',
          'Total Amount Due',
        ],
      ];

      // Totals
      double totalLoaned = 0.0;
      double totalInterest = 0.0;
      double interestEarned = 0.0;

      // Add loan data
      for (Person loan in loans) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final currencyFormat = NumberFormat.currency(symbol: 'K ');

        final totalDue = loan.calculateTotalAmount();
        final interestTerm = totalDue - loan.amount;

        csvData.add([
          loan.name,
          loan.nrc,
          loan.phone,
          currencyFormat.format(loan.amount),
          '${loan.interestRate}%',
          currencyFormat.format(interestTerm),
          dateFormat.format(loan.loanDate),
          dateFormat.format(loan.dueDate),
          loan.isPaid ? 'Paid' : 'Active',
          currencyFormat.format(totalDue),
        ]);

        totalLoaned += loan.amount;
        totalInterest += interestTerm;
        if (loan.isPaid) interestEarned += interestTerm;
      }

      // Append an empty row then totals summary rows
      csvData.add([]);
      csvData.add(['Totals', '', '',
        NumberFormat.currency(symbol: 'K ').format(totalLoaned),
        '',
        NumberFormat.currency(symbol: 'K ').format(totalInterest),
        '',
        '',
        '',
        '']);

      csvData.add(['Interest Earned (paid loans)', '', '', '', '', '', '', '', '',
        NumberFormat.currency(symbol: 'K ').format(interestEarned)]);

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      final fileName = 'loans_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      late Directory dest;

      if (outputDirPath != null) {
        dest = Directory(outputDirPath);
        if (!await dest.exists()) {
          await dest.create(recursive: true);
        }
      } else {
        dest = await _getPublicLoansTrackerDir();
      }

      final file = File('${dest.path}/$fileName');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<String> exportMonthlyReportsToCsv(List<Person> loans, {String? outputDirPath}) async {
    try {
      // Group loans by year and month
      final Map<DateTime, List<Person>> groupsMap = {};
      for (final p in loans) {
        final dateKey = DateTime(p.loanDate.year, p.loanDate.month);
        groupsMap.putIfAbsent(dateKey, () => []).add(p);
      }

      // Convert to list and sort chronologically (most recent first)
      final List<DateTime> sortedKeys = groupsMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      List<List<String>> csvData = [
        // Header row
        [
          'Month',
          'Loans Count',
          'Total Loaned',
          'Collective Interest',
          'Total Expected Due',
        ],
      ];

      double overallLoaned = 0.0;
      double overallInterest = 0.0;
      int overallCount = 0;

      for (final dateKey in sortedKeys) {
        final monthLoans = groupsMap[dateKey]!;
        final monthName = DateFormat('MMMM yyyy').format(dateKey);

        double monthLoaned = 0;
        double monthInterest = 0;
        for (final p in monthLoans) {
          monthLoaned += p.amount;
          monthInterest += p.interestForTerm();
        }

        final monthTotal = monthLoaned + monthInterest;

        csvData.add([
          monthName,
          monthLoans.length.toString(),
          NumberFormat.currency(symbol: 'K ').format(monthLoaned),
          NumberFormat.currency(symbol: 'K ').format(monthInterest),
          NumberFormat.currency(symbol: 'K ').format(monthTotal),
        ]);

        overallLoaned += monthLoaned;
        overallInterest += monthInterest;
        overallCount += monthLoans.length;
      }

      // Append spacer and totals
      csvData.add([]);
      csvData.add([
        'Overall Totals',
        overallCount.toString(),
        NumberFormat.currency(symbol: 'K ').format(overallLoaned),
        NumberFormat.currency(symbol: 'K ').format(overallInterest),
        NumberFormat.currency(symbol: 'K ').format(overallLoaned + overallInterest),
      ]);

      String csvString = const ListToCsvConverter().convert(csvData);
      final fileName = 'monthly_report_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      late Directory dest;
      if (outputDirPath != null) {
        dest = Directory(outputDirPath);
        if (!await dest.exists()) {
          await dest.create(recursive: true);
        }
      } else {
        dest = await _getPublicLoansTrackerDir();
      }

      final file = File('${dest.path}/$fileName');
      await file.writeAsString(csvString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export Monthly CSV: $e');
    }
  }
}
