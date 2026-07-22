import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';
import '../utils/formatters.dart';
import '../theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ContractManualPage extends StatefulWidget {
  const ContractManualPage({super.key});

  @override
  State<ContractManualPage> createState() => _ContractManualPageState();
}

class _ContractManualPageState extends State<ContractManualPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nrcCtrl = TextEditingController();
  final _countryCodeCtrl = TextEditingController(text: '+260');
  final _phoneCtrl = TextEditingController();
  final _workplaceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController(text: '8');
  late DateTime _loanDate;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _loanDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nrcCtrl.dispose();
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    _workplaceCtrl.dispose();
    _amountCtrl.dispose();
    _interestRateCtrl.dispose();
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

    String cleanPhone = _phoneCtrl.text.trim();
    if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    String fullPhone = '';
    if (cleanPhone.isNotEmpty) {
      String code = _countryCodeCtrl.text.trim();
      if (code.isNotEmpty && !code.startsWith('+')) {
        code = '+$code';
      }
      fullPhone = '$code$cleanPhone';
    }

    // Create a temporary borrower representation for contract preview
    final person = Person(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      nrc: _nrcCtrl.text.trim(),
      phone: fullPhone,
      workplace: _workplaceCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text.trim()) ?? 0.0,
      interestRate: double.tryParse(_interestRateCtrl.text.trim()) ?? 0.0,
      loanDate: _loanDate,
      dueDate: _dueDate,
    );

    // Replace current route so going back from contract preview screen
    // returns to the contracts landing page.
    Navigator.pushReplacementNamed(
      context,
      '/contract',
      arguments: person,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Provider.of<ThemeController>(context, listen: false).accent;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Contract'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Next'),
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
              // Borrower Info Section
              _buildSectionHeader(
                icon: Icons.person_rounded,
                title: 'Borrower Details',
                delay: 0,
              ),
              const SizedBox(height: 16),

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
                label: 'Workplace / School',
                icon: Icons.business_rounded,
                delay: 250,
              ),
              const SizedBox(height: 32),

              // Loan Details Section
              _buildSectionHeader(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Loan Details',
                delay: 280,
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
                      delay: 300,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _interestRateCtrl,
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
                      delay: 320,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Loan Date',
                      date: _loanDate,
                      onTap: _pickLoanDate,
                      icon: Icons.calendar_today_rounded,
                      delay: 340,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Due Date',
                      date: _dueDate,
                      onTap: _pickDueDate,
                      icon: Icons.event_rounded,
                      delay: 360,
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
    int maxLines = 1,
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
                maxLines: maxLines,
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
