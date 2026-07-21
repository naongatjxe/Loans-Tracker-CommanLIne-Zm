import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/person.dart';
import '../utils/storage_helper.dart';
import '../models/contract.dart';
import '../utils/loan_provider.dart';
import '../utils/pdf_generator.dart';
import 'contract_manual_page.dart';
import 'signature_pad_page.dart';
import '../theme/theme_controller.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  ContractPageState createState() => ContractPageState();
}

class ContractPageState extends State<ContractPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyPhoneCodeController = TextEditingController(text: '+26');
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _termsController = TextEditingController();
  Person? _person;
  Contract? _existingContract;
  bool _isGenerating = false;

  // Digital signatures
  Uint8List? _lenderSignature;
  DateTime _signatureDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _companyNameController.text = 'Your Company Name';
    _companyPhoneCodeController.text = '+26';
    _companyPhoneController.text = '';
    _companyAddressController.text = '';
    // Terms are intentionally minimal; contract text is generated for clarity in the PDF
    _termsController.text =
        'This Agreement constitutes the entire understanding between the parties.';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the person or contract object passed as an argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is Person) {
        _person = args;
        _existingContract = null;
        _companyPhoneCodeController.text = '+26';
        _companyPhoneController.text = '';
        _signatureDate = DateTime.now();
      } else if (args is Contract) {
        _existingContract = args;
        _person = args.person;
        _companyNameController.text = args.companyName;
        
        String initialPhone = args.lenderPhone;
        String parsedCode = '+26';
        if (initialPhone.startsWith('+')) {
          final match = RegExp(r'^\+\d{1,2}').firstMatch(initialPhone);
          if (match != null) {
            parsedCode = match.group(0)!;
            initialPhone = initialPhone.substring(parsedCode.length).trim();
          }
        }
        _companyPhoneCodeController.text = parsedCode;
        _companyPhoneController.text = initialPhone;
        _companyAddressController.text = args.lenderAddress;
        _termsController.text = args.terms;
        _signatureDate = args.signatureDate ?? DateTime.now();
      }
    } else {
      _person = null;
      _existingContract = null;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyPhoneCodeController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _generateContract() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGenerating = true;
      });

      try {
        String code = _companyPhoneCodeController.text.trim();
        if (code.isNotEmpty && !code.startsWith('+')) {
          code = '+$code';
        }
        String cleanPhone = _companyPhoneController.text.trim();
        if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }
        final fullPhone = cleanPhone.isEmpty ? '' : '$code$cleanPhone';

        final contract = Contract(
          id: _existingContract?.id ?? const Uuid().v4(),
          person: _person!,
          companyName: _companyNameController.text.trim(),
          lenderPhone: fullPhone,
          lenderAddress: _companyAddressController.text.trim(),
          creationDate: _existingContract?.creationDate ?? DateTime.now(),
          terms: _termsController.text.trim(),
          signatureDate: _signatureDate,
        );

        // Save/Update the contract
        await Provider.of<LoanProvider>(
          context,
          listen: false,
        ).updateContract(contract);

        // Generate PDF
        final pdfBytes = await PdfGenerator.generateContract(
          contract,
          lenderSignature: _lenderSignature,
        );

        if (mounted) {
          setState(() {
            _isGenerating = false;
          });

          // Preview and print PDF
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Contract Preview'),
                  elevation: 0,
                ),
                body: PdfPreview(
                  build: (format) => pdfBytes,
                  allowPrinting: true,
                  // Sharing removed from preview per request; explicit save options provided
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName:
                      'contract_${(_person?.name ?? 'borrower').replaceAll(RegExp(r"[^A-Za-z0-9_]"), "_")}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating contract: $e')),
          );
        }
      }
    }
  }

  Future<void> _savePdf(dynamic pdfBytes, Contract contract) async {
    try {
      // Save into the application support directory. On Android this maps to
      // the app's internal files directory which the FileProvider <files-path>
      // entry allows sharing from.
      final directory = await getApplicationSupportDirectory();
      final safeName = contract.person.name.replaceAll(
        RegExp(r"[^A-Za-z0-9_]"),
        "_",
      );
      final fileName =
          'contract_${safeName}_${DateFormat('yyyyMMdd').format(contract.creationDate)}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 16),
                Expanded(child: Text('Contract saved to $filePath')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 16),
                Expanded(child: Text('Error saving contract: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Keep save helpers for future use; intentionally unused while the preview AppBar is hidden.
  // ignore: unused_element
  void _showSaveOptions(Uint8List pdfBytes, Contract contract) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save to Downloads'),
              onTap: () async {
                Navigator.pop(context);
                await _saveToDownloads(pdfBytes, contract);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Save to App files (internal)'),
              onTap: () async {
                Navigator.pop(context);
                await _savePdf(pdfBytes, contract);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDownloads(Uint8List pdfBytes, Contract contract) async {
    try {
      final safeName = contract.person.name.replaceAll(
        RegExp(r"[^A-Za-z0-9_]"),
        "_",
      );
      final fileName =
          'contract_${safeName}_${DateFormat('yyyyMMdd').format(contract.creationDate)}.pdf';

      // Ensure we have permission or a chosen folder
      final hasPermission = await StorageHelper.ensureStoragePermission(context);

      // Try path_provider's getDownloadsDirectory (desktop platforms)
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {
        downloadsDir = null;
      }

      // Fallback: Android external downloads directory
      if (downloadsDir == null) {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDirs != null && extDirs.isNotEmpty) {
          downloadsDir = extDirs.first;
        }
      }

      // If permission was not granted, let user pick a folder
      if (!hasPermission) {
        final chosen = await StorageHelper.promptForDirectory();
        if (chosen != null && chosen.isNotEmpty) {
          final file = File('$chosen/$fileName');
          await file.writeAsBytes(pdfBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contract saved to ${file.path}')),
            );
          }
          return;
        }

        // User didn't pick a folder; fall back to internal app files
        await _savePdf(pdfBytes, contract);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to App files instead.')),
          );
        }
        return;
      }

      if (downloadsDir == null) {
        // If we couldn't find a downloads directory, fall back to app support
        await _savePdf(pdfBytes, contract);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloads not available; saved to App files instead.')),
          );
        }
        return;
      }

      final file = File('${downloadsDir.path}/$fileName');
      try {
        await file.writeAsBytes(pdfBytes);
      } catch (e) {
        // If writing failed (permission or scoped storage), prompt for folder
        final chosen = await StorageHelper.promptForDirectory();
        if (chosen != null && chosen.isNotEmpty) {
          final fallback = File('$chosen/$fileName');
          await fallback.writeAsBytes(pdfBytes);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contract saved to ${fallback.path}')),
            );
          }
          return;
        }

        // Last resort
        await _savePdf(pdfBytes, contract);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to App files instead due to error: $e')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contract saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving to Downloads: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'K ');
    final themeCtrl = Provider.of<ThemeController>(context);
    final accent = themeCtrl.accent;
    // If no person supplied, show list of borrowers and offer contract-only form
    if (_person == null) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Contracts'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            bottom: TabBar(
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Generate'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Tab 1: Generate
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContractManualPage(),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Contract (manual)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Existing Borrowers',
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Consumer<LoanProvider>(
                        builder: (context, provider, child) {
                          final people = provider.people.where((p) => !p.isPaid).toList();
                          if (people.isEmpty) {
                            return Center(
                              child: Text(
                                'No borrowers available',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: people.length,
                            itemBuilder: (context, index) {
                              final p = people[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 1,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: accent.withValues(alpha: 0.1),
                                    child: Icon(Icons.person_outline_rounded, color: accent),
                                  ),
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(p.phone),
                                  trailing: ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/contract',
                                      arguments: p,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Generate'),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 2: History
              Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<LoanProvider>(
                  builder: (context, provider, child) {
                    final contracts = provider.contracts;
                    if (contracts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No generated contracts yet',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }
                    // Sort latest first
                    final sortedContracts = List<Contract>.from(contracts)
                      ..sort((a, b) => b.creationDate.compareTo(a.creationDate));

                    return ListView.builder(
                      itemCount: sortedContracts.length,
                      itemBuilder: (context, index) {
                        final contract = sortedContracts[index];
                        final p = contract.person;
                        final dateStr = DateFormat('MMM d, yyyy h:mm a').format(contract.creationDate);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: accent.withValues(alpha: 0.1),
                                  child: Icon(Icons.description_rounded, color: accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'K ${p.amount.toStringAsFixed(2)} • ${p.interestRate}% Interest',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                                  tooltip: 'Edit & View PDF',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/contract',
                                      arguments: contract,
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Contract?'),
                                        content: const Text(
                                          'Are you sure you want to delete this contract from history? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('CANCEL'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              provider.deleteContract(contract.id);
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Contract deleted successfully'),
                                                  backgroundColor: Colors.blue,
                                                ),
                                              );
                                            },
                                            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If a person was supplied, show the existing contract UI for that person
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Contract'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Contract Information'),
                  content: const Text(
                    'This page allows you to generate a loan contract with the borrower\'s details. '
                    'Fill in your company name and modify the terms if needed. '
                    'The generated PDF can be printed, shared, or saved to your device.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating contract...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contract Generator',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a legally binding loan agreement between you and ${_person!.name}',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Borrower Information Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: accent,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Borrower Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _person!.isPaid
                                        ? Colors.green
                                        : accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _person!.isPaid ? 'PAID' : 'ACTIVE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Full Name:', _person!.name),
                            _buildInfoRow('NRC Number:', _person!.nrc),
                            _buildInfoRow('Phone Number:', _person!.phone),
                            _buildInfoRow('Workplace:', _person!.workplace),
                            const Divider(height: 24),
                            _buildInfoRow(
                              'Principal Amount:',
                              currencyFormat.format(_person!.amount),
                              valueStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            _buildInfoRow(
                              'Interest Rate:',
                              '${_person!.interestRate}%',
                            ),
                            _buildInfoRow(
                              'Loan Date:',
                              DateFormat(
                                'dd MMMM yyyy',
                              ).format(_person!.loanDate),
                            ),
                            _buildInfoRow(
                              'Due Date:',
                              DateFormat(
                                'dd MMMM yyyy',
                              ).format(_person!.dueDate),
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              'Total Amount Payable:',
                              currencyFormat.format(
                                _person!.calculateAmountDue(_person!.dueDate),
                              ),
                              valueStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lender Information
                    Row(
                      children: [
                        Icon(Icons.business, color: accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Lender Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        labelText: 'Company/Lender Name',
                        prefixIcon: const Icon(Icons.business),
                        hintText: 'Enter your company or personal name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(66, 66, 66, 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 105,
                          child: TextFormField(
                            controller: _companyPhoneCodeController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(3),
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
                              fillColor: const Color.fromRGBO(66, 66, 66, 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _companyPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Lender Phone',
                              prefixIcon: const Icon(Icons.phone),
                              hintText: 'Phone number (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(66, 66, 66, 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Lender Address',
                        prefixIcon: const Icon(Icons.location_on),
                        hintText: 'Enter lender address (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(66, 66, 66, 0.3),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Editable Terms and Conditions for the PDF
                    TextFormField(
                      controller: _termsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Terms and Conditions (editable for PDF)',
                        alignLabelWithHint: true,
                        hintText:
                            'Edit the contract terms that will appear in the generated PDF',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Color.fromRGBO(66, 66, 66, 0.06),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Digital Signatures section
                    Row(
                      children: [
                        Icon(Icons.edit_document, color: accent),
                        const SizedBox(width: 8),
                        const Text(
                          'Digital Signatures',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 240,
                        child: _buildSignatureBox(
                          title: 'Lender Signature',
                          signature: _lenderSignature,
                          onTap: () async {
                            final bytes = await Navigator.push<Uint8List>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignaturePadPage(title: 'Lender Signature'),
                              ),
                            );
                            if (bytes != null) {
                              setState(() => _lenderSignature = bytes);
                            }
                          },
                          onClear: () {
                            setState(() => _lenderSignature = null);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _signatureDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setState(() => _signatureDate = d);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Signature Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMMM d, yyyy').format(_signatureDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Note: Terms are kept minimal in the UI; generated PDF contains the official language.
                    const SizedBox(height: 16),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _generateContract,
                        icon: const Icon(Icons.picture_as_pdf, size: 24),
                        label: const Text(
                          'GENERATE CONTRACT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSignatureBox({
    required String title,
    required Uint8List? signature,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Provider.of<ThemeController>(context, listen: false).accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: signature != null ? accent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: signature != null
                  ? Stack(
                      children: [
                        Center(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8),
                            child: Image.memory(signature, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onClear,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: accent.withValues(alpha: 0.7), size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to sign',
                            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[400])),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
