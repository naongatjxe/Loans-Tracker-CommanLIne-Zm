import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../utils/loan_provider.dart';
import '../theme/theme_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<LoanProvider>(
        builder: (context, provider, child) {
          final people = provider.people;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                _buildSectionHeader(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard Overview',
                ),
                const SizedBox(height: 24),

                // Main Stats Cards
                _buildMainStatsSection(people),
                const SizedBox(height: 32),

                // Additional Analytics
                _buildSectionHeader(
                  icon: Icons.analytics_rounded,
                  title: 'Analytics',
                ),
                const SizedBox(height: 16),

                _buildAnalyticsSection(people),
                const SizedBox(height: 32),

                // Recent Activity
                _buildSectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Recent Activity',
                ),
                const SizedBox(height: 16),

                _buildRecentActivitySection(people),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainStatsSection(List<Person> people) {
    final currency = NumberFormat('#,##0.00');
    double totalLoaned = 0, totalInterest = 0, totalOutstanding = 0, interestEarned = 0;
    int overdue = 0;
    double overdueAmount = 0;

    for (final p in people) {
      totalLoaned += p.amount;
      final loanInterest = p.amount * (p.interestRate / 100);

      if (!p.isPaid) {
        totalInterest += loanInterest;
        totalOutstanding += p.calculateAmountDue(DateTime.now());

        final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final dueMidnight = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
        if (dueMidnight.isBefore(todayMidnight)) {
          overdue++;
          overdueAmount += p.calculateAmountDue(DateTime.now());
        }
      } else {
        interestEarned += loanInterest;
      }
    }

    return Column(
      children: [
        // First row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Loaned',
                  'K${currency.format(totalLoaned)}',
                  Icons.account_balance_wallet_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Outstanding',
                  'K${currency.format(totalOutstanding)}',
                  Icons.payment_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Second row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Interest',
                  'K${currency.format(totalInterest)}',
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Interest Earned',
                  'K${currency.format(interestEarned)}',
                  Icons.monetization_on,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Third row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Overdue Loans',
                  overdue.toString(),
                  Icons.warning_rounded,
                  overdue > 0 ? Colors.red : Colors.grey,
                  highlight: overdue > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Overdue Amount',
                  'K${currency.format(overdueAmount)}',
                  Icons.report_problem_rounded,
                  overdue > 0 ? Colors.red : Colors.grey,
                  highlight: overdue > 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(List<Person> people) {
    final paidLoans = people.where((p) => p.isPaid).length;
    final activeLoans = people.where((p) => !p.isPaid).length;
    final totalLoans = people.length;
    final currency = NumberFormat('#,##0.00');

    double avgLoanAmount = 0;
    if (people.isNotEmpty) {
      avgLoanAmount =
          people.map((p) => p.amount).reduce((a, b) => a + b) / people.length;
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Loans',
                  totalLoans.toString(),
                  Icons.receipt_long_rounded,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Loans',
                  activeLoans.toString(),
                  Icons.hourglass_empty_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Paid Loans',
                  paidLoans.toString(),
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Avg. Amount',
                  'K${currency.format(avgLoanAmount)}',
                  Icons.calculate_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(List<Person> people) {
    // Sort by loan date, most recent first
    final recentLoans = [...people]
      ..sort((a, b) => b.loanDate.compareTo(a.loanDate));

    final recentItems = recentLoans.take(5).toList();

    if (recentItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: recentItems.asMap().entries.map((entry) {
        final person = entry.value;
        return _buildRecentActivityItem(person);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No loan data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first loan to see analytics',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Provider.of<ThemeController>(
              context,
              listen: false,
            ).accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Provider.of<ThemeController>(context, listen: false).accent,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? Colors.red.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.3),
          width: highlight ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildRecentActivityItem(Person person) {
    final currency = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: person.isPaid
                  ? Colors.green.withValues(alpha: 0.1)
                  : Provider.of<ThemeController>(
                      context,
                      listen: false,
                    ).accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              person.isPaid ? Icons.check_circle : Icons.person,
              color: person.isPaid
                  ? Colors.green
                  : Provider.of<ThemeController>(context, listen: false).accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'K${currency.format(person.amount)} • ${dateFormat.format(person.loanDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: person.isPaid
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              person.isPaid ? 'PAID' : 'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: person.isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
