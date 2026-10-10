import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/theme_picker.dart';
import '../../../data/models/order.dart';
import '../../../data/models/customer_note.dart';
import '../../../data/remote/auth_service.dart';
import '../../../data/repositories/customer_note_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../l10n/strings_id.dart';
import '../../admin/admin_shell.dart';
import '../../auth/biometric_credential_service.dart';
import '../../auth/login_cepat_toggle.dart';
import '../../gateway/gateway_screen.dart';
import '../session.dart';
import 'coin_history_page.dart';
import 'misi_koin_page.dart';

/// Tab Akun — bergembok untuk tamu.
/// Member: data akun + koin + riwayat pesanan + Keluar.
class AccountTab extends ConsumerWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final isGuest = session == null || session.isGuest;
    final uid = isGuest ? null : session.user!.uid;
    final nama = displayName(session ?? const Session.guest());
    final inisial =
        nama.isNotEmpty ? nama[0].toUpperCase() : 'M';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        // Header ala PWA.
        Text(
          'Milikmu',
          style: TextStyle(
            color: context.teksRedup,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'Akun',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        // Kartu profil: avatar | info | chip koin.
        AppCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    inisial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pelanggan Warunge Mimi',
                      style: TextStyle(
                          color: context.teksRedup, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Chip koin ala PWA.
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: uid == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CoinHistoryPage(uid: uid),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0C8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isGuest
                        ? 'Belum ada koin'
                        : '${NumberFormat('#,###', 'id_ID').format(session.coins)} koin',
                    style: const TextStyle(
                      color: Color(0xFF8B5910),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Kartu Bonus Harian ala PWA.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2DF),
            border: Border.all(color: const Color(0xFFECCB9E)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  color: AppColors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonus harian',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Bonus masuk setelah pelanggan login.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'Belum diambil',
                style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Grid menu 2 kolom ala PWA.
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _menuTile(
              context,
              icon: Icons.delivery_dining_outlined,
              title: 'Pesanan aktif',
              subtitle: 'Belum ada pesanan aktif',
              onTap: uid == null
                  ? null
                  : () => _bukaPesanan(context, ref, uid),
            ),
            _menuTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Pesanan',
              subtitle: 'Belum ada riwayat',
              onTap: uid == null
                  ? null
                  : () => _bukaRiwayat(context, ref, uid),
            ),
            _menuTile(
              context,
              icon: Icons.note_alt_outlined,
              title: 'Catatan & Tagihan',
              subtitle: 'Belum ada catatan',
              onTap: uid == null
                  ? null
                  : () => _bukaCatatan(context, ref, uid),
            ),
            _menuTile(
              context,
              icon: Icons.emoji_events_outlined,
              title: 'Misi koin',
              subtitle: 'Selesaikan tantangan dan ambil bonus',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MisiKoinPage(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Daftar pengaturan ala PWA.
        _settingTile(
          context,
          icon: Icons.settings_outlined,
          title: 'Identitas & tampilan',
          onTap: () => _bukaPengaturan(context, ref),
        ),
        const SizedBox(height: 8),
        _settingTile(
          context,
          icon: Icons.badge_outlined,
          title: 'Simpan kartu aplikasi',
          onTap: () => _bukaKartu(context),
        ),
        const SizedBox(height: 8),
        _settingTile(
          context,
          icon: Icons.logout,
          title: 'Keluar dari akun',
          danger: true,
          onTap: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 20),
        // Login cepat sidik jari (fitur native, dipertahankan).
        LoginCepatToggle(
          accountId: 'customer',
          verifySignIn: (email, password) async {
            final auth = ref.read(authServiceProvider);
            if (auth == null) throw Exception('no auth');
            await auth.signIn(email: email, password: password);
          },
        ),
        const SizedBox(height: 12),
        AppButton(
          label: Strings.gantiKeModeAdmin,
          kind: AppButtonKind.secondary,
          onPressed: () => _gantiKeModeAdmin(context, ref),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            Strings.poweredBy,
            style: TextStyle(color: context.teksRedup, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Tile menu grid ala PWA: ikon atas, teks bawah.
  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.orange, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style:
                TextStyle(color: context.teksRedup, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Baris pengaturan ala PWA.
  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return AppCard(
      onTap: onTap,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              color: danger ? AppColors.danger : AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: danger ? AppColors.danger : null,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.teksRedup),
        ],
      ),
    );
  }

  /// Sheet generik ala PWA: kicker + judul + × + isi.
  void _bukaSheet(
    BuildContext context, {
    required String kicker,
    required String title,
    required Widget child,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: TextStyle(
                      color: Theme.of(ctx).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  void _bukaPesanan(BuildContext context, WidgetRef ref, String uid) {
    _bukaSheet(
      context,
      kicker: 'Pesananmu',
      title: 'Pesanan aktif',
      child: _PesananList(uid: uid, aktifSaja: true),
    );
  }

  void _bukaRiwayat(BuildContext context, WidgetRef ref, String uid) {
    _bukaSheet(
      context,
      kicker: 'Pesananmu',
      title: 'Riwayat Pesanan',
      child: _PesananList(uid: uid, aktifSaja: false),
    );
  }

  void _bukaCatatan(BuildContext context, WidgetRef ref, String uid) {
    _bukaSheet(
      context,
      kicker: 'Dari toko',
      title: 'Catatan & Tagihan',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _catatanTokoSection(context, ref, uid),
      ),
    );
  }

  void _bukaPengaturan(BuildContext context, WidgetRef ref) {
    _bukaSheet(
      context,
      kicker: 'Sesuai caramu',
      title: 'Pengaturan Pelanggan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            onTap: () =>
                showThemePicker(context, temaPelangganProvider),
            child: Row(
              children: [
                const Icon(Icons.palette_outlined,
                    color: AppColors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tampilan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  ref.watch(temaPelangganProvider).label,
                  style: TextStyle(
                      color: context.teksRedup, fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right,
                    color: context.teksRedup, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bukaKartu(BuildContext context) {
    _bukaSheet(
      context,
      kicker: 'Kartu aplikasi',
      title: 'Kartu Pelanggan',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Tunjukkan kode ini untuk membuka Warunge Mimi',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'KQ-WM-2026',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by KasirQuh',
              style:
                  TextStyle(color: context.teksRedup, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Catatan toko: daftar tagihan/catatan dari toko + sisa tagihan.
  /// Tanpa catatan → empty state jujur.
  Widget _catatanTokoSection(
      BuildContext context, WidgetRef ref, String uid) {
    final notesAsync = ref.watch(myCustomerNotesProvider(uid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan toko',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )),
          error: (_, __) => const EmptyState(
            icon: Icons.note_outlined,
            title: 'Gagal memuat catatan toko',
            hint: Strings.periksaKoneksi,
          ),
          data: (notes) {
            if (notes.isEmpty) {
              return const EmptyState(
                icon: Icons.note_outlined,
                title: 'Belum ada catatan toko',
                hint:
                    'Tagihan atau catatan dari toko muncul di sini.',
              );
            }
            final tagihan = totalTagihan(notes);
            return Column(
              children: [
                AppCard(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisa tagihan',
                        style:
                            TextStyle(color: context.teksRedup),
                      ),
                      Text(
                        formatRp(tagihan),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: tagihan > 0
                              ? AppColors.danger
                              : AppColors.ok,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final n in notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.note.isEmpty
                                      ? customerNoteTypeLabel(n.type)
                                      : n.note,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  customerNoteTypeLabel(n.type),
                                  style: TextStyle(
                                      color: context.teksRedup,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (n.amount > 0)
                            Text(
                              formatRp(n.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: n.type == 'tagihan'
                                    ? AppColors.danger
                                    : AppColors.ok,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }


  /// Ganti ke Mode Admin via sidik jari.
  /// Alur: biometric → baca kredensial admin → signOut → signInAdmin → AdminShell.
  Future<void> _gantiKeModeAdmin(
      BuildContext context, WidgetRef ref) async {
    final svc = ref.read(biometricCredentialServiceProvider);
    final ok = await svc.verifyBiometric(Strings.alasanVerifikasiSidikJari);
    if (!ok || !context.mounted) return;
    final cred = await svc.read('admin');
    if (cred == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada akun admin tersimpan. '
                'Masuk sebagai admin dulu lalu aktifkan login cepat.'),
          ),
        );
      }
      return;
    }
    final auth = ref.read(authServiceProvider);
    if (auth == null) return;
    try {
      await auth.signOut();
      await auth.signInAdmin(email: cred.email, password: cred.password);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminShell()),
          (_) => false,
        );
      }
    } catch (_) {
      await svc.delete('admin');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.masukGagal)),
        );
      }
    }
  }

  Future<void> _confirmLogout(
      BuildContext context, WidgetRef ref) async {    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(Strings.keluar),
        content: const Text(Strings.yakinKeluar),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              Strings.keluar,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(authServiceProvider)?.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const GatewayScreen()),
          (_) => false,
        );
      }
    }
  }
}

final _myOrdersProvider =
    StreamProvider.family<List<Order>, String>((ref, uid) {
  return ref.watch(orderRepositoryProvider).watchMyOrders(uid);
});

/// Daftar pesanan untuk sheet (aktif saja atau riwayat).
class _PesananList extends ConsumerWidget {
  final String uid;
  final bool aktifSaja;

  const _PesananList({required this.uid, required this.aktifSaja});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_myOrdersProvider(uid));
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const EmptyState(
        icon: Icons.cloud_off_outlined,
        title: Strings.gagalMuatPesanan,
        hint: Strings.periksaKoneksi,
      ),
      data: (orders) {
        final list = aktifSaja
            ? orders
                .where((o) =>
                    o.status != OrderStatus.selesai &&
                    o.status != OrderStatus.dibatalkan)
                .toList()
            : orders;
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: aktifSaja
                ? 'Belum ada pesanan aktif'
                : 'Belum ada riwayat',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _OrderCardStatic(order: list[i]),
        );
      },
    );
  }
}

/// Kartu pesanan statis (dipakai di sheet).
class _OrderCardStatic extends StatelessWidget {
  final Order order;

  const _OrderCardStatic({required this.order});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.code,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatStok(order.items.fold(0.0, (s, e) => s + e.qty))} barang • ${formatRp(order.total)}',
            style: TextStyle(color: context.teksRedup, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Chip status pesanan.
class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = orderStatusLabel(status);
    final color = switch (status) {
      OrderStatus.menunggu => Colors.orange,
      OrderStatus.dikemas => Colors.blue,
      OrderStatus.dikirim => Colors.purple,
      OrderStatus.selesai => Colors.green,
      OrderStatus.dibatalkan => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
