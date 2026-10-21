import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  CollectionReference<Map<String, dynamic>> get products =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get promos =>
      _db.collection('promos');
  CollectionReference<Map<String, dynamic>> get orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get customers =>
      _db.collection('customers');
  CollectionReference<Map<String, dynamic>> get journal =>
      _db.collection('journal');
  CollectionReference<Map<String, dynamic>> get coinLedger =>
      _db.collection('coin_ledger');

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingApprovals() =>
      customers.where('approvalStatus', isEqualTo: 'pending').snapshots();

  Future<void> setApproval(String uid, bool approved) =>
      customers.doc(uid).update({
        'approvalStatus': approved ? 'approved' : 'rejected',
      });

  Future<void> setOrderStatus(String orderId, String status) =>
      orders.doc(orderId).update({'status': status});

  Future<Map<String, dynamic>?> storeSettings() async {
    final doc = await _db.collection('store_settings').doc('main').get();
    return doc.data();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final firestoreOrNullProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
});
