import 'package:flutter/material.dart';
import 'product_store.dart' as ps;
import 'receipt_store.dart' as rs;
import 'receipt_detail_screen.dart';
import 'customer_store.dart' as cs;

class SalesScreen extends StatefulWidget {
  final String? initialCustomerId;
  const SalesScreen({super.key, this.initialCustomerId});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _searchCtrl = TextEditingController();
  final Map<String, int> _cartQty = {};
  String _query = '';
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    ps.productStore.addListener(_onProductsChanged);
  }

  @override
  void dispose() {
    ps.productStore.removeListener(_onProductsChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onProductsChanged() => setState(() {});

  List<ps.Product> get _filtered {
    final q = _query.trim().toLowerCase();
    final all = ps.productStore.items;
    if (q.isEmpty) return all;
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  void _addToCart(ps.Product p) {
    final current = _cartQty[p.id] ?? 0;
    if (current >= p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${p.stock} in stock for "${p.name}"')),
      );
      return;
    }
    setState(() => _cartQty[p.id] = current + 1);
  }

  int get _total {
    int sum = 0;
    for (final p in ps.productStore.items) {
      final qty = _cartQty[p.id] ?? 0;
      sum += p.price * qty;
    }
    return sum;
  }

  Future<void> _checkout() async {
    if (_cartQty.isEmpty) return;

    // validate stock
    for (final entry in _cartQty.entries) {
      final p = ps.productStore.items.firstWhere((e) => e.id == entry.key);
      if (entry.value > p.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for "${p.name}"')),
        );
        return;
      }
    }

    // Build receipt items
    final items = _cartQty.entries.map((e) {
      final p = ps.productStore.items.firstWhere((x) => x.id == e.key);
      return rs.ReceiptItem(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        qty: e.value,
      );
    }).toList();

    // Apply sale to inventory
    for (final entry in _cartQty.entries) {
      final ok = ps.productStore.sell(entry.key, entry.value);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale failed. Please try again.')),
        );
        return;
      }
    }

    // Save receipt with customerId (may be null = Walk-in)
    final receipt = rs.receiptStore.addReceipt(
      items: items,
      customerId: _customerId,
    );

    setState(() {
      _cartQty.clear();
      _searchCtrl.clear();
      _query = '';
    });

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptDetailScreen(receipt: receipt)),
    );
  }

  Future<void> _pickCustomer() async {
    final selected = await _showCustomerPicker(context);
    if (selected != null) {
      setState(() => _customerId = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = (_customerId != null)
        ? (cs.customerStore.byId(_customerId!)?.name ?? 'Unknown')
        : 'Walk-in';

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          // Customer selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(child: Text('Customer: $selectedName')),
                TextButton(
                  onPressed: _pickCustomer,
                  child: Text(_customerId == null ? 'Select' : 'Change'),
                ),
                if (_customerId != null)
                  TextButton(
                    onPressed: () => setState(() => _customerId = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products (e.g. cap)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _filtered[i];
                final qty = _cartQty[p.id] ?? 0;
                final canAdd = p.stock > 0 && qty < p.stock;

                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('৳${p.price} • In stock: ${p.stock}'),
                  trailing: qty == 0
                      ? ElevatedButton(
                          onPressed: canAdd ? () => _addToCart(p) : null,
                          child: const Text('Add'),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  final now = qty - 1;
                                  if (now <= 0) {
                                    _cartQty.remove(p.id);
                                  } else {
                                    _cartQty[p.id] = now;
                                  }
                                });
                              },
                            ),
                            Text('$qty'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: canAdd ? () => _addToCart(p) : null,
                            ),
                          ],
                        ),
                  onTap: canAdd ? () => _addToCart(p) : null,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ৳$_total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton(
                onPressed: _cartQty.isEmpty ? null : _checkout,
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet picker: returns selected customerId or null (Walk-in)
  Future<String?> _showCustomerPicker(BuildContext context) async {
    final searchCtrl = TextEditingController();
    String q = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final all = cs.customerStore.items;
            final list = (q.trim().isEmpty)
                ? all
                : all.where((c) {
                    final s = q.toLowerCase();
                    return c.name.toLowerCase().contains(s) ||
                        (c.phone ?? '').toLowerCase().contains(s) ||
                        (c.email ?? '').toLowerCase().contains(s);
                  }).toList();
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search customers',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setSheetState(() => q = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                            [
                              if (c.phone != null && c.phone!.isNotEmpty)
                                '📞 ${c.phone}',
                              if (c.email != null && c.email!.isNotEmpty)
                                '✉️ ${c.email}',
                            ].join('   '),
                          ),
                          onTap: () => Navigator.of(ctx).pop(c.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Use Walk-in'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Add customer'),
                          onPressed: () async {
                            final newId = await _quickAddCustomer(ctx);
                            if (newId != null) {
                              if (ctx.mounted) Navigator.of(ctx).pop(newId);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _quickAddCustomer(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add customer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final id = cs.customerStore.addCustomer(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop(id);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
