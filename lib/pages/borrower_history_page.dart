import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/borrower_profile.dart';
import '../models/person.dart';
import '../utils/loan_provider.dart';
import '../theme/theme_controller.dart';
import 'loan_details_page.dart';

class BorrowerHistoryPage extends StatefulWidget {
  const BorrowerHistoryPage({super.key});

  @override
  State<BorrowerHistoryPage> createState() => _BorrowerHistoryPageState();
}

class _BorrowerHistoryPageState extends State<BorrowerHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BorrowerProfile> _groupBorrowers(List<Person> loans) {
    final Map<String, List<Person>> grouped = {};
    for (var loan in loans) {
      final key = loan.nrc.trim();
      if (grouped.containsKey(key)) {
        grouped[key]!.add(loan);
      } else {
        grouped[key] = [loan];
      }
    }

    return grouped.entries.map((e) {
      // Find the most recent loan to extract the latest details
      final sortedLoans = List<Person>.from(e.value)
        ..sort((a, b) => b.loanDate.compareTo(a.loanDate));
      final latest = sortedLoans.first;

      return BorrowerProfile(
        nrc: e.key,
        name: latest.name,
        phone: latest.phone,
        workplace: latest.workplace,
        loans: e.value,
      );
    }).toList();
  }

  Color _getTrustColor(double rating) {
    if (rating >= 80) return Colors.green.shade600;
    if (rating >= 50) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  void _showBorrowerDetails(BuildContext context, BorrowerProfile profile) {
    final currencyFormat = NumberFormat('#,##0.00');
    final accent = Provider.of<ThemeController>(context, listen: false).accent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NRC: ${profile.nrc}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getTrustColor(profile.trustRating).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: _getTrustColor(profile.trustRating),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.trustRating.toStringAsFixed(0)}% Trust',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getTrustColor(profile.trustRating),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Contact Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.phone_rounded, color: accent),
                            title: Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            subtitle: Text(
                              profile.phone,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () => launchUrl(Uri.parse('tel:${profile.phone}')),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.message, color: Colors.blue),
                                  onPressed: () => launchUrl(Uri.parse('sms:${profile.phone}')),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.business_rounded, color: accent),
                            title: Text(
                              'Workplace / School',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            subtitle: Text(
                              profile.workplace,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Borrower Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          title: 'Total Borrowed',
                          value: 'K${currencyFormat.format(profile.totalBorrowed)}',
                          icon: Icons.payments_rounded,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          title: 'Outstanding',
                          value: 'K${currencyFormat.format(profile.totalOutstanding)}',
                          icon: Icons.pending_actions_rounded,
                          color: profile.totalOutstanding > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Loan History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${profile.loans.length} Loans',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // List of Historical Loans
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profile.loans.length,
                    itemBuilder: (context, index) {
                      final loan = profile.loans[index];
                      final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                      final dueMidnight = DateTime(loan.dueDate.year, loan.dueDate.month, loan.dueDate.day);
                      final isOverdue = !loan.isPaid && dueMidnight.isBefore(todayMidnight);

                      String dateDetail = 'Due: ${DateFormat('MMM d, yyyy').format(loan.dueDate)}';
                      if (!loan.isPaid) {
                        if (isOverdue) {
                          final days = todayMidnight.difference(dueMidnight).inDays;
                          dateDetail += ' • Overdue by $days d';
                        } else {
                          final days = dueMidnight.difference(todayMidnight).inDays;
                          if (days == 0) {
                            dateDetail += ' • Due Today';
                          } else {
                            dateDetail += ' • $days d remaining';
                          }
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoanDetailsPage(person: loan)),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: loan.isPaid
                                ? Colors.green.withValues(alpha: 0.1)
                                : (isOverdue ? Colors.red.withValues(alpha: 0.1) : accent.withValues(alpha: 0.1)),
                            child: Icon(
                              loan.isPaid ? Icons.check : (isOverdue ? Icons.warning : Icons.schedule),
                              color: loan.isPaid ? Colors.green : (isOverdue ? Colors.red : accent),
                            ),
                          ),
                          title: Text(
                            'K${currencyFormat.format(loan.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(dateDetail),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoanProvider>(context);
    final currencyFormat = NumberFormat('#,##0.00');

    // Get all grouped borrowers
    final borrowers = _groupBorrowers(provider.people);

    // Apply Search Filter
    final filteredBorrowers = borrowers.where((b) {
      final nameMatches = b.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final nrcMatches = b.nrc.contains(_searchQuery);
      return nameMatches || nrcMatches;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Borrowers'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or NRC...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: filteredBorrowers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No borrowers found',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBorrowers.length,
                    itemBuilder: (context, index) {
                      final profile = filteredBorrowers[index];
                      final todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                      final isOverdue = profile.loans.any((l) {
                        final dueMidnight = DateTime(l.dueDate.year, l.dueDate.month, l.dueDate.day);
                        return !l.isPaid && dueMidnight.isBefore(todayMidnight);
                      });

                      String statusText = 'Settled';
                      if (isOverdue) {
                        int maxDays = 0;
                        for (var l in profile.loans) {
                          if (!l.isPaid) {
                            final dueMidnight = DateTime(l.dueDate.year, l.dueDate.month, l.dueDate.day);
                            final days = todayMidnight.difference(dueMidnight).inDays;
                            if (days > maxDays) maxDays = days;
                          }
                        }
                        statusText = 'Overdue ($maxDays d)';
                      } else if (profile.activeLoansCount > 0) {
                        int minDays = 999999;
                        for (var l in profile.loans) {
                          if (!l.isPaid) {
                            final dueMidnight = DateTime(l.dueDate.year, l.dueDate.month, l.dueDate.day);
                            final days = dueMidnight.difference(todayMidnight).inDays;
                            if (days < minDays) minDays = days;
                          }
                        }
                        if (minDays == 0) {
                          statusText = 'Due Today';
                        } else {
                          statusText = '$minDays d left';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _showBorrowerDetails(context, profile),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getTrustColor(profile.trustRating).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${profile.trustRating.toStringAsFixed(0)}% Trust',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getTrustColor(profile.trustRating),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'NRC: ${profile.nrc} • Phone: ${profile.phone}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TOTAL BORROWED',
                                            style: TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'K${currencyFormat.format(profile.totalBorrowed)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'OUTSTANDING',
                                            style: TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'K${currencyFormat.format(profile.totalOutstanding)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: profile.totalOutstanding > 0 ? Colors.orange : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'STATUS',
                                            style: TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                isOverdue
                                                    ? Icons.warning_rounded
                                                    : (profile.activeLoansCount > 0
                                                        ? Icons.schedule_rounded
                                                        : Icons.check_circle_rounded),
                                                size: 14,
                                                color: isOverdue
                                                    ? Colors.red
                                                    : (profile.activeLoansCount > 0 ? Colors.blue : Colors.green),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isOverdue
                                                        ? Colors.red
                                                        : (profile.activeLoansCount > 0 ? Colors.blue : Colors.green),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
