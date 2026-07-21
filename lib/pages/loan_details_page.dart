import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../models/repayment.dart';
import '../utils/loan_provider.dart';
import '../theme/theme_controller.dart';
import 'loan_edit_page_new.dart';

class LoanDetailsPage extends StatelessWidget {
  final Person person;
  const LoanDetailsPage({super.key, required this.person});

  void _showRepaymentDialog(BuildContext context, Person livePerson, LoanProvider provider) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final accent = Provider.of<ThemeController>(context, listen: false).accent;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Record Repayment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Styled Amount input
                        const Text(
                          'Amount to Record',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'K ',
                            prefixStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: accent.withValues(alpha: 0.6),
                            ),
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final amt = double.tryParse(v);
                            if (amt == null || amt <= 0) return 'Invalid amount';
                            return null;
                          },
                        ),
                        Divider(color: accent.withValues(alpha: 0.3), thickness: 1.5, indent: 50, endIndent: 50),
                        const SizedBox(height: 12),

                        // Notes input
                        TextFormField(
                          controller: notesCtrl,
                          decoration: InputDecoration(
                            labelText: 'Notes / Reference',
                            prefixIcon: Icon(Icons.description_rounded, color: accent.withValues(alpha: 0.7)),
                            hintText: 'e.g. Bank Transfer, Cash',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accent, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final amt = double.parse(amountCtrl.text.trim());
                            final notes = notesCtrl.text.trim();

                            final newRep = Repayment(
                              id: const Uuid().v4(),
                              amount: amt,
                              date: DateTime.now(),
                              notes: notes.isEmpty ? 'Repayment' : notes,
                            );

                            final updatedRepayments = List<Repayment>.from(livePerson.repayments)..add(newRep);
                            final outstanding = livePerson.copyWith(repayments: updatedRepayments).calculateAmountDue(DateTime.now());
                            final isPaidNow = outstanding <= 0;

                            final updatedPerson = livePerson.copyWith(
                              repayments: updatedRepayments,
                              isPaid: isPaidNow,
                            );

                            await provider.updatePerson(updatedPerson);
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Repayment of K$amt recorded successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Text(
                            'Record',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteRepayment(BuildContext context, Person livePerson, Repayment repayment, LoanProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade600,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Repayment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete this payment record? This will adjust the outstanding balance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final updatedRepayments = List<Repayment>.from(livePerson.repayments)..removeWhere((r) => r.id == repayment.id);
                          final outstanding = livePerson.copyWith(repayments: updatedRepayments).calculateAmountDue(DateTime.now());
                          final isPaidNow = outstanding <= 0;

                          final updatedPerson = livePerson.copyWith(
                            repayments: updatedRepayments,
                            isPaid: isPaidNow,
                          );

                          await provider.updatePerson(updatedPerson);
                          Navigator.pop(context);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlertSheet(BuildContext context, Person livePerson) {
    final now = DateTime.now();
    final amountDue = livePerson.calculateAmountDue(now);
    final formattedAmount = NumberFormat('#,##0.00').format(amountDue);
    final formattedDueDate = DateFormat('MMM d, yyyy').format(livePerson.dueDate);

    final cleanPhone = livePerson.phone.replaceAll(RegExp(r'[^0-9+]'), '');

    final message = "Hi ${livePerson.name}, this is a friendly reminder that your loan balance of K$formattedAmount "
        "is due on $formattedDueDate. Please settle at your earliest convenience. Thank you!";

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),
                const Text(
                  'Alert Borrower',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a friendly repayment reminder to ${livePerson.name}.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.blue.shade50.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.message_rounded, color: Colors.white),
                    ),
                    title: const Text('Send SMS', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Send reminder via system SMS client'),
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse("sms:$cleanPhone?body=${Uri.encodeComponent(message)}");
                      try {
                        await launchUrl(uri);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch SMS application.')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.green.shade50.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                    ),
                    title: const Text('Send WhatsApp', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Send reminder direct via WhatsApp'),
                    onTap: () async {
                      Navigator.pop(context);
                      final waUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
                      try {
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch WhatsApp application.')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');
    final provider = Provider.of<LoanProvider>(context);

    // Retrieve live updated version from provider
    final livePerson = provider.people.firstWhere(
      (p) => p.id == person.id,
      orElse: () => person,
    );

    final now = DateTime.now();
    final amountDue = livePerson.calculateAmountDue(now);
    final interest = livePerson.calculateStandardInterest(now);
    final lateFees = livePerson.calculateLateFees(now);
    final repaymentsPaid = livePerson.getPaidRepaymentsSum();

    final dueMidnight = DateTime(livePerson.dueDate.year, livePerson.dueDate.month, livePerson.dueDate.day);
    final nowMidnight = DateTime(now.year, now.month, now.day);
    final daysLeft = dueMidnight.difference(nowMidnight).inDays;
    final isOverdue = daysLeft < 0 && !livePerson.isPaid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
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
                    livePerson.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('NRC: ${livePerson.nrc}'),
                  Text('Phone: ${livePerson.phone}'),
                  Text('Workplace: ${livePerson.workplace}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(label: Text(livePerson.isPaid ? 'PAID' : 'ACTIVE')),
                      Text(
                        isOverdue
                            ? 'OVERDUE'
                            : (daysLeft == 0
                                ? 'Due Today'
                                : (daysLeft > 0 ? '$daysLeft days remaining' : 'Paid')),
                        style: TextStyle(color: isOverdue ? Colors.red : null),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
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
                  _row(context, 'Principal', 'K${currencyFormat.format(livePerson.amount)}'),
                  const SizedBox(height: 8),
                  _row(context, 'Interest (${livePerson.interestType.toUpperCase()})', 'K${currencyFormat.format(interest)}'),
                  if (lateFees > 0) ...[
                    const SizedBox(height: 8),
                    _row(context, 'Late Fees / Penalties', 'K${currencyFormat.format(lateFees)}', isHighlighted: true),
                  ],
                  if (repaymentsPaid > 0) ...[
                    const SizedBox(height: 8),
                    _row(context, 'Repayments Paid', '-K${currencyFormat.format(repaymentsPaid)}'),
                  ],
                  const Divider(height: 24),
                  _row(
                    context,
                    'Outstanding Balance',
                    'K${currencyFormat.format(amountDue)}',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
          if (livePerson.repayments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Repayment Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: livePerson.repayments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rep = livePerson.repayments[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.payment_rounded, color: Colors.green),
                    title: Text('K${currencyFormat.format(rep.amount)}'),
                    subtitle: Text('${rep.notes} • ${DateFormat('MMM d, yyyy').format(rep.date)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      onPressed: () => _deleteRepayment(context, livePerson, rep, provider),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildActionGrid(context, livePerson, provider),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, Person livePerson, LoanProvider provider) {
    final accent = Provider.of<ThemeController>(context).accent;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (livePerson.isPaid) {
                    provider.markAsUnpaid(livePerson.id);
                  } else {
                    provider.markAsPaid(livePerson.id);
                  }
                },
                icon: Icon(
                  livePerson.isPaid ? Icons.undo : Icons.check_circle,
                  size: 18,
                ),
                label: Text(livePerson.isPaid ? 'MARK UNPAID' : 'MARK PAID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: livePerson.isPaid
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
             Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (livePerson.isPaid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanEditPage(
                          person: livePerson,
                          isReborrow: true,
                        ),
                      ),
                    );
                  } else {
                    _showRepaymentDialog(context, livePerson, provider);
                  }
                },
                icon: Icon(
                  livePerson.isPaid ? Icons.cached_rounded : Icons.add_card_rounded,
                  size: 18,
                ),
                label: Text(livePerson.isPaid ? 'REBORROW' : 'REPAYMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/contract', arguments: livePerson);
                },
                icon: const Icon(Icons.description, size: 18),
                label: const Text('CONTRACT'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: accent),
                  foregroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAlertSheet(context, livePerson),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('ALERT'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: accent),
                  foregroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlighted
                ? colorScheme.primary
                : onSurface.withValues(alpha: 0.6),
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? colorScheme.primary : onSurface,
          ),
        ),
      ],
    );
  }
}
