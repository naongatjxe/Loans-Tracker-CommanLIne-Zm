import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../utils/loan_provider.dart';

class LoanDetailsPage extends StatelessWidget {
  final Person person;
  const LoanDetailsPage({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    // Amounts are shown using fixed per-term interest (principal + interestRate%)
    final total = person.calculateAmountDue(person.dueDate);
    final interest = total - person.amount;

    final daysLeft = person.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && !person.isPaid;

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details'), elevation: 2),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('NRC: ${person.nrc}'),
                  Text('Phone: ${person.phone}'),
                  Text('Workplace: ${person.workplace}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text(person.isPaid ? 'PAID' : 'ACTIVE')),
                      Text(
                        isOverdue ? 'OVERDUE' : '$daysLeft days remaining',
                        style: TextStyle(color: isOverdue ? Colors.red : null),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payment Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Principal', 'K${currencyFormat.format(person.amount)}'),
                  const SizedBox(height: 8),
                  _row('Interest', 'K${currencyFormat.format(interest)}'),
                  const Divider(height: 24),
                  _row(
                    'Total Due',
                    'K${currencyFormat.format(total)}',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Build buttons dynamically so spacing is only added when
              // adjacent buttons are visible.
              ..._buildActionButtons(context, person, isOverdue),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    Person person,
    bool isOverdue,
  ) {
    final actions = <Widget>[];

    // Contract (secondary)
    actions.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            // Close the details page then open the contract generator
            Navigator.pop(context);
            Navigator.pushNamed(context, '/contract', arguments: person);
          },
          icon: const Icon(Icons.description, size: 18),
          label: const Text('CONTRACT'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            minimumSize: const Size(0, 40),
          ),
        ),
      ),
    );

    // Mark Paid / Unpaid toggle. Show a single button that either marks the loan
    // as paid when it is currently unpaid or restores it to unpaid status when
    // it has been marked paid. The button colour changes to reflect the
    // action: green when marking paid and red when reverting to unpaid.
    actions.add(const SizedBox(width: 12));
    actions.add(
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            final provider = Provider.of<LoanProvider>(
              context,
              listen: false,
            );
            if (person.isPaid) {
              provider.markAsUnpaid(person.id);
            } else {
              provider.markAsPaid(person.id);
            }
            Navigator.pop(context);
          },
          icon: Icon(
            person.isPaid ? Icons.undo : Icons.check_circle,
            size: 18,
          ),
          label: Text(person.isPaid ? 'MARK UNPAID' : 'MARK PAID'),
          style: ElevatedButton.styleFrom(
            backgroundColor: person.isPaid
                ? const Color(0xFFB71C1C) // red for revert
                : const Color(0xFF2E7D32), // green for mark paid
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            minimumSize: const Size(0, 40),
          ),
        ),
      ),
    );

    return actions;
  }

  Widget _row(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? Colors.white : Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? const Color(0xFF64B5F6) : null,
          ),
        ),
      ],
    );
  }
}
