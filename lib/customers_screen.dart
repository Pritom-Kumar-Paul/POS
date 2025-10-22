import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_store.dart' as cs;
import 'receipt_store.dart' as rs;
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([cs.customerStore, rs.receiptStore]),
      builder: (context, _) {
        final all = cs.customerStore.items;
        final q = _query.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all.where((c) {
                final inName = c.name.toLowerCase().contains(q);
                final inPhone = (c.phone ?? '').toLowerCase().contains(q);
                final inEmail = (c.email ?? '').toLowerCase().contains(q);
                return inName || inPhone || inEmail;
              }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Customers')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search name/phone/email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('No customers'))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = list[i];
                          final receipts = rs.receiptStore.forCustomer(c.id);
                          final spent = receipts.fold(0, (s, r) => s + r.total);
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
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showEditCustomer(context, c);
                                } else if (val == 'delete') {
                                  cs.customerStore.removeCustomer(c.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (c.id != 'c_walkin')
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                              ],
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '৳$spent',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    'Receipts: ${receipts.length}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerDetailScreen(customerId: c.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCustomerSheet(context),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add customer'),
          ),
        );
      },
    );
  }
}

void _showAddCustomerSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
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
                    if (v.trim().length < 2) return 'Too short';
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      cs.customerStore.addCustomer(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty
                            ? null
                            : emailCtrl.text.trim(),
                        address: addrCtrl.text.trim().isEmpty
                            ? null
                            : addrCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Customer added')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showEditCustomer(BuildContext context, cs.Customer c) {
  final nameCtrl = TextEditingController(text: c.name);
  final phoneCtrl = TextEditingController(text: c.phone ?? '');
  final emailCtrl = TextEditingController(text: c.email ?? '');
  final addrCtrl = TextEditingController(text: c.address ?? '');
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit customer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final updated = c.copyWith(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty
                            ? null
                            : emailCtrl.text.trim(),
                        address: addrCtrl.text.trim().isEmpty
                            ? null
                            : addrCtrl.text.trim(),
                      );
                      cs.customerStore.updateCustomer(updated);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Customer updated')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
