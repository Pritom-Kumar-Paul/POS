import 'package:flutter/material.dart';
import 'receipt_store.dart' as rs;
import 'product_store.dart' as ps;
import 'utils/format.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rs.receiptStore, ps.productStore]),
      builder: (context, _) {
        final receipts = rs.receiptStore.receipts;
        final now = DateTime.now();

        bool isSameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;

        int sumToday = receipts
            .where((r) => isSameDay(r.createdAt, now))
            .fold(0, (s, r) => s + r.total);
        int sum7 = receipts
            .where(
              (r) => r.createdAt.isAfter(now.subtract(const Duration(days: 7))),
            )
            .fold(0, (s, r) => s + r.total);
        int sum30 = receipts
            .where(
              (r) =>
                  r.createdAt.isAfter(now.subtract(const Duration(days: 30))),
            )
            .fold(0, (s, r) => s + r.total);

        final products = ps.productStore.items;
        final top = [...products]..sort((a, b) => b.sold.compareTo(a.sold));

        final lowStock = products.where((p) => p.isLowStock).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Reports')),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Today'),
                trailing: Text(fmtMoney(context, sumToday)),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Last 7 days'),
                trailing: Text(fmtMoney(context, sum7)),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Last 30 days'),
                trailing: Text(fmtMoney(context, sum30)),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Top products (by sold)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (top.isEmpty)
                const ListTile(title: Text('No products'))
              else
                ...top
                    .take(5)
                    .map(
                      (p) => ListTile(
                        title: Text(p.name),
                        subtitle: Text('Sold: ${p.sold}  •  Stock: ${p.stock}'),
                      ),
                    ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Low stock',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (lowStock.isEmpty)
                const ListTile(title: Text('No low stock'))
              else
                ...lowStock.map(
                  (p) => ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      'Stock: ${p.stock}  •  Threshold: ${p.lowStockThreshold}',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
