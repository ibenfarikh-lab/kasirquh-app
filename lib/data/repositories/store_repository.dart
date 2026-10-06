import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/firestore_service.dart';

/// Info toko — mirror doc `store_settings/main`.
/// Nilai default jujur bila dokumen belum ada (bukan data siluman).
class StoreInfo {
  final String storeName;
  final String? address;
  final String? phone;
  final String? infoText;
  final String? runningText;
  final String openHour;
  final String closeHour;
  final int? modal; // sisa modal belanja (null = belum diisi)
  final int lowStockDefault;
  final int coinRate;

  const StoreInfo({
    this.storeName = 'Warunge Mimi',
    this.address,
    this.phone,
    this.infoText,
    this.runningText,
    this.openHour = '07:00',
    this.closeHour = '21:00',
    this.modal,
    this.lowStockDefault = 5,
    this.coinRate = 1,
  });

  /// Buka/tutup berdasar jam — hanya bila format jam valid.
  /// Bila tak bisa dihitung, kembalikan null (jangan tampilkan status palsu).
  bool? get isOpenNow {
    try {
      final now = DateTime.now();
      final o = openHour.split(':');
      final c = closeHour.split(':');
      final open = DateTime(
          now.year, now.month, now.day, int.parse(o[0]), int.parse(o[1]));
      var close = DateTime(
          now.year, now.month, now.day, int.parse(c[0]), int.parse(c[1]));
      if (close.isBefore(open)) close = close.add(const Duration(days: 1));
      return !now.isBefore(open) && now.isBefore(close);
    } catch (_) {
      return null;
    }
  }

  factory StoreInfo.fromMap(Map<String, dynamic> m) => StoreInfo(
        storeName: (m['storeName'] as String?) ?? 'Warunge Mimi',
        address: m['address'] as String?,
        phone: m['phone'] as String?,
        infoText: m['infoText'] as String?,
        runningText: m['runningText'] as String?,
        openHour: (m['openHour'] as String?) ?? '07:00',
        closeHour: (m['closeHour'] as String?) ?? '21:00',
        modal: (m['modal'] as num?)?.toInt(),
        lowStockDefault: (m['lowStockDefault'] as num?)?.toInt() ?? 5,
        coinRate: (m['coinRate'] as num?)?.toInt() ?? 1,
      );
}

/// Promo — mirror koleksi `promos`.
/// discountType: 'percent' | 'amount' | 'flash' (skema).
class Promo {
  final String id;
  final String title;
  final String? subtitle;
  final String? productId;
  final String? discountType;
  final int discountValue;
  final bool isActive;

  const Promo({
    required this.id,
    required this.title,
    this.subtitle,
    this.productId,
    this.discountType,
    this.discountValue = 0,
    this.isActive = true,
  });

  factory Promo.fromDoc(String id, Map<String, dynamic> m) {
    final now = DateTime.now();
    bool active = m['isActive'] != false;
    final start = (m['startsAt'] as Timestamp?)?.toDate();
    final end = (m['endsAt'] as Timestamp?)?.toDate();
    if (start != null && now.isBefore(start)) active = false;
    if (end != null && now.isAfter(end)) active = false;
    return Promo(
      id: id,
      title: (m['title'] as String?) ?? '',
      subtitle: m['subtitle'] as String?,
      productId: m['productId'] as String?,
      discountType: m['discountType'] as String?,
      discountValue: (m['discountValue'] as num?)?.toInt() ?? 0,
      isActive: active,
    );
  }

  /// Harga setelah promo untuk [hargaNormal] (integer Rp).
  /// 'percent' → potongan %; 'amount'/'flash' → potongan nominal.
  int hargaPromo(int hargaNormal) {
    switch (discountType) {
      case 'percent':
        if (discountValue <= 0) return hargaNormal;
        return (hargaNormal * (100 - discountValue.clamp(0, 100)) / 100)
            .round();
      case 'amount':
      case 'flash':
        return (hargaNormal - discountValue).clamp(0, hargaNormal);
      default:
        return hargaNormal;
    }
  }
}

class StoreRepository {
  final FirebaseFirestore? _db;

  StoreRepository(this._db);

  Stream<StoreInfo> watchStoreInfo() async* {
    if (_db == null) {
      yield const StoreInfo();
      return;
    }
    try {
      yield* _db
          .collection('store_settings')
          .doc('main')
          .snapshots()
          .map((doc) => doc.data() == null
              ? const StoreInfo()
              : StoreInfo.fromMap(doc.data()!));
    } catch (_) {
      yield const StoreInfo();
    }
  }

  Stream<List<Promo>> watchPromos() async* {
    if (_db == null) {
      yield const [];
      return;
    }
    try {
      yield* _db
          .collection('promos')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Promo.fromDoc(d.id, d.data()))
              .where((p) => p.isActive && p.title.isNotEmpty)
              .toList());
    } catch (_) {
      yield const [];
    }
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(firestoreOrNullProvider));
});

final storeInfoProvider = StreamProvider<StoreInfo>((ref) {
  return ref.watch(storeRepositoryProvider).watchStoreInfo();
});

final promosProvider = StreamProvider<List<Promo>>((ref) {
  return ref.watch(storeRepositoryProvider).watchPromos();
});
