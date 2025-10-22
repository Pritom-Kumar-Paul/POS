import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final int price; // ৳
  final int stock; // available units
  final int sold; // total sold

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
  });

  Product copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    int? sold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
    );
  }
}

class ProductStore extends ChangeNotifier {
  final List<Product> _items = [
    Product(id: 'p1', name: 'Cap', price: 300, stock: 10, sold: 0),
    Product(id: 'p2', name: 'Cap - Blue', price: 350, stock: 8, sold: 0),
    Product(id: 'p3', name: 'T-Shirt', price: 600, stock: 15, sold: 0),
  ];

  List<Product> get items => List.unmodifiable(_items);

  void addProduct({
    required String name,
    required int price,
    required int stock,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      Product(id: id, name: name, price: price, stock: stock, sold: 0),
    );
    notifyListeners();
  }

  void removeProduct(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Optional: add (+/-) stock
  void restock(String id, int delta) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final p = _items[i];
    final newStock = (p.stock + delta);
    if (newStock < 0) return;
    _items[i] = p.copyWith(stock: newStock);
    notifyListeners();
  }

  // Decrease stock, increase sold when a sale happens
  bool sell(String id, int qty) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return false;
    final p = _items[i];
    if (qty <= 0 || p.stock < qty) return false;
    _items[i] = p.copyWith(stock: p.stock - qty, sold: p.sold + qty);
    notifyListeners();
    return true;
  }
}

// Global singleton (do not duplicate this in other files)
final productStore = ProductStore();
