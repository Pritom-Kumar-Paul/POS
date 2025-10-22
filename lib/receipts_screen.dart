import 'package:flutter/material.dart';
import 'receipt_store.dart' as rs;
import 'receipt_detail_screen.dart';
import 'utils/format.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rs.receiptStore,
      builder: (context, _) {
        final list = rs.receiptStore.receipts;
        return Scaffold(
          appBar: AppBar(title: const Text('Receipts')),
          body: list.isEmpty
              ? const Center(child: Text('No receipts yet'))
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    final dt = fmtDate(r.createdAt);
                    final itemsCount = r.items.fold<int>(
                      0,
                      (s, it) => s + it.qty,
                    );
                    return ListTile(
                      title: Text(
                        'Receipt #${r.number} • ${fmtMoney(context, r.total)}',
                      ),
                      subtitle: Text(
                        '$dt • Items: $itemsCount • ${r.paymentMethod.label}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReceiptDetailScreen(receipt: r),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
