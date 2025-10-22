import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'product_store.dart';
import 'session.dart';
import 'utils/format.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final canManage = session.canManageCatalog;
    return AnimatedBuilder(
      animation: productStore,
      builder: (context, _) {
        final items = productStore.items.where((p) {
          final byCat =
              _selectedCategory == 'All' || p.category == _selectedCategory;
          final byQuery =
              _query.trim().isEmpty ||
              p.name.toLowerCase().contains(_query.trim().toLowerCase());
          return byCat && byQuery;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Products')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search products',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      items: productStore.categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No products yet'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = items[i];
                          final text =
                              '${fmtMoney(context, p.price)} • Stock: ${p.stock} • Sold: ${p.sold} • ${p.category}';
                          final low = p.isLowStock;
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              text,
                              style: TextStyle(color: low ? Colors.red : null),
                            ),
                            leading: low
                                ? const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canManage)
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _showEditProduct(context, p),
                                  ),
                                if (canManage)
                                  IconButton(
                                    tooltip: 'Restock +1',
                                    icon: const Icon(Icons.add_box_outlined),
                                    onPressed: () =>
                                        productStore.restock(p.id, 1),
                                  ),
                                if (canManage)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        productStore.removeProduct(p.id),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: session.canManageCatalog
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddProductSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                )
              : null,
        );
      },
    );
  }
}

void _showAddProductSheet(BuildContext context) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  final categoryCtrl = TextEditingController(text: 'General');
  final thresholdCtrl = TextEditingController(text: '3');
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
                  'Add product',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter product name';
                    if (v.trim().length < 2) return 'Too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price (৳)',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Initial stock',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter a valid stock';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: thresholdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock threshold',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      await productStore.addProduct(
                        name: nameCtrl.text.trim(),
                        price: int.parse(priceCtrl.text),
                        stock: int.parse(stockCtrl.text),
                        category: categoryCtrl.text.trim().isEmpty
                            ? 'General'
                            : categoryCtrl.text.trim(),
                        lowStockThreshold:
                            int.tryParse(thresholdCtrl.text) ?? 3,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product added')),
                        );
                      }
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

void _showEditProduct(BuildContext context, Product p) {
  final nameCtrl = TextEditingController(text: p.name);
  final priceCtrl = TextEditingController(text: '${p.price}');
  final categoryCtrl = TextEditingController(text: p.category);
  final thresholdCtrl = TextEditingController(text: '${p.lowStockThreshold}');
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
                  'Edit product',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price (৳)',
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Enter valid price'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: thresholdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock threshold',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final updated = p.copyWith(
                        name: nameCtrl.text.trim(),
                        price: int.parse(priceCtrl.text),
                        category: categoryCtrl.text.trim().isEmpty
                            ? 'General'
                            : categoryCtrl.text.trim(),
                        lowStockThreshold:
                            int.tryParse(thresholdCtrl.text) ??
                            p.lowStockThreshold,
                      );
                      await productStore.updateProduct(updated);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product updated')),
                        );
                      }
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
