import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'receipt_store.dart';

Future<Uint8List> buildReceiptPdf(
  Receipt r, {
  String currency = '৳',
  String? customerName,
  String? customerPhone,
}) async {
  final pdf = pw.Document();

  String two(int n) => n.toString().padLeft(2, '0');
  final d = r.createdAt;
  final dateStr =
      '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Smart POS',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Receipt #${r.number}'),
            pw.Text('Date: $dateStr'),
            if (customerName != null && customerName.isNotEmpty)
              pw.Text(
                'Customer: $customerName${customerPhone != null ? ' • $customerPhone' : ''}',
              ),
            pw.Text('Payment: ${r.paymentMethod.label}'),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Table(
              border: pw.TableBorder.symmetric(
                inside: const pw.BorderSide(
                  width: 0.3,
                  color: PdfColors.grey600,
                ),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFEFEFEF),
                  ),
                  children: [
                    _cell('Item', bold: true),
                    _cell('Qty', bold: true, align: pw.TextAlign.right),
                    _cell('Unit', bold: true, align: pw.TextAlign.right),
                    _cell('Total', bold: true, align: pw.TextAlign.right),
                  ],
                ),
                ...r.items.map(
                  (it) => pw.TableRow(
                    children: [
                      _cell(it.name),
                      _cell('${it.qty}', align: pw.TextAlign.right),
                      _cell(
                        '$currency ${it.unitPrice}',
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        '$currency ${it.lineTotal}',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            _kv('Subtotal', '$currency ${r.subtotal}'),
            if (r.discount != 0) _kv('Discount', '- $currency ${r.discount}'),
            if (r.tax != 0) _kv('Tax', '+ $currency ${r.tax}'),
            pw.SizedBox(height: 6),
            _kv('Total', '$currency ${r.total}', bold: true),
            pw.SizedBox(height: 24),
            pw.Text('Thank you for your purchase!'),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _kv(String k, String v, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 12,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Row(
    children: [
      pw.Expanded(child: pw.Text(k, style: style)),
      pw.Text(v, style: style),
    ],
  );
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}
