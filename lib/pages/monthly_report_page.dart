import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../utils/loan_provider.dart';
import '../theme/theme_controller.dart';
import 'loan_details_page.dart';

class MonthGroup {
  final DateTime monthDate;
  final List<Person> loans;

  MonthGroup(this.monthDate, this.loans);

  String get name => DateFormat('MMMM yyyy').format(monthDate);
}

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  final Set<DateTime> _expandedMonths = {};

  void _toggleExpand(DateTime monthDate) {
    setState(() {
      if (_expandedMonths.contains(monthDate)) {
        _expandedMonths.remove(monthDate);
      } else {
        _expandedMonths.add(monthDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: cs.surface,
      body: Consumer<LoanProvider>(
        builder: (context, provider, child) {
          final people = provider.people;

          if (people.isEmpty) {
            return _buildEmptyState();
          }

          // Group loans by year and month
          final Map<DateTime, List<Person>> groupsMap = {};
          for (final p in people) {
            final dateKey = DateTime(p.loanDate.year, p.loanDate.month);
            groupsMap.putIfAbsent(dateKey, () => []).add(p);
          }

          // Convert to list and sort chronologically (most recent first)
          final List<MonthGroup> groups = groupsMap.entries.map((e) {
            return MonthGroup(e.key, e.value);
          }).toList()
            ..sort((a, b) => b.monthDate.compareTo(a.monthDate));

          // Calculate overall statistics
          double overallLoaned = 0;
          double overallInterest = 0;
          for (final p in people) {
            overallLoaned += p.amount;
            overallInterest += p.interestForTerm();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),

              // === PAGE HEADER ===
              _buildSectionHeader(
                icon: Icons.calendar_month_rounded,
                title: 'Monthly Summary',
              ),
              const SizedBox(height: 20),

              // === OVERALL STATISTICS ROW ===
              _buildOverallSummaryCard(
                overallLoaned: overallLoaned,
                overallInterest: overallInterest,
                monthsCount: groups.length,
                currency: currency,
              ),
              const SizedBox(height: 24),

              // === LIST OF MONTH GROUPS ===
              Text(
                'Monthly Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isExpanded = _expandedMonths.contains(group.monthDate);

                  // Calculate group specific totals
                  double monthLoaned = 0;
                  double monthInterest = 0;
                  int paidCount = 0;
                  int activeCount = 0;

                  for (final p in group.loans) {
                    monthLoaned += p.amount;
                    monthInterest += p.interestForTerm();
                    if (p.isPaid) {
                      paidCount++;
                    } else {
                      activeCount++;
                    }
                  }

                  return _buildMonthCard(
                    group: group,
                    isExpanded: isExpanded,
                    monthLoaned: monthLoaned,
                    monthInterest: monthInterest,
                    activeCount: activeCount,
                    paidCount: paidCount,
                    currency: currency,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    final themeController = Provider.of<ThemeController>(context, listen: false);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeController.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: themeController.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOverallSummaryCard({
    required double overallLoaned,
    required double overallInterest,
    required int monthsCount,
    required NumberFormat currency,
  }) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.accent.withValues(alpha: 0.15),
            themeController.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeController.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All-Time Totals',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeController.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$monthsCount ${monthsCount == 1 ? "Month" : "Months"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: themeController.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Loaned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'K${currency.format(overallLoaned)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Interest',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'K${currency.format(overallInterest)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard({
    required MonthGroup group,
    required bool isExpanded,
    required double monthLoaned,
    required double monthInterest,
    required int activeCount,
    required int paidCount,
    required NumberFormat currency,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeController = Provider.of<ThemeController>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outline.withValues(alpha: 0.15),
        ),
      ),
      color: cs.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpand(group.monthDate),
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Title and Expand Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${group.loans.length} ${group.loans.length == 1 ? "loan" : "loans"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: themeController.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrics Grid (2 columns)
                  Row(
                    children: [
                      // Month Loaned Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on_outlined,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Loaned',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'K${currency.format(monthLoaned)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Month Interest Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Interest',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'K${currency.format(monthInterest)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable List of Loans
          if (isExpanded) ...[
            Container(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.loans.length,
                    itemBuilder: (context, i) {
                      final loan = group.loans[i];
                      final daysLeft = loan.dueDate.difference(DateTime.now()).inDays;
                      final isOverdue = daysLeft < 0 && !loan.isPaid;
                      final isDueSoon = daysLeft >= 0 && daysLeft <= 7 && !loan.isPaid;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoanDetailsPage(person: loan),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Borrower name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(loan.loanDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Amounts
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'K${loan.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '+K${loan.interestForTerm().toStringAsFixed(0)} int.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    loan.isPaid,
                                    isOverdue,
                                    isDueSoon,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    _getStatusText(
                                    loan.isPaid,
                                    isOverdue,
                                    isDueSoon,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(
                                      loan.isPaid,
                                      isOverdue,
                                      isDueSoon,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(bool isPaid, bool isOverdue, bool isDueSoon) {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isDueSoon) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText(bool isPaid, bool isOverdue, bool isDueSoon) {
    if (isPaid) return 'PAID';
    if (isOverdue) return 'OVERDUE';
    if (isDueSoon) return 'DUE SOON';
    return 'ACTIVE';
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No loan reports yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first loan to view monthly stats.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
