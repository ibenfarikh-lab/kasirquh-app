import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/customer_note.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Catatan Toko per pelanggan (kasbon digital V1) — Mode Admin.
/// Admin mencatat tagihan/pembayaran/catatan; pelanggan melihatnya
/// di Tab Akun sebagai "Catatan toko".
class CustomerNotesSheet extends ConsumerWidget {
  final Customer customer;

  const CustomerNotesSheet({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync =
        ref.watch(_customerNotesProvider(customer.uid));
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.adminLine,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${Strings.modulCatatanToko} — ${customer.name}',
              style: const TextStyle(
                color: AppColors.warmText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            notesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.orange)),
              ),
              error: (_, __) => const EmptyState(
                icon: Icons.note_outlined,
                title: Strings.belumAdaCatatanToko,
                hint: Strings.butuhInternetAdmin,
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return const EmptyState(
                    icon: Icons.note_outlined,
                    title: Strings.belumAdaCatatanToko,
                  );
                }
                final tagihan = totalTagihan(notes);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sisa tagihan',
                            style: TextStyle(
                                color: AppColors.warmMuted),
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
                      _noteTile(context, ref, n),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppButton(
              label: Strings.tambahCatatanToko,
              fullWidth: true,
              onPressed: () =>
                  _tambahDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteTile(
      BuildContext context, WidgetRef ref, CustomerNote n) {
    final isTagihan = n.type == 'tagihan';
    final isBayar = n.type == 'pembayaran';
    return Card(
      color: AppColors.panel2,
      child: ListTile(
        title: Text(
          n.note.isEmpty
              ? customerNoteTypeLabel(n.type)
              : n.note,
          style: const TextStyle(color: AppColors.warmText),
        ),
        subtitle: Text(
          '${customerNoteTypeLabel(n.type)}${n.amount > 0 ? ' · ${formatRp(n.amount)}' : ''}',
          style: const TextStyle(color: AppColors.warmMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              n.amount > 0
                  ? '${isBayar ? '-' : '+'}${formatRp(n.amount)}'
                  : '',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isTagihan
                    ? AppColors.danger
                    : isBayar
                        ? AppColors.ok
                        : AppColors.warmMuted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
              onPressed: () => _hapus(context, ref, n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapus(
      BuildContext context, WidgetRef ref, CustomerNote n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel2,
        title: const Text('Hapus catatan ini?',
            style: TextStyle(color: AppColors.warmText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Strings.hapus,
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteCustomerNote(n.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(Strings.butuhInternetAdmin)),
        );
      }
    }
  }

  Future<void> _tambahDialog(
      BuildContext context, WidgetRef ref) async {
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var type = 'tagihan';
    var busy = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.panel2,
          title: const Text(Strings.tambahCatatanToko,
              style: TextStyle(color: AppColors.warmText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  dropdownColor: AppColors.panel2,
                  style:
                      const TextStyle(color: AppColors.warmText),
                  decoration: const InputDecoration(
                    labelText: 'Jenis',
                    labelStyle:
                        TextStyle(color: AppColors.warmMuted),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'tagihan',
                        child: Text('Tagihan (belum dibayar)')),
                    DropdownMenuItem(
                        value: 'pembayaran',
                        child: Text('Pembayaran')),
                    DropdownMenuItem(
                        value: 'catatan',
                        child: Text('Catatan umum')),
                  ],
                  onChanged: (v) =>
                      setState(() => type = v ?? 'tagihan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style:
                      const TextStyle(color: AppColors.warmText),
                  decoration: const InputDecoration(
                    labelText: 'Nominal (Rp)',
                    labelStyle:
                        TextStyle(color: AppColors.warmMuted),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style:
                      const TextStyle(color: AppColors.warmText),
                  decoration: const InputDecoration(
                    labelText: Strings.isiCatatan,
                    hintText: 'Cth: Ambil beras 1 karung',
                    labelStyle:
                        TextStyle(color: AppColors.warmMuted),
                    hintStyle:
                        TextStyle(color: AppColors.warmMuted),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(Strings.batal),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final amount = int.tryParse(amountCtrl.text
                                .replaceAll(
                                    RegExp(r'[^0-9]'), '')) ??
                            0;
                        await ref
                            .read(adminRepositoryProvider)
                            .saveCustomerNote(
                              customerId: customer.uid,
                              type: type,
                              amount: amount,
                              note: noteCtrl.text,
                            );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(true);
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    Strings.butuhInternetAdmin)),
                          );
                          setState(() => busy = false);
                        }
                      }
                    },
              child: const Text(Strings.simpan),
            ),
          ],
        ),
      ),
    );
    noteCtrl.dispose();
    amountCtrl.dispose();
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(Strings.berhasilDisimpan)),
      );
    }
  }
}

final _customerNotesProvider =
    StreamProvider.family<List<CustomerNote>, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).watchCustomerNotes(uid);
});
