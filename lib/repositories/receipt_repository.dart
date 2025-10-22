import 'package:cloud_firestore/cloud_firestore.dart';
import '../receipt_store.dart';
import 'firestore_paths.dart';

class ReceiptRepository {
  final String orgId;
  ReceiptRepository(this.orgId);

  Stream<List<Receipt>> streamAll() {
    return FF
        .receipts(orgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) {
          return qs.docs
              .map(
                (d) => Receipt.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<Receipt> createSale({
    required List<ReceiptItem> items,
    required int discount,
    required int tax,
    required String? customerId,
    required PaymentMethod paymentMethod,
  }) async {
    final db = FirebaseFirestore.instance;
    late Receipt created;

    await db.runTransaction((tx) async {
      // =============== READS FIRST ===============
      // a) Counter read
      final counterRef = FF.countersReceipts(orgId);
      final counterSnap = await tx.get(counterRef);
      final lastNo =
          (((counterSnap.data() as Map<String, dynamic>?)?['lastNumber']
                      as num?) ??
                  0)
              .toInt();
      final nextNo = lastNo + 1;

      // b) Read all product docs
      final productRefs = <DocumentReference>[];
      final productSnaps = <DocumentSnapshot>[];
      for (final it in items) {
        final pRef = FF.products(orgId).doc(it.productId);
        final pSnap = await tx.get(pRef);
        if (!pSnap.exists) {
          throw Exception('Product not found: ${it.productId}');
        }
        productRefs.add(pRef);
        productSnaps.add(pSnap);
      }

      // =============== VALIDATION ===============
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        final data = productSnaps[i].data() as Map<String, dynamic>;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        if (stock < it.qty) {
          final name = (data['name'] as String?) ?? it.productId;
          throw Exception('Not enough stock for "$name"');
        }
      }

      // Prepare receipt data
      final rRef = FF.receipts(orgId).doc();
      final map = Receipt.toFirestoreMap(
        number: nextNo,
        items: items,
        discount: discount,
        tax: tax,
        customerId: customerId,
        paymentMethod: paymentMethod,
      );

      // =============== WRITES AFTER ALL READS ===============
      // 1) Create receipt
      tx.set(rRef, map);

      // 2) Update products (stock, sold)
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        final data = productSnaps[i].data() as Map<String, dynamic>;
        final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
        final newStock = currentStock - it.qty;

        tx.update(productRefs[i], {
          'stock': newStock,
          'sold': FieldValue.increment(it.qty),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3) Update counter
      tx.set(counterRef, {'lastNumber': nextNo}, SetOptions(merge: true));

      // Local object to return
      created = Receipt(
        id: rRef.id,
        number: nextNo,
        createdAt: DateTime.now(), // Stream e server time asbe
        items: items,
        discount: discount,
        tax: tax,
        customerId: customerId ?? '',
        paymentMethod: paymentMethod,
      );
    });

    return created;
  }
}
