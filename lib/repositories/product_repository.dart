import 'package:cloud_firestore/cloud_firestore.dart';
import '../product_store.dart';
import 'firestore_paths.dart';

class ProductRepository {
  final String orgId;
  ProductRepository(this.orgId);

  Stream<List<Product>> streamAll() {
    return FF.products(orgId).orderBy('name').snapshots().map((qs) {
      return qs.docs
          .map((d) => Product.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addProduct(Product p) async {
    await FF.products(orgId).add(p.toMap());
  }

  Future<void> updateProduct(Product p) async {
    await FF.products(orgId).doc(p.id).update(p.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await FF.products(orgId).doc(id).delete();
  }

  Future<void> restock(String id, int delta) async {
    await FF.products(orgId).doc(id).update({
      'stock': FieldValue.increment(delta),
    });
  }
}
