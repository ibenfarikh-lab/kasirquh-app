import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/notify.dart';
import '../../data/models/order.dart';
import '../../data/remote/messaging_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../l10n/strings_id.dart';

/// Bootstrap push & heads-up Mode Pelanggan (dipasang di CustomerShell).
/// - Minta izin notifikasi SEKALI per perangkat, didahului penjelasan jujur.
/// - Simpan token FCM ke customers/{uid}.fcmToken.
/// - Pantau status pesanan & chat toko → heads-up lokal saat berubah.
class PushBootstrap extends ConsumerStatefulWidget {
  final String uid;
  const PushBootstrap({super.key, required this.uid});

  @override
  ConsumerState<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends ConsumerState<PushBootstrap> {
  bool _jalan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_jalan || !mounted) return;
    _jalan = true;
    await Notify.init();
    final prefs = await SharedPreferences.getInstance();
    final sudahTanya =
        prefs.getBool('notif_izin_ditanya') ?? false;
    final messaging = ref.read(messagingServiceProvider);
    if (sudahTanya) {
      // Pernah ditanya: langsung ambil token tanpa dialog ulang.
      final token = await messaging.init(
        mintaIzinDulu: () async => true,
        onForeground: _bannerDalamAplikasi,
        simpanUlang: (t) =>
            messaging.simpanTokenMember(widget.uid, t),
      );
      if (token != null) {
        await messaging.simpanTokenMember(widget.uid, token);
      }
      return;
    }
    if (!mounted) return;
    final mau = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Strings.notifIzinJudul),
        content: const Text(Strings.notifIzinIsi),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.notifNanti),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Strings.notifAktifkan),
          ),
        ],
      ),
    );
    await prefs.setBool('notif_izin_ditanya', true);
    if (mau != true || !mounted) return;
    final token = await messaging.init(
      mintaIzinDulu: () async => true,
      onForeground: _bannerDalamAplikasi,
      simpanUlang: (t) => messaging.simpanTokenMember(widget.uid, t),
    );
    if (token != null) {
      await messaging.simpanTokenMember(widget.uid, token);
    }
  }

  void _bannerDalamAplikasi(String judul, String isi) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$judul\n$isi'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Widget tak kasat mata: pantau perubahan untuk heads-up.
    return const SizedBox.shrink();
  }
}

/// Pantau pesanan milikku: status berubah → heads-up lokal.
class OrderStatusWatcher extends ConsumerStatefulWidget {
  final String uid;
  const OrderStatusWatcher({super.key, required this.uid});

  @override
  ConsumerState<OrderStatusWatcher> createState() =>
      _OrderStatusWatcherState();
}

final _pesananSayaProvider =
    StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).watchMyOrders(uid);
});

class _OrderStatusWatcherState extends ConsumerState<OrderStatusWatcher> {
  Map<String, OrderStatus>? _terakhir;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _pesananSayaProvider(widget.uid),
      (prev, next) {
        final orders = next.valueOrNull;
        if (orders == null) return;
        final kini = {for (final o in orders) o.id: o.status};
        final lalu = _terakhir;
        _terakhir = kini;
        if (lalu == null) return; // snapshot pertama: jangan berisik
        for (final o in orders) {
          final sLama = lalu[o.id];
          if (sLama != null &&
              sLama != o.status &&
              o.status != OrderStatus.dibatalkan) {
            Notify.headsUp(
              Strings.statusPesananJudul,
              'Pesanan ${o.code}: ${orderStatusLabel(o.status)}',
            );
          }
        }
      },
    );
    return const SizedBox.shrink();
  }
}

/// Pantau chat toko: pesan baru dari admin → heads-up lokal.
class TokoUnreadWatcher extends ConsumerStatefulWidget {
  final String uid;
  const TokoUnreadWatcher({super.key, required this.uid});

  @override
  ConsumerState<TokoUnreadWatcher> createState() =>
      _TokoUnreadWatcherState();
}

class _TokoUnreadWatcherState extends ConsumerState<TokoUnreadWatcher> {
  int? _terakhir;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      myTokoThreadProvider(widget.uid),
      (prev, next) {
        final unread = next.valueOrNull?.unreadCustomer ?? 0;
        final lalu = _terakhir;
        _terakhir = unread;
        if (lalu == null) return;
        if (unread > lalu) {
          Notify.headsUp(
            Strings.chatBaruJudul,
            next.valueOrNull?.lastMessage ?? '',
          );
        }
      },
    );
    return const SizedBox.shrink();
  }
}
