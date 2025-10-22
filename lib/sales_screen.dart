import 'package:flutter/material.dart';
import 'package:flutter_application_9/product_store.dart' as ps;
import 'package:flutter_application_9/receipt_store.dart' as rs;
import 'package:flutter_application_9/customer_store.dart' as cs;
import 'package:flutter_application_9/receipt_detail_screen.dart';
// Optional: jodi error hoy, fmtMoney bad diyeo chalano jabe
import 'package:flutter_application_9/utils/format.dart';

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

  int _discount = 0;
  int _tax = 0;
  rs.PaymentMethod _payment = rs.PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    ps.productStore.addListener(_onProductsChanged);

    debugPrint(
      'SalesScreen init: isBound=${ps.productStore != null} count=${ps.productStore.items.length}',
    );
  }

  @override
  void dispose() {
    ps.productStore.removeListener(_onProductsChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onProductsChanged() {
    setState(() {});
  }

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

  int get _subtotal {
    int sum = 0;
    for (final p in ps.productStore.items) {
      final qty = _cartQty[p.id] ?? 0;
      sum += p.price * qty;
    }
    return sum;
  }

  int get _total => _subtotal - _discount + _tax;

  Future<void> _checkout() async {
    if (_cartQty.isEmpty) return;

    for (final entry in _cartQty.entries) {
      final p = ps.productStore.items.firstWhere((e) => e.id == entry.key);
      if (entry.value > p.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for "${p.name}"')),
        );
        return;
      }
    }

    final items = _cartQty.entries.map((e) {
      final p = ps.productStore.items.firstWhere((x) => x.id == e.key);
      return rs.ReceiptItem(
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        qty: e.value,
      );
    }).toList();

    try {
      final receipt = await rs.receiptStore.addReceipt(
        items: items,
        discount: _discount,
        tax: _tax,
        customerId: _customerId,
        paymentMethod: _payment,
      );

      setState(() {
        _cartQty.clear();
        _searchCtrl.clear();
        _query = '';
        _discount = 0;
        _tax = 0;
        _payment = rs.PaymentMethod.cash;
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptDetailScreen(receipt: receipt),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    }
  }

  Future<void> _pickCustomer() async {
    final selected = await _showCustomerPicker(context);
    if (selected != null) {
      setState(() => _customerId = selected);
    }
  }

  Future<void> _setDiscountTax() async {
    final result = await _showDiscountTaxSheet(context, _discount, _tax);
    if (result != null) {
      setState(() {
        _discount = result.$1;
        _tax = result.$2;
      });
    }
  }

  Future<void> _pickPayment() async {
    final selected = await _showPaymentPicker(context, _payment);
    if (selected != null) {
      setState(() => _payment = selected);
    }
  }

  String _paymentLabel(rs.PaymentMethod m) {
    switch (m) {
      case rs.PaymentMethod.cash:
        return 'Cash';
      case rs.PaymentMethod.card:
        return 'Card';
      case rs.PaymentMethod.mobile:
        return 'Mobile';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'SalesScreen build: items=${ps.productStore.items.length}, filtered=${_filtered.length}, query="$_query"',
    );

    final selectedName = (() {
      if (_customerId == null) return 'Walk-in';
      try {
        return cs.customerStore.byId(_customerId!)?.name ?? 'Unknown';
      } catch (_) {
        return 'Walk-in';
      }
    })();

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      // bottomNavigationBar BADH diyেছি, niche Column e bottom panel add kora
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
          // Controls row: discount/tax + payment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _setDiscountTax,
                  icon: const Icon(Icons.percent),
                  label: Text(
                    'Discount/Tax (${_discount > 0 ? '-${fmtMoney(context, _discount)}' : '0'}'
                    '${_tax > 0 ? ' / +${fmtMoney(context, _tax)}' : ''})',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickPayment,
                  icon: const Icon(Icons.payments),
                  label: Text('Payment: ${_paymentLabel(_payment)}'),
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
          // Product list (safe + visible)
          Expanded(
            child: Container(
              color: Colors.yellow.shade50, // visibly show the list area
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No products to show'
                            : 'No results for "$_query"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final p = _filtered[i];
                        debugPrint('render item $i: ${p.name}');
                        final qty = _cartQty[p.id] ?? 0;
                        final canAdd = p.stock > 0 && qty < p.stock;

                        return Container(
                          color: i.isEven ? Colors.white : Colors.grey.shade100,
                          child: ListTile(
                            title: Text(
                              p.name,
                              style: const TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              '${fmtMoney(context, p.price)} • In stock: ${p.stock}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            trailing: qty == 0
                                ? ElevatedButton(
                                    onPressed: canAdd
                                        ? () => _addToCart(p)
                                        : null,
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
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: canAdd
                                            ? () => _addToCart(p)
                                            : null,
                                      ),
                                    ],
                                  ),
                            onTap: canAdd ? () => _addToCart(p) : null,
                          ),
                        );
                      },
                    ),
            ),
          ),
          // Bottom panel (instead of bottomNavigationBar)
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subtotal: ${fmtMoney(context, _subtotal)}'),
                      if (_discount > 0 || _tax > 0)
                        Text(
                          'Adj: -${fmtMoney(context, _discount)} / +${fmtMoney(context, _tax)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      Text(
                        'Total: ${fmtMoney(context, _total)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _cartQty.isEmpty ? null : _checkout,
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
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
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop(newId);
                              }
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter name';
                    }
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
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final id = await cs.customerStore.addCustomer(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop(id);
                      }
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

Future<(int, int)?> _showDiscountTaxSheet(
  BuildContext context,
  int initialDiscount,
  int initialTax,
) {
  final discountCtrl = TextEditingController(text: '$initialDiscount');
  final taxCtrl = TextEditingController(text: '$initialTax');
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<(int, int)>(
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
                'Discount & Tax',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: discountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Discount (৳)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: taxCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tax (৳)',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop((
                      int.parse(discountCtrl.text),
                      int.parse(taxCtrl.text),
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<rs.PaymentMethod?> _showPaymentPicker(
  BuildContext context,
  rs.PaymentMethod current,
) {
  return showModalBottomSheet<rs.PaymentMethod>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      Widget tile(String label, rs.PaymentMethod m, IconData icon) {
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: current == m
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () => Navigator.of(ctx).pop(m),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select payment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            tile('Cash', rs.PaymentMethod.cash, Icons.payments),
            tile('Card', rs.PaymentMethod.card, Icons.credit_card),
            tile('Mobile', rs.PaymentMethod.mobile, Icons.phone_iphone),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
