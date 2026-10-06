import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_note.dart';
import '../remote/firestore_service.dart';

/// Catatan toko (kasbon digital) — baca untuk pemilik.
/// Tulis hanya lewat AdminRepository (admin saja, sesuai rules).
class CustomerNoteRepository {
  final FirebaseFirestore? _db;

  CustomerNoteRepository(this._db);

  /// Catatan tokoku — hanya yang login sebagai pemilik yang bisa baca
  /// (rules: pemilik + admin).
  Stream<List<CustomerNote>> watchMyNotes(String uid) async* {
    final db = _db;
    if (db == null) {
      yield const [];
      return;
    }
    try {
      yield* db
          .collection('customer_notes')
          .where('customerId', isEqualTo: uid)
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => CustomerNote.fromDoc(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (_) {
      yield const [];
    }
  }
}

final customerNoteRepositoryProvider =
    Provider<CustomerNoteRepository>((ref) {
  return CustomerNoteRepository(ref.watch(firestoreOrNullProvider));
});

final myCustomerNotesProvider =
    StreamProvider.family<List<CustomerNote>, String>((ref, uid) {
  return ref.watch(customerNoteRepositoryProvider).watchMyNotes(uid);
});
