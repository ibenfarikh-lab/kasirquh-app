import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CRUD Firestore per koleksi — dipakai SyncEngine untuk push
/// dan layar admin untuk baca/tulis langsung saat online.
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

  /// Antrean persetujuan: pendaftar dengan approvalStatus=pending.
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingApprovals() =>
      customers.where('approvalStatus', isEqualTo: 'pending').snapshots();

  /// Setujui / tolak pendaftar (admin).
  Future<void> setApproval(String uid, bool approved) =>
      customers.doc(uid).update({
        'approvalStatus': approved ? 'approved' : 'rejected',
      });

  /// Ubah status pesanan (admin).
  Future<void> setOrderStatus(String orderId, String status) =>
      orders.doc(orderId).update({'status': status});

  /// Pengaturan toko (dokumen tunggal `main`).
  Future<Map<String, dynamic>?> storeSettings() async {
    final doc = await _db.collection('store_settings').doc('main').get();
    return doc.data();
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

/// Firestore yang nullable — null saat mode lokal (Firebase tak ter-init).
/// Repository Fase 2 memakai ini agar tetap aman offline.
final firestoreOrNullProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
});
