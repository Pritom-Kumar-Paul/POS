import 'package:flutter/foundation.dart';

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
}

class Receipt {
  final String id;
  final int number;
  final DateTime createdAt;
  final List<ReceiptItem> items;
  final int discount;
  final int tax;
  final String customerId;

  const Receipt({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.items,
    this.discount = 0,
    this.tax = 0,
    this.customerId = "",
  });

  int get subtotal => items.fold(0, (s, it) => s + it.lineTotal);
  int get total => subtotal - discount + tax;
}

class ReceiptStore extends ChangeNotifier {
  final List<Receipt> _receipts = [];
  int _counter = 0;

  List<Receipt> get receipts => List.unmodifiable(_receipts);

  List<Receipt> forCustomer(String customerId) {
    return _receipts.where((r) => r.customerId == customerId).toList();
  }

  Receipt addReceipt({
    required List<ReceiptItem> items,
    int discount = 0,
    int tax = 0,
    String? customerId,
  }) {
    _counter += 1;
    final r = Receipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: _counter,
      createdAt: DateTime.now(),
      items: items,
      discount: discount,
      tax: tax,
      customerId: customerId ?? "",
    );
    _receipts.insert(0, r);
    notifyListeners();
    return r;
  }
}

final receiptStore = ReceiptStore();
