import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../customer_shell.dart';
import '../session.dart';
import 'rumpi_feed.dart';
import 'toko_chat_page.dart';

/// Mode Pelanggan > Tab Chat — plek-plek PWA live (?v=20261013r).
/// Header "Tetap terhubung" / "Chat" + 2 kartu pilihan:
/// "Rumpi Warga" dan "Chat Toko" — masing-masing buka sheet modal.
/// Tamu melihat kartu, diblokir saat tap (modal login).
class ChatTab extends ConsumerWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final uid = memberUid(session ?? const Session.guest());
    final nama = displayName(session ?? const Session.guest());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        // Header ala PWA.
        Text(
          'Tetap terhubung',
          style: TextStyle(
            color: context.teksRedup,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'Chat',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        // Kartu Rumpi Warga.
        _chatChoiceCard(
          context,
          icon: Icons.groups_outlined,
          title: 'Rumpi Warga',
          subtitle: 'Obrolan tetangga, resep, dan kabar sekitar.',
          onTap: () {
            if (uid == null) {
              _loginGate(context, ref);
              return;
            }
            _bukaRumpi(context, uid, nama);
          },
        ),
        const SizedBox(height: 12),
        // Kartu Chat Toko.
        _chatChoiceCard(
          context,
          icon: Icons.storefront_outlined,
          title: 'Chat Toko',
          subtitle: 'Tanya stok, pesanan, atau kebutuhanmu.',
          onTap: () {
            if (uid == null) {
              _loginGate(context, ref);
              return;
            }
            _bukaToko(context, uid);
          },
        ),
      ],
    );
  }

  /// Kartu pilihan ala PWA: ikon 42px | teks | chevron.
  Widget _chatChoiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      TextStyle(color: context.teksRedup, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.teksRedup),
        ],
      ),
    );
  }

  /// Gate login ala PWA untuk tamu — halaman penuh
  /// (aturan user: bottom sheet hanya Teman Belanja/AI).
  void _loginGate(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Masuk / Daftar')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur khusus pelanggan',
                  style: TextStyle(
                    color: context.teksRedup,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masuk / Daftar',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mau lanjut? Login atau daftar dulu ya...',
                  style:
                      TextStyle(color: context.teksRedup, fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Pindah ke tab Akun untuk login.
                      ref.read(customerTabProvider.notifier).state = 4;
                    },
                    child: const Text('Masuk / Daftar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rumpi Warga — halaman penuh
  /// (aturan user: bottom sheet hanya Teman Belanja/AI).
  void _bukaRumpi(BuildContext context, String uid, String nama) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Rumpi Warga')),
          body: RumpiFeed(
            uid: uid,
            nama: nama,
            modeSheet: true,
          ),
        ),
      ),
    );
  }

  /// Chat Toko — halaman penuh
  /// (aturan user: bottom sheet hanya Teman Belanja/AI).
  void _bukaToko(BuildContext context, String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Chat Toko')),
          body: TokoChatPage(uid: uid),
        ),
      ),
    );
  }
}
