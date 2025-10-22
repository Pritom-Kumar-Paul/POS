import '../customer_store.dart';
import 'firestore_paths.dart';

class CustomerRepository {
  final String orgId;
  CustomerRepository(this.orgId);

  Stream<List<Customer>> streamAll() {
    return FF
        .customers(orgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) {
          return qs.docs
              .map(
                (d) => Customer.fromMap(d.id, d.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  Future<String> addCustomer(Customer c) async {
    final ref = await FF.customers(orgId).add(c.toMap());
    return ref.id;
  }

  Future<void> updateCustomer(Customer c) async {
    await FF.customers(orgId).doc(c.id).update(c.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await FF.customers(orgId).doc(id).delete();
  }
}
