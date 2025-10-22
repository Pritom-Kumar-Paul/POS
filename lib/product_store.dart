import 'dart:async';
import 'package:flutter/foundation.dart';
import 'repositories/product_repository.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final int stock;
  final int sold;
  final String category;
  final int lowStockThreshold;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sold,
    this.category = 'General',
    this.lowStockThreshold = 3,
  });

  Product copyWith({
    String? id,
    String? name,
    int? price,
    int? stock,
    int? sold,
    String? category,
    int? lowStockThreshold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      category: category ?? this.category,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  bool get isLowStock => stock <= lowStockThreshold;

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'stock': stock,
    'sold': sold,
    'category': category,
    'lowStockThreshold': lowStockThreshold,
    'createdAt': DateTime.now().toUtc(),
  };

  factory Product.fromMap(String id, Map<String, dynamic> m) {
    return Product(
      id: id,
      name: (m['name'] as String?) ?? '',
      price: (m['price'] as int?) ?? 0,
      stock: (m['stock'] as int?) ?? 0,
      sold: (m['sold'] as int?) ?? 0,
      category: (m['category'] as String?) ?? 'General',
      lowStockThreshold: (m['lowStockThreshold'] as int?) ?? 3,
    );
  }
}

class ProductStore extends ChangeNotifier {
  List<Product> _items = [];
  List<Product> get items => List.unmodifiable(_items);

  StreamSubscription? _sub;
  ProductRepository? _repo;

  void bind(String orgId) {
    _repo = ProductRepository(orgId);
    _sub?.cancel();
    _sub = _repo!.streamAll().listen((list) {
      _items = list;
      notifyListeners();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _repo = null;
    _items = [];
    notifyListeners();
  }

  void _ensureBound() {
    if (_repo == null) {
      throw StateError(
        'ProductStore is not bound. Call bind(orgId) before using the store.',
      );
    }
  }

  List<String> get categories => [
    'All',
    ...{for (final p in _items) p.category},
  ];

  Future<void> addProduct({
    required String name,
    required int price,
    required int stock,
    String category = 'General',
    int lowStockThreshold = 3,
  }) async {
    _ensureBound();
    await _repo!.addProduct(
      Product(
        id: 'new',
        name: name,
        price: price,
        stock: stock,
        sold: 0,
        category: category,
        lowStockThreshold: lowStockThreshold,
      ),
    );
  }

  Future<void> updateProduct(Product updated) async {
    _ensureBound();
    await _repo!.updateProduct(updated);
  }

  Future<void> removeProduct(String id) async {
    _ensureBound();
    await _repo!.deleteProduct(id);
  }

  Future<void> restock(String id, int delta) async {
    _ensureBound();
    await _repo!.restock(id, delta);
  }
}

final productStore = ProductStore();
