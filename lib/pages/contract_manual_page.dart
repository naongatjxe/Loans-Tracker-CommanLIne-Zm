import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _phoneCtrl = TextEditingController();
  final _workplaceCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _lenderPhoneCtrl = TextEditingController();
  final _lenderAddressCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _companyNameCtrl.text = 'Your Company Name';
    _termsCtrl.text =
        'This Agreement constitutes the entire understanding between the parties.';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nrcCtrl.dispose();
    _phoneCtrl.dispose();
    _workplaceCtrl.dispose();
    _companyNameCtrl.dispose();
    _lenderPhoneCtrl.dispose();
    _lenderAddressCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Create a temporary borrower representation for contract preview
    final person = Person(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      nrc: _nrcCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      workplace: _workplaceCtrl.text.trim(),
      amount: 0.0,
      interestRate: 0.0,
      loanDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
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

              _buildModernTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                delay: 200,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _workplaceCtrl,
                label: 'Workplace / School',
                icon: Icons.business_rounded,
                delay: 250,
              ),
              const SizedBox(height: 32),

              // Lender Info Section
              _buildSectionHeader(
                icon: Icons.business_rounded,
                title: 'Lender Details',
                delay: 300,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _companyNameCtrl,
                label: 'Company / Lender Name',
                icon: Icons.business_center_rounded,
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                delay: 350,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _lenderPhoneCtrl,
                label: 'Lender Phone',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                delay: 400,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _lenderAddressCtrl,
                label: 'Lender Address',
                icon: Icons.location_on_rounded,
                maxLines: 2,
                delay: 450,
              ),
              const SizedBox(height: 32),

              // Contract Terms Section
              _buildSectionHeader(
                icon: Icons.description_rounded,
                title: 'Contract Terms',
                delay: 500,
              ),
              const SizedBox(height: 16),

              _buildModernTextField(
                controller: _termsCtrl,
                label: 'Terms and Conditions',
                icon: Icons.gavel_rounded,
                maxLines: 4,
                delay: 550,
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
}
