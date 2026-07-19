import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/contract.dart';
// Removed unused import of InterestCalculator; total due is now calculated
// using the same fixed per-term interest formula used in the Person model.

class PdfGenerator {
  static Future<Uint8List> generateContract(Contract contract) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'K ');

    // Calculate the total amount due using the fixed per-term interest
    // formula used in the app. This ensures the contract PDF reflects the
    // principal plus the agreed-term interest (amount * interestRate%). See
    // Person.totalForTerm() for the corresponding logic in the model layer.
    // Use the Person model's method so calculation logic is centralised
    final double termTotal = contract.person.calculateAmountDue(contract.person.dueDate);

    // Define styles
    final headerStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final sectionTitleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final labelStyle = pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey700);

    final valueStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );

    final highlightStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey900,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with border
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.blueGrey200,
                      width: 2,
                    ),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('LOAN AGREEMENT', style: headerStyle),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${dateFormat.format(contract.creationDate)}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Contract ID: ${contract.id.substring(0, 8)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Contract introduction
              pw.Paragraph(
                text:
                    'This loan agreement ("Agreement") is made and entered into on ${dateFormat.format(contract.creationDate)} between:',
                style: pw.TextStyle(fontSize: 11),
              ),

              pw.SizedBox(height: 15),

              // Parties section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PARTIES', style: sectionTitleStyle),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Lender
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('LENDER:', style: labelStyle),
                              pw.SizedBox(height: 4),
                              pw.Text(contract.companyName, style: valueStyle),
                              if (contract.lenderPhone.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Phone: ${contract.lenderPhone}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ],
                              if (contract.lenderAddress.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Address: ${contract.lenderAddress}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        // Borrower
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BORROWER:', style: labelStyle),
                              pw.SizedBox(height: 4),
                              pw.Text(contract.person.name, style: valueStyle),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'NRC: ${contract.person.nrc}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                'Phone: ${contract.person.phone}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                'Workplace: ${contract.person.workplace}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Loan details section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LOAN DETAILS', style: sectionTitleStyle),
                    pw.SizedBox(height: 10),
                    _buildDetailRow(
                      'Principal Amount:',
                      currencyFormat.format(contract.person.amount),
                    ),
                    _buildDetailRow(
                      'Interest Rate:',
                      '${contract.person.interestRate}%',
                    ),
                    _buildDetailRow(
                      'Loan Date:',
                      dateFormat.format(contract.person.loanDate),
                    ),
                    _buildDetailRow(
                      'Due Date:',
                      dateFormat.format(contract.person.dueDate),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    _buildDetailRow(
                      'Total Amount Payable:',
                      currencyFormat.format(termTotal),
                      labelStyle: highlightStyle,
                      valueStyle: highlightStyle,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Terms and conditions
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TERMS AND CONDITIONS', style: sectionTitleStyle),
                    pw.SizedBox(height: 10),
                    pw.Text(contract.terms, style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Signatures
              pw.Text('SIGNATURES', style: sectionTitleStyle),
              pw.SizedBox(height: 15),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 200,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.black),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Lender Signature',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        contract.companyName,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Date: _________________',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 200,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.black),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Borrower Signature',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        contract.person.name,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'NRC: ${contract.person.nrc}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Date: _________________',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'This is a legally binding document. Keep it for your records.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildDetailRow(
    String label,
    String value, {
    pw.TextStyle? labelStyle,
    pw.TextStyle? valueStyle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style:
                  labelStyle ??
                  pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style:
                  valueStyle ??
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
