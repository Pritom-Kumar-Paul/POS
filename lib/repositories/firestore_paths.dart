import 'package:cloud_firestore/cloud_firestore.dart';

class FF {
  static final db = FirebaseFirestore.instance;

  static DocumentReference userDoc(String uid) =>
      db.collection('users').doc(uid);
  static DocumentReference orgDoc(String orgId) =>
      db.collection('orgs').doc(orgId);

  static CollectionReference products(String orgId) =>
      orgDoc(orgId).collection('products');
  static CollectionReference customers(String orgId) =>
      orgDoc(orgId).collection('customers');
  static CollectionReference receipts(String orgId) =>
      orgDoc(orgId).collection('receipts');
  static DocumentReference countersReceipts(String orgId) =>
      orgDoc(orgId).collection('counters').doc('receipts');
}
