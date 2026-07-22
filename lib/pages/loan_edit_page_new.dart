import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';
import '../utils/loan_provider.dart';
import '../theme/theme_controller.dart';
import '../utils/formatters.dart';

class LoanEditPage extends StatefulWidget {
  final Person? person;
  final bool isReborrow;
  const LoanEditPage({super.key, this.person, this.isReborrow = false});

  @override
  State<LoanEditPage> createState() => _LoanEditPageState();
}

class _LoanEditPageState extends State<LoanEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nrcCtrl;
  late final TextEditingController _countryCodeCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _workplaceCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _interestCtrl;

  late DateTime _loanDate;
  late DateTime _dueDate;

  bool get isEditing => widget.person != null && !widget.isReborrow;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _nrcCtrl = TextEditingController(text: p?.nrc ?? '');

    String initialPhone = p?.phone ?? '';
    String parsedCode = '+260';
    if (initialPhone.startsWith('+')) {
      final match = RegExp(r'^\+\d{1,3}').firstMatch(initialPhone);
      if (match != null) {
        parsedCode = match.group(0)!;
        initialPhone = initialPhone.substring(parsedCode.length).trim();
      }
    }
    _countryCodeCtrl = TextEditingController(text: parsedCode);
    _phoneCtrl = TextEditingController(text: initialPhone);

    _workplaceCtrl = TextEditingController(text: p?.workplace ?? '');
    _amountCtrl = TextEditingController(
      text: p != null ? p.amount.toString() : '',
    );
    _interestCtrl = TextEditingController(
      text: p != null ? p.interestRate.toString() : '8',
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _loanDate = widget.isReborrow ? today : (p?.loanDate ?? today);
    _dueDate = widget.isReborrow
        ? today.add(const Duration(days: 7))
        : (p?.dueDate ?? today.add(const Duration(days: 7)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nrcCtrl.dispose();
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _workplaceCtrl.dispose();
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLoanDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _loanDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _loanDate = d;
        if (_dueDate.isBefore(_loanDate)) {
          _dueDate = _loanDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final initial = _dueDate.isBefore(_loanDate) ? _loanDate : _dueDate;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _loanDate,
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<LoanProvider>(context, listen: false);

    String code = _countryCodeCtrl.text.trim();
    if (code.isNotEmpty && !code.startsWith('+')) {
      code = '+$code';
    }

    String cleanPhone = _phoneCtrl.text.trim();
    if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    final fullPhone = '$code$cleanPhone';

    final person = Person(
      id: (widget.person != null && !widget.isReborrow)
          ? widget.person!.id
          : const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      nrc: _nrcCtrl.text.trim(),
      phone: fullPhone,
      workplace: _workplaceCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      interestRate: double.parse(_interestCtrl.text.trim()),
      loanDate: _loanDate,
      dueDate: _dueDate,
      isPaid: widget.isReborrow ? false : (widget.person?.isPaid ?? false),
      repayments: (widget.person != null && !widget.isReborrow)
          ? widget.person!.repayments
          : const [],
      interestType: 'flat',
      interestPeriod: 'none',
      lateFeeFlat: 0.0,
      lateFeeRate: 0.0,
    );

    if (isEditing) {
      provider.updatePerson(person);
    } else {
      provider.addPerson(person);
    }

    Navigator.pop(context, person);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Provider.of<ThemeController>(context, listen: false).accent;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Loan' : 'Add New Loan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: Text(isEditing ? 'UPDATE' : 'SAVE'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildSectionHeader(
                icon: Icons.person_rounded,
                title: 'Personal Information',
                delay: 0,
              ),
              const SizedBox(height: 16),

              // Personal Information Cards
              _buildModernTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                delay: 100,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _nrcCtrl,
                label: 'NRC Number',
                icon: Icons.badge_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  NrcInputFormatter(),
                ],
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  final regExp = RegExp(r'^\d{6}/\d{2}/\d$');
                  if (!regExp.hasMatch(text)) {
                    return 'Invalid NRC format (000000/00/0)';
                  }
                  return null;
                },
                delay: 150,
              ),
              const SizedBox(height: 16),

              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 105,
                            child: TextFormField(
                              controller: _countryCodeCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
                                FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
                              ],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Code',
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: accent,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone_rounded),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: accent,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _workplaceCtrl,
                label: 'Workplace',
                icon: Icons.business_rounded,
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                delay: 250,
              ),

              const SizedBox(height: 32),

              // Loan Information
              _buildSectionHeader(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Loan Details',
                delay: 300,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _amountCtrl,
                      label: 'Amount (K)',
                      icon: Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) {
                        if (v?.trim().isEmpty == true) return 'Required';
                        final amt = double.tryParse(v!);
                        if (amt == null || amt <= 0) return 'Invalid amount';
                        return null;
                      },
                      delay: 350,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _interestCtrl,
                      label: 'Interest Rate (%)',
                      icon: Icons.trending_up_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) {
                        if (v?.trim().isEmpty == true) return 'Required';
                        final rate = double.tryParse(v!);
                        if (rate == null || rate < 0) return 'Invalid rate';
                        return null;
                      },
                      delay: 400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date Section
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Loan Date',
                      date: _loanDate,
                      onTap: _pickLoanDate,
                      icon: Icons.calendar_today_rounded,
                      delay: 460,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Due Date',
                      date: _dueDate,
                      onTap: _pickDueDate,
                      icon: Icons.event_rounded,
                      delay: 480,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Row(
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
                    color: Provider.of<ThemeController>(
                      context,
                      listen: false,
                    ).accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                validator: validator,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeController>(
                        context,
                        listen: false,
                      ).accent,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              color: Provider.of<ThemeController>(
                                context,
                                listen: false,
                              ).accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
