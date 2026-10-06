import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/notify.dart';
import '../../data/models/order.dart';
import '../../data/remote/messaging_service.dart';
import '../../data/repositories/admin_repository.dart';
import '../../l10n/strings_id.dart';

/// Bootstrap push & heads-up Mode Admin (dipasang di AdminShell).
/// - Simpan token FCM ke store_settings/main.adminFcmTokens.
/// - Pesanan baru (status menunggu) → heads-up, sesuai pengaturan
///   notifikasi admin (notif_pesanan_baru).
class AdminPushBootstrap extends ConsumerStatefulWidget {
  const AdminPushBootstrap({super.key});

  @override
  ConsumerState<AdminPushBootstrap> createState() =>
      _AdminPushBootstrapState();
}

class _AdminPushBootstrapState extends ConsumerState<AdminPushBootstrap> {
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
    final messaging = ref.read(messagingServiceProvider);
    // Admin: izin diminta langsung oleh sistem (tanpa dialog penjelasan
    // tambahan — pengaturan notifikasi ada di Menu > Pengaturan).
    final token = await messaging.init(
      mintaIzinDulu: () async => true,
      onForeground: (judul, isi) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$judul\n$isi'),
            duration: const Duration(seconds: 5),
          ),
        );
      },
      simpanUlang: (t) => messaging.simpanTokenAdmin(t),
    );
    if (token != null) {
      await messaging.simpanTokenAdmin(token);
    }
  }

  @override
  Widget build(BuildContext context) =>
      const _PesananBaruWatcher();
}

/// Pantau pesanan menunggu: ada yang baru → heads-up (bila diizinkan).
class _PesananBaruWatcher extends ConsumerStatefulWidget {
  const _PesananBaruWatcher();

  @override
  ConsumerState<_PesananBaruWatcher> createState() =>
      _PesananBaruWatcherState();
}

final _semuaPesananProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllOrders();
});

class _PesananBaruWatcherState
    extends ConsumerState<_PesananBaruWatcher> {
  Set<String>? _terakhir;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      _semuaPesananProvider,
      (prev, next) async {
        final orders = next.valueOrNull;
        if (orders == null) return;
        final menunggu = {
          for (final o in orders)
            if (o.status == OrderStatus.menunggu) o.id
        };
        final lalu = _terakhir;
        _terakhir = menunggu;
        if (lalu == null) return; // snapshot pertama: jangan berisik
        final baru = menunggu.difference(lalu);
        if (baru.isEmpty) return;
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('notif_pesanan_baru') ?? true)) return;
        final contoh = orders.firstWhere(
          (o) => baru.contains(o.id),
          orElse: () => orders.first,
        );
        if (!mounted) return;
        Notify.headsUp(
          Strings.pesananBaruJudul,
          baru.length == 1
              ? 'Pesanan ${contoh.code} • ${contoh.customerName}'
              : '${baru.length} pesanan baru menunggu',
        );
      },
    );
    return const SizedBox.shrink();
  }
}
