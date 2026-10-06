import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/rumpi.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';

/// Mode Pelanggan > Akun > Riwayat Koin — baca dari `coin_ledger`.
class CoinHistoryPage extends ConsumerWidget {
  final String uid;
  const CoinHistoryPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(coinLedgerProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.riwayatKoin)),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.monetization_on_outlined,
          title: Strings.koinKosong,
          hint: Strings.butuhInternetUmum,
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.monetization_on_outlined,
              title: Strings.koinKosong,
              hint: Strings.koinKosongHint,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) =>
                _CoinTile(entry: entries[i]),
          );
        },
      ),
    );
  }
}

class _CoinTile extends StatelessWidget {
  final CoinEntry entry;
  const _CoinTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final plus = entry.amount >= 0;
    final date = DateFormat('d MMM yyyy, HH:mm', 'id_ID')
        .format(entry.createdAt);
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (plus ? AppColors.ok : AppColors.danger)
              .withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          plus ? Icons.add : Icons.remove,
          color: plus ? AppColors.ok : AppColors.danger,
        ),
      ),
      title: Text(
        labelAlasanKoin(entry.reason),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        date,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: Text(
        '${plus ? '+' : ''}${NumberFormat('#,###', 'id_ID').format(entry.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: plus ? AppColors.ok : AppColors.danger,
        ),
      ),
    );
  }
}
