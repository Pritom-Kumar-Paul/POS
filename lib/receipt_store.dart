import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repositories/receipt_repository.dart';

class ReceiptItem {
  final String productId;
  final String name;
  final int unitPrice;
  final int qty;
  const ReceiptItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.qty,
  });
  int get lineTotal => unitPrice * qty;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'unitPrice': unitPrice,
    'qty': qty,
  };

  factory ReceiptItem.fromMap(Map<String, dynamic> m) {
    return ReceiptItem(
      productId: (m['productId'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      unitPrice: (m['unitPrice'] as int?) ?? 0,
      qty: (m['qty'] as int?) ?? 0,
    );
  }
}

enum PaymentMethod { cash, card, mobile }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.mobile => 'Mobile',
  };
  static PaymentMethod from(String s) => s == 'Card'
      ? PaymentMethod.card
      : s == 'Mobile'
      ? PaymentMethod.mobile
      : PaymentMethod.cash;
}

class Receipt {
  final String id;
  final int number;
  final DateTime createdAt;
  final List<ReceiptItem> items;
  final int discount;
  final int tax;
  final String customerId;
  final PaymentMethod paymentMethod;

  const Receipt({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.items,
    this.discount = 0,
    this.tax = 0,
    this.customerId = "",
    this.paymentMethod = PaymentMethod.cash,
  });

  int get subtotal => items.fold(0, (s, it) => s + it.lineTotal);
  int get total => subtotal - discount + tax;

  static Map<String, dynamic> toFirestoreMap({
    required int number,
    required List<ReceiptItem> items,
    required int discount,
    required int tax,
    required String? customerId,
    required PaymentMethod paymentMethod,
  }) {
    final subtotal = items.fold(0, (s, it) => s + it.lineTotal);
    final total = subtotal - discount + tax;
    return {
      'number': number,
      'createdAt': FieldValue.serverTimestamp(),
      'items': items.map((e) => e.toMap()).toList(),
      'discount': discount,
      'tax': tax,
      'customerId': customerId ?? '',
      'paymentMethod': paymentMethod.label,
      'subtotal': subtotal,
      'total': total,
    };
  }

  factory Receipt.fromMap(String id, Map<String, dynamic> m) {
    final rawItems = (m['items'] as List? ?? const []);
    final items = rawItems
        .map((e) => ReceiptItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final ts = m['createdAt'];
    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is DateTime) {
      createdAt = ts;
    } else {
      createdAt = DateTime.tryParse('$ts') ?? DateTime.now();
    }
    return Receipt(
      id: id,
      number: (m['number'] as int?) ?? 0,
      createdAt: createdAt,
      items: items,
      discount: (m['discount'] as int?) ?? 0,
      tax: (m['tax'] as int?) ?? 0,
      customerId: (m['customerId'] as String?) ?? '',
      paymentMethod: PaymentMethodX.from(
        (m['paymentMethod'] as String?) ?? 'Cash',
      ),
    );
  }
}

class ReceiptStore extends ChangeNotifier {
  final List<Receipt> _receipts = [];
  List<Receipt> get receipts => List.unmodifiable(_receipts);

  StreamSubscription? _sub;
  ReceiptRepository? _repo;

  void bind(String orgId) {
    _repo = ReceiptRepository(orgId);
    _sub?.cancel();
    _sub = _repo!.streamAll().listen((list) {
      _receipts
        ..clear()
        ..addAll(list);
      notifyListeners();
    });
  }

  void unbind() {
    _sub?.cancel();
    _sub = null;
    _repo = null;
    _receipts.clear();
    notifyListeners();
  }

  List<Receipt> forCustomer(String customerId) =>
      _receipts.where((r) => r.customerId == customerId).toList();

  Future<Receipt> addReceipt({
    required List<ReceiptItem> items,
    int discount = 0,
    int tax = 0,
    String? customerId,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    return _repo!.createSale(
      items: items,
      discount: discount,
      tax: tax,
      customerId: customerId,
      paymentMethod: paymentMethod,
    );
  }
}

final receiptStore = ReceiptStore();
