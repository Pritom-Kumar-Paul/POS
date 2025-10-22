import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'receipt_store.dart' as rs;
import 'customer_store.dart' as cs;
import 'receipt_pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'utils/format.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final rs.Receipt receipt;
  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    final customer = r.customerId.isEmpty
        ? null
        : cs.customerStore.byId(r.customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${r.number}'),
        actions: [
          IconButton(
            tooltip: 'Copy text',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _asText(r, context, customer)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied')));
              }
            },
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed: () async {
              final bytes = await buildReceiptPdf(
                r,
                currency: '৳',
                customerName: customer?.name,
                customerPhone: customer?.phone,
              );
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () async {
              final text = _asText(r, context, customer);
              await Share.share(text);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_headerLine(r), style: Theme.of(context).textTheme.titleMedium),
          if (customer != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Customer: ${customer.name}${customer.phone != null ? ' • ${customer.phone}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Payment: ${r.paymentMethod.label}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...r.items.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(it.name)),
                  Text(
                    '${it.qty} x ${fmtMoney(context, it.unitPrice)} = ${fmtMoney(context, it.lineTotal)}',
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          _kv(context, 'Subtotal', fmtMoney(context, r.subtotal)),
          if (r.discount != 0)
            _kv(context, 'Discount', '- ${fmtMoney(context, r.discount)}'),
          if (r.tax != 0) _kv(context, 'Tax', '+ ${fmtMoney(context, r.tax)}'),
          const SizedBox(height: 6),
          _kv(context, 'Total', fmtMoney(context, r.total), isBold: true),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool isBold = false}) {
    final style = isBold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(k, style: style)),
        Text(v, style: style),
      ],
    );
  }

  String _headerLine(rs.Receipt r) {
    final d = r.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final when =
        '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    return 'Date: $when • No: ${r.number}';
  }

  String _asText(rs.Receipt r, BuildContext context, cs.Customer? customer) {
    final buf = StringBuffer();
    buf.writeln('Receipt #${r.number}');
    buf.writeln(_headerLine(r));
    if (customer != null) {
      buf.writeln(
        'Customer: ${customer.name}${customer.phone != null ? ' • ${customer.phone}' : ''}',
      );
    }
    buf.writeln('Payment: ${r.paymentMethod.label}');
    for (final it in r.items) {
      buf.writeln(
        '${it.name}  ${it.qty} x ${fmtMoney(context, it.unitPrice)} = ${fmtMoney(context, it.lineTotal)}',
      );
    }
    buf.writeln('Subtotal: ${fmtMoney(context, r.subtotal)}');
    if (r.discount != 0)
      buf.writeln('Discount: -${fmtMoney(context, r.discount)}');
    if (r.tax != 0) buf.writeln('Tax: +${fmtMoney(context, r.tax)}');
    buf.writeln('TOTAL: ${fmtMoney(context, r.total)}');
    return buf.toString();
  }
}
