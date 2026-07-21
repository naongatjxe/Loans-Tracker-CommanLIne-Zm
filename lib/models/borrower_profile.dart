import 'person.dart';

class BorrowerProfile {
  final String nrc;
  final String name;
  final String phone;
  final String workplace;
  final List<Person> loans;

  BorrowerProfile({
    required this.nrc,
    required this.name,
    required this.phone,
    required this.workplace,
    required this.loans,
  });

  double get totalBorrowed => loans.fold(0.0, (sum, l) => sum + l.amount);

  double get totalOutstanding {
    final now = DateTime.now();
    return loans.fold(0.0, (sum, l) => sum + l.calculateAmountDue(now));
  }

  int get activeLoansCount => loans.where((l) => !l.isPaid).length;
  int get paidLoansCount => loans.where((l) => l.isPaid).length;

  double get trustRating {
    int totalFinished = 0;
    int onTimeFinished = 0;

    for (var loan in loans) {
      if (loan.isPaid) {
        totalFinished++;
        if (loan.repayments.isNotEmpty) {
          final lastRepDate = loan.repayments.fold<DateTime>(
            loan.loanDate,
            (maxDate, r) => r.date.isAfter(maxDate) ? r.date : maxDate,
          );
          final lastRepMidnight = DateTime(lastRepDate.year, lastRepDate.month, lastRepDate.day);
          final dueMidnight = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
          if (lastRepMidnight.difference(dueMidnight).inDays <= 0) {
            onTimeFinished++;
          }
        } else {
          onTimeFinished++;
        }
      } else {
        // Unpaid and overdue reduces rating
        final dueMidnight = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
        final nowMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (nowMidnight.difference(dueMidnight).inDays > 0) {
          totalFinished++; // Count overdue unpaid loans as "finished period" but not on-time
        }
      }
    }

    if (totalFinished == 0) return 100.0;
    final rating = (onTimeFinished / totalFinished) * 100.0;
    return rating < 0 ? 0.0 : rating;
  }
}
