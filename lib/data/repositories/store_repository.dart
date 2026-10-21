import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/firestore_service.dart';
import '../models/recipe.dart';

/// Konfigurasi visibilitas & urutan satu section Beranda — mirror
/// `store_settings/main.homeSections.{restock,popular,recipe}` (PWA).
class HomeSectionConfig {
  final bool show;
  final int order;

  const HomeSectionConfig({this.show = true, this.order = 1});

  factory HomeSectionConfig.fromMap(Map<String, dynamic>? m) =>
      HomeSectionConfig(
        show: m?['show'] != false,
        order: (m?['order'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {'show': show, 'order': order};
}

/// Info toko — mirror doc `store_settings/main`.
/// Nilai default jujur bila dokumen belum ada (bukan data siluman).
class StoreInfo {
  final String storeName;
  final String? address;
  final String? phone;
  final String? infoText;
  final String? runningText;
  final String openTime;
  final String closeTime;
  final int? modal; // sisa modal belanja (null = belum diisi)
  final int lowStockDefault;
  final int coinRate;
  // Batas penukaran koin: persen maks. dari total belanja (0 = belum diatur).
  final int coinRedeemLimit;
  // Paket Tanggal Muda (section Beranda, diatur warung).
  final bool paketEnabled;
  final String? paketTitle;
  final String? paketSubtitle;
  // Agregat produk laris (dihitung admin dari pesanan, bukan data siluman).
  final List<String> topProductIds;
  // --- Pusat Kendali Beranda (mirror PWA homeControlModal) ---
  // Slide gateway (headline max 64, subheadline max 110).
  final String gatewayTitle1;
  final String gatewayCopy1;
  final String gatewayTitle2;
  final String gatewayCopy2;
  final String gatewayTitle3;
  final String gatewayCopy3;
  // Promo pilihan.
  final String? promoTitle;
  final String? promoProductId;
  final String? promoCopy;
  // Promo kilat.
  final String? flashProductId;
  final int flashPrice;
  final String? flashRule;
  final DateTime? flashEndsAt;
  // Thread Chat Toko yang di-pin admin (urutan = prioritas, P1-2).
  final List<String> pinnedChatIds;
  // ID item Inbox yang sudah dibaca — persisten lintas perangkat
  // di store_settings (P1-8, skema Web `inboxReadIds`).
  final List<String> inboxReadIds;
  // Kabar warung (override; kosong = otomatis).
  final String? kabarStatus;
  final String? kabarMood;
  // Slot carousel promo (5 slot tetap ala PWA: flash/coin/recipe/budget/hajatan).
  // Key: `{slot}Title`, `{slot}Copy`, `{slot}Badge` — kosong = pakai default PWA.
  final Map<String, String> carouselSlots;
  // Visibilitas & urutan section Beranda (restock/popular/recipe).
  final Map<String, HomeSectionConfig> homeSections;

  const StoreInfo({
    this.storeName = 'Warunge Mimi',
    this.address,
    this.phone,
    this.infoText,
    this.runningText,
    this.openTime = '07:00',
    this.closeTime = '21:00',
    this.modal,
    this.lowStockDefault = 5,
    this.coinRate = 1,
    this.coinRedeemLimit = 0,
    this.paketEnabled = false,
    this.paketTitle,
    this.paketSubtitle,
    this.topProductIds = const [],
    this.gatewayTitle1 = 'Hemat belanja, senang di rumah',
    this.gatewayCopy1 =
        'Promo pilihan Warunge Mimi untuk kebutuhan harian keluarga.',
    this.gatewayTitle2 = 'Sembako lengkap, tinggal pilih',
    this.gatewayCopy2 =
        'Minyak, gula, mi, dan kebutuhan dapur siap untuk stok rumah.',
    this.gatewayTitle3 = 'Jajan dan minuman favoritmu',
    this.gatewayCopy3 =
        'Camilan renyah dan minuman segar untuk teman santai kapan saja.',
    this.promoTitle,
    this.promoProductId,
    this.promoCopy,
    this.flashProductId,
    this.flashPrice = 0,
    this.flashRule,
    this.flashEndsAt,
    this.pinnedChatIds = const [],
    this.inboxReadIds = const [],
    this.kabarStatus,
    this.kabarMood,
    this.carouselSlots = const {},
    this.homeSections = const {},
  });

  /// Teks slot carousel promo ala PWA: `{slot}Title/Copy/Badge`.
  /// Kosong → pakai [def].
  String slotText(String slot, String field, String def) {
    final v = (carouselSlots['$slot$field'] ?? '').trim();
    return v.isEmpty ? def : v;
  }

  /// Buka/tutup berdasar jam — hanya bila format jam valid.
  /// Bila tak bisa dihitung, kembalikan null (jangan tampilkan status palsu).
  bool? get isOpenNow {
    try {
      final now = DateTime.now();
      final o = openTime.split(':');
      final c = closeTime.split(':');
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
        // Jam operasional mengikuti field Web `openTime`/`closeTime`
        // (P0-5). Fallback ke field lama Native agar jam yang pernah
        // diatur dari Native tidak hilang sebelum ditulis ulang.
        openTime: (m['openTime'] as String?) ??
            (m['openHour'] as String?) ??
            '07:00',
        closeTime: (m['closeTime'] as String?) ??
            (m['closeHour'] as String?) ??
            '21:00',
        modal: (m['modal'] as num?)?.toInt(),
        lowStockDefault: (m['lowStockDefault'] as num?)?.toInt() ?? 5,
        coinRate: (m['coinRate'] as num?)?.toInt() ?? 1,
        coinRedeemLimit:
            (m['coinRedeemLimit'] as num?)?.toInt() ?? 0,
        paketEnabled: m['paketEnabled'] == true,
        paketTitle: m['paketTitle'] as String?,
        paketSubtitle: m['paketSubtitle'] as String?,
        topProductIds: (m['topProductIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        gatewayTitle1: (m['gatewayTitle1'] as String?) ??
            'Hemat belanja, senang di rumah',
        gatewayCopy1: (m['gatewayCopy1'] as String?) ??
            'Promo pilihan Warunge Mimi untuk kebutuhan harian keluarga.',
        gatewayTitle2: (m['gatewayTitle2'] as String?) ??
            'Sembako lengkap, tinggal pilih',
        gatewayCopy2: (m['gatewayCopy2'] as String?) ??
            'Minyak, gula, mi, dan kebutuhan dapur siap untuk stok rumah.',
        gatewayTitle3: (m['gatewayTitle3'] as String?) ??
            'Jajan dan minuman favoritmu',
        gatewayCopy3: (m['gatewayCopy3'] as String?) ??
            'Camilan renyah dan minuman segar untuk teman santai kapan saja.',
        promoTitle: m['promoTitle'] as String?,
        promoProductId: m['promoProductId'] as String?,
        promoCopy: m['promoCopy'] as String?,
        flashProductId: m['flashProductId'] as String?,
        flashPrice: (m['flashPrice'] as num?)?.toInt() ?? 0,
        flashRule: m['flashRule'] as String?,
        flashEndsAt: (m['flashEndsAt'] as Timestamp?)?.toDate(),
        pinnedChatIds: (m['pinnedChatIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        inboxReadIds: (m['inboxReadIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
        kabarStatus: m['kabarStatus'] as String?,
        kabarMood: m['kabarMood'] as String?,
        carouselSlots: ((m['carouselSlots'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v ?? '').toString()),
        ),
        homeSections: ((m['homeSections'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
            k.toString(),
            HomeSectionConfig.fromMap(
                v is Map<String, dynamic> ? v : null),
          ),
        ),
      );
}

/// Promo — mirror koleksi `promos`.
/// Skema tulis Web (P1-10): banner sederhana {title, copy, badge,
/// isActive} — TANPA diskon harga. Field diskon warisan Native
/// (productId/discountType/discountValue/startsAt/endsAt) dipertahankan
/// hanya untuk membaca data lama; promo Web tidak memilikinya sehingga
/// tidak pernah memicu potongan harga.
class Promo {
  final String id;
  final String title;
  final String? subtitle;
  /// Teks promo gaya Web (`copy`); fallback ke `subtitle` lama.
  final String copy;
  /// Lencana promo gaya Web (`badge`, bawaan Web 'PROMO').
  final String badge;
  final String? productId;
  final String? discountType;
  final int discountValue;
  final bool isActive;

  /// Batas akhir promo (untuk countdown Promo Kilat). Null = akhir hari ini.
  final DateTime? endsAt;

  const Promo({
    required this.id,
    required this.title,
    this.subtitle,
    this.copy = '',
    this.badge = 'PROMO',
    this.productId,
    this.discountType,
    this.discountValue = 0,
    this.isActive = true,
    this.endsAt,
  });

  factory Promo.fromDoc(String id, Map<String, dynamic> m) {
    final now = DateTime.now();
    bool active = m['isActive'] != false;
    final start = (m['startsAt'] as Timestamp?)?.toDate();
    final end = (m['endsAt'] as Timestamp?)?.toDate();
    if (start != null && now.isBefore(start)) active = false;
    if (end != null && now.isAfter(end)) active = false;
    final badgeMentah = (m['badge'] as String?)?.trim() ?? '';
    return Promo(
      id: id,
      title: (m['title'] as String?) ?? '',
      subtitle: m['subtitle'] as String?,
      copy: (m['copy'] as String?) ?? (m['subtitle'] as String?) ?? '',
      badge: badgeMentah.isEmpty ? 'PROMO' : badgeMentah,
      productId: m['productId'] as String?,
      discountType: m['discountType'] as String?,
      discountValue: (m['discountValue'] as num?)?.toInt() ?? 0,
      isActive: active,
      endsAt: (m['endsAt'] as Timestamp?)?.toDate(),
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

  /// Langganan resep publik — selaras PWA `watchRecipes()`.
  /// Koleksi `recipes` boleh dibaca publik (rule: allow read: if true),
  /// jadi langganan ini permanen dan tidak ikut terputus saat ganti mode.
  Stream<List<Recipe>> watchRecipes() async* {
    if (_db == null) {
      yield const [];
      return;
    }
    try {
      yield* _db
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Recipe.fromDoc(d.id, d.data()))
              .where((r) => r.nama.isNotEmpty)
              .toList());
    } catch (_) {
      yield const [];
    }
  }

  /// Langganan "Ide Masakku" pelanggan — subkoleksi `customers/{uid}/my_recipes`.
  /// Selaras PWA (2026-10-16).
  Stream<List<Recipe>> watchMyRecipes(String uid) async* {
    if (_db == null || uid.isEmpty) {
      yield const [];
      return;
    }
    try {
      yield* _db
          .collection('customers')
          .doc(uid)
          .collection('my_recipes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Recipe.fromDoc(d.id, d.data()))
              .where((r) => r.nama.isNotEmpty)
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

/// Daftar resep Ide Masak Warga (publik, permanen) — selaras PWA.
final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(storeRepositoryProvider).watchRecipes();
});

/// Daftar "Ide Masakku" milik pelanggan yang login — selaras PWA.
final myRecipesProvider =
    StreamProvider.family<List<Recipe>, String>((ref, uid) {
  return ref.watch(storeRepositoryProvider).watchMyRecipes(uid);
});

/// Pengaturan Koin Warga — mirror `store_settings/main` (ikut PWA).
class CoinSettings {
  final bool enabled;
  final int coinRate; // Rp per koin
  final int redeemLimit; // % maksimal dari total
  final Map<String, bool> events; // checkin, mission, guess, spend
  final Map<String, int> rewards; // checkin, mission, guess
  final int spendRule; // Rp per bonus (default PWA: 100)
  final int spendReward; // koin per rule

  const CoinSettings({
    this.enabled = true,
    this.coinRate = 1,
    this.redeemLimit = 50,
    this.events = const {},
    this.rewards = const {},
    this.spendRule = 100,
    this.spendReward = 1,
  });

  factory CoinSettings.fromMap(Map<String, dynamic> m) {
    final events = (m['coinEvents'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), v == true),
    );
    final rewards = (m['coinRewards'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
    return CoinSettings(
      enabled: m['coinProgramEnabled'] != false,
      coinRate: (m['coinRate'] as num?)?.toInt() ?? 1,
      redeemLimit: (m['coinRedeemLimit'] as num?)?.toInt() ?? 50,
      events: events,
      rewards: rewards,
      spendRule: (m['coinSpendRule'] as num?)?.toInt() ?? 100,
      spendReward: (m['coinSpendReward'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Stream pengaturan koin (ikut PWA).
final coinSettingsProvider = StreamProvider<CoinSettings>((ref) {
  final db = ref.watch(firestoreOrNullProvider);
  if (db == null) {
    return Stream.value(const CoinSettings());
  }
  return db
      .collection('store_settings')
      .doc('main')
      .snapshots()
      .map((doc) => doc.data() == null
          ? const CoinSettings()
          : CoinSettings.fromMap(doc.data()!));
});
