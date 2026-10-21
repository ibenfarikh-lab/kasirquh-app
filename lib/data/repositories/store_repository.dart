import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/firestore_service.dart';
import '../models/recipe.dart';

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

class StoreInfo {
  final String storeName;
  final String? address;
  final String? phone;
  final String? infoText;
  final String? runningText;
  final String openTime;
  final String closeTime;
  final int? modal;
  final int lowStockDefault;
  final int coinRate;
  final int coinRedeemLimit;
  final bool paketEnabled;
  final String? paketTitle;
  final String? paketSubtitle;
  final List<String> topProductIds;
  final String gatewayTitle1;
  final String gatewayCopy1;
  final String gatewayTitle2;
  final String gatewayCopy2;
  final String gatewayTitle3;
  final String gatewayCopy3;
  final String? promoTitle;
  final String? promoProductId;
  final String? promoCopy;
  final String? flashProductId;
  final int flashPrice;
  final String? flashRule;
  final DateTime? flashEndsAt;
  final List<String> pinnedChatIds;
  final List<String> inboxReadIds;
  final List<String> dashboardShortcutIds;
  final String? kabarStatus;
  final String? kabarMood;
  final Map<String, String> carouselSlots;
  final Map<String, HomeSectionConfig> homeSections;
  final AdminSoundSettings soundSettings;

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
    this.dashboardShortcutIds = const [],
    this.kabarStatus,
    this.kabarMood,
    this.carouselSlots = const {},
    this.homeSections = const {},
    this.soundSettings = const AdminSoundSettings(),
  });

  String slotText(String slot, String field, String def) {
    final v = (carouselSlots['$slot$field'] ?? '').trim();
    return v.isEmpty ? def : v;
  }

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
        dashboardShortcutIds: (m['dashboardShortcutIds'] as List?)
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
        soundSettings: AdminSoundSettings.fromMap(
          m['adminSoundSettings'] is Map
              ? Map<String, dynamic>.from(m['adminSoundSettings'] as Map)
              : null,
        ),
      );
}

class AdminSoundSettings {
  final String order;
  final String chat;
  final String promo;
  final bool vibrate;

  const AdminSoundSettings({
    this.order = 'system',
    this.chat = 'system',
    this.promo = 'system',
    this.vibrate = true,
  });

  factory AdminSoundSettings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const AdminSoundSettings();
    String suara(String k) {
      final v = (m[k] as String?) ?? 'system';
      return (v == 'mimi' || v == 'silent') ? v : 'system';
    }

    return AdminSoundSettings(
      order: suara('order'),
      chat: suara('chat'),
      promo: suara('promo'),
      vibrate: m['vibrate'] != false,
    );
  }
}

class Promo {
  final String id;
  final String title;
  final String? subtitle;
  final String copy;
  final String badge;
  final String? productId;
  final String? discountType;
  final int discountValue;
  final bool isActive;

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

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(storeRepositoryProvider).watchRecipes();
});

final myRecipesProvider =
    StreamProvider.family<List<Recipe>, String>((ref, uid) {
  return ref.watch(storeRepositoryProvider).watchMyRecipes(uid);
});

class CoinSettings {
  final bool enabled;
  final int coinRate;
  final int redeemLimit;
  final Map<String, bool> events;
  final Map<String, int> rewards;
  final int spendRule;
  final int spendReward;

  const CoinSettings({
    this.enabled = true,
    this.coinRate = 1,
    this.redeemLimit = 50,
    this.events = const {},
    this.rewards = const {},
    this.spendRule = 10000,
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
      spendRule: (m['coinSpendRule'] as num?)?.toInt() ?? 10000,
      spendReward: (m['coinSpendReward'] as num?)?.toInt() ?? 1,
    );
  }
}

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
