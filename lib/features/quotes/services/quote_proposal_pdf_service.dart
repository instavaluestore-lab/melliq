import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../company/models/company_context.dart';
import '../../customers/models/customer.dart';
import '../models/quote.dart';
import '../models/quote_line_item.dart';

class QuoteProposalPdfService {
  const QuoteProposalPdfService();

  Future<Uint8List> buildProposalPdf({
    required CompanyContext companyContext,
    required Quote quote,
    required List<QuoteLineItem> lineItems,
    required Customer customer,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(36)),
        build: (context) => [
          _buildHeader(companyContext: companyContext, quote: quote),
          pw.SizedBox(height: 20),
          _buildQuoteSummary(quote),
          pw.SizedBox(height: 18),
          _buildIncludedItems(lineItems),
          pw.SizedBox(height: 18),
          _buildTotals(quote),
          pw.SizedBox(height: 18),
          _buildTerms(),
          pw.SizedBox(height: 18),
          _buildAcceptance(),
          pw.SizedBox(height: 18),
          _buildFooter(companyContext),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader({
    required CompanyContext companyContext,
    required Quote quote,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              companyContext.displayBrandName,
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Project Proposal',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                quote.quoteNumber,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                quote.statusLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuoteSummary(Quote quote) {
    final validUntil = quote.validUntil;
    final notes = quote.notes?.trim();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            quote.title.isEmpty ? 'Untitled Quote' : quote.title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          if (validUntil != null) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Valid until ${_formatDate(validUntil)}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              notes,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
                lineSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCustomer(Customer customer) {
    final companyName = customer.companyName?.trim();
    final email = customer.email?.trim();
    final phone = customer.phone?.trim();
    final location = customer.location;

    final detailLines = <String>[
      if (companyName != null &&
          companyName.isNotEmpty &&
          companyName != customer.displayName)
        companyName,
      if (email != null && email.isNotEmpty) 'Email: $email',
      if (phone != null && phone.isNotEmpty) 'Phone: $phone',
      if (location != 'No location') 'Location: $location',
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Prepared For',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            customer.displayName,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          if (detailLines.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              detailLines.join('\n'),
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey800,
                lineSpacing: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildIncludedItems(List<QuoteLineItem> lineItems) {
    if (lineItems.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Included Items'),
          pw.SizedBox(height: 8),
          pw.Text(
            'No proposal line items have been added yet.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Included Items'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader('Item'),
                _tableHeader('Qty'),
                _tableHeader('Unit'),
              ],
            ),
            ...lineItems.map(
              (item) => pw.TableRow(
                children: [
                  _tableCell(
                    item.description != null &&
                            item.description!.trim().isNotEmpty
                        ? '${item.name}\n${item.description!.trim()}'
                        : item.name,
                  ),
                  _tableCell(item.quantity.toStringAsFixed(2)),
                  _tableCell(item.unit),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotals(Quote quote) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 260,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: [
            if (quote.discountAmount > 0)
              _totalRow('Discount', '-${_formatMoney(quote.discountAmount)}'),
            if (quote.taxAmount > 0)
              _totalRow('Tax', _formatMoney(quote.taxAmount)),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              'Customer Total',
              _formatMoney(quote.totalAmount),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTerms() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        border: pw.Border.all(color: PdfColors.amber200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Proposal Terms'),
          pw.SizedBox(height: 8),
          pw.Text(
            '• Pricing is based on the scope, quantities, and selections shown in this proposal.\n'
            '• Changes to size, site conditions, materials, engineering, permits, or installation requirements may require a revised proposal.\n'
            '• Work should not begin until the proposal is accepted and any required deposit or authorization is received.\n'
            '• Permit, engineering, utility, or access requirements may affect schedule and final scope.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey800,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAcceptance() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customer Acceptance'),
          pw.SizedBox(height: 22),
          _signatureLine('Customer Name'),
          pw.SizedBox(height: 18),
          _signatureLine('Customer Signature'),
          pw.SizedBox(height: 18),
          _signatureLine('Date'),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(CompanyContext companyContext) {
    final text = companyContext.poweredByLupinusBuild
        ? 'Prepared by ${companyContext.displayBrandName} • Powered by LupinusBuild'
        : 'Prepared by ${companyContext.displayBrandName}';

    return pw.Center(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey800,
          lineSpacing: 2,
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: isTotal ? 5 : 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isTotal ? 12 : 9,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 13 : 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _signatureLine(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 0.8, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final cents = parts[1];

    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final indexFromRight = whole.length - i;
      buffer.write(whole[i]);

      if (indexFromRight > 1 && indexFromRight % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}\$${buffer.toString()}.$cents';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$month/$day/$year';
  }
}
