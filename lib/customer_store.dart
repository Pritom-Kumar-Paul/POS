import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repositories/customer_repository.dart';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'createdAt': DateTime.now().toUtc(),
  };

  factory Customer.fromMap(String id, Map<String, dynamic> m) {
    final ts = m['createdAt'];
    final createdAt = ts is Timestamp
        ? ts.toDate()
        : DateTime.tryParse('$ts') ?? DateTime.now();
    return Customer(
      id: id,
      name: (m['name'] as String?) ?? '',
      phone: m['phone'] as String?,
      email: m['email'] as String?,
      address: m['address'] as String?,
      createdAt: createdAt,
    );
  }
}

class CustomerStore extends ChangeNotifier {
  final List<Customer> _items = [];
  List<Customer> get items => List.unmodifiable(_items);

  StreamSubscription? _sub;
  CustomerRepository? _repo;

  void bind(String orgId) {
    _repo = CustomerRepository(orgId);
    _sub?.cancel();
    _sub = _repo!.streamAll().listen((list) {
      _items
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _repo = null;
    _items.clear();
    notifyListeners();
  }

  Customer? byId(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) async {
    return _repo!.addCustomer(
      Customer(
        id: 'new',
        name: name,
        phone: phone,
        email: email,
        address: address,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateCustomer(Customer updated) async =>
      _repo!.updateCustomer(updated);
  Future<void> removeCustomer(String id) async => _repo!.deleteCustomer(id);
}

final customerStore = CustomerStore();
