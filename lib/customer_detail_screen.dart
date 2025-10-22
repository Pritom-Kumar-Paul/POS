import 'package:flutter/material.dart';
import 'customer_store.dart' as cs;
import 'receipt_store.dart' as rs;
import 'receipt_detail_screen.dart';
import 'sales_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([cs.customerStore, rs.receiptStore]),
      builder: (context, _) {
        final c = cs.customerStore.byId(customerId);
        if (c == null) {
          return const Scaffold(
            body: Center(child: Text('Customer not found')),
          );
        }
        final receipts = rs.receiptStore.forCustomer(customerId);
        final spent = receipts.fold(0, (s, r) => s + r.total);

        return Scaffold(
          appBar: AppBar(
            title: Text(c.name),
            actions: [
              IconButton(
                tooltip: 'New sale',
                icon: const Icon(Icons.point_of_sale),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SalesScreen(initialCustomerId: c.id),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(
                  c.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.phone != null && c.phone!.isNotEmpty)
                      Text('📞 ${c.phone}'),
                    if (c.email != null && c.email!.isNotEmpty)
                      Text('✉️ ${c.email}'),
                    if (c.address != null && c.address!.isNotEmpty)
                      Text('🏠 ${c.address}'),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Lifetime spent'),
                trailing: Text(
                  '৳$spent',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                title: const Text('Receipts'),
                trailing: Text('${receipts.length}'),
              ),
              const Divider(),
              if (receipts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No receipts yet'),
                )
              else
                ...receipts.map((r) {
                  final dt = _fmt(r.createdAt);
                  final itemsCount = r.items.fold<int>(
                    0,
                    (s, it) => s + it.qty,
                  );
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Receipt #${r.number} • ৳${r.total}'),
                    subtitle: Text('$dt • Items: $itemsCount'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReceiptDetailScreen(receipt: r),
                        ),
                      );
                    },
                  );
                }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
