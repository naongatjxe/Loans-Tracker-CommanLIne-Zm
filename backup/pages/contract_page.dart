import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  ContractPageState createState() => ContractPageState();
}

class ContractPageState extends State<ContractPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _termsController = TextEditingController();
  Person? _person;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _companyNameController.text = 'Your Company Name';
    _companyPhoneController.text = '';
    _companyAddressController.text = '';
    // Terms are intentionally minimal; contract text is generated for clarity in the PDF
    _termsController.text =
        'This Agreement constitutes the entire understanding between the parties.';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the person object passed as an argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Person) {
      _person = args;
    } else {
      _person = null; // show contract tab landing (list + contract-only)
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
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
        final contract = Contract(
          id: const Uuid().v4(),
          person: _person!,
          companyName: _companyNameController.text.trim(),
          lenderPhone: _companyPhoneController.text.trim(),
          lenderAddress: _companyAddressController.text.trim(),
          creationDate: DateTime.now(),
          terms: _termsController.text.trim(),
        );

        // Save the contract
        await Provider.of<LoanProvider>(
          context,
          listen: false,
        ).addContract(contract);

        // Generate PDF
        final pdfBytes = await PdfGenerator.generateContract(contract);

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
    // If no person supplied, show list of borrowers and offer contract-only form
    if (_person == null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contracts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContractManualPage(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create Contract (manual)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Existing Borrowers',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<LoanProvider>(
                  builder: (context, provider, child) {
                    final people = provider.people;
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
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text(p.phone),
                          trailing: ElevatedButton(
                            child: const Text('Generate'),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/contract',
                              arguments: p,
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
        elevation: 2,
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
                        color: const Color(0xFF1E3A5F),
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
                        side: BorderSide(color: Colors.grey[800]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Color(0xFF64B5F6),
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
                                        : const Color(0xFF1E3A5F),
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
                              valueStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF64B5F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lender Information
                    const Row(
                      children: [
                        Icon(Icons.business, color: Color(0xFF64B5F6)),
                        SizedBox(width: 8),
                        Text(
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
                    TextFormField(
                      controller: _companyPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Lender Phone',
                        prefixIcon: const Icon(Icons.phone),
                        hintText: 'Enter lender phone number (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(66, 66, 66, 0.3),
                      ),
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
                          backgroundColor: const Color(0xFF1E3A5F),
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
