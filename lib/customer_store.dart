import 'package:flutter/foundation.dart';

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
}

class CustomerStore extends ChangeNotifier {
  final List<Customer> _items = [
    Customer(id: 'c_walkin', name: 'Walk-in', createdAt: DateTime.now()),
    Customer(
      id: 'c1',
      name: 'Rahim Uddin',
      phone: '01700000000',
      createdAt: DateTime.now(),
    ),
    Customer(
      id: 'c2',
      name: 'Karim Mia',
      phone: '01800000000',
      createdAt: DateTime.now(),
    ),
  ];

  List<Customer> get items => List.unmodifiable(_items);

  Customer? byId(String id) {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  String addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _items.add(
      Customer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return id;
  }

  void updateCustomer(Customer updated) {
    final i = _items.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      _items[i] = updated;
      notifyListeners();
    }
  }

  void removeCustomer(String id) {
    if (id == 'c_walkin') return;
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

final customerStore = CustomerStore();
