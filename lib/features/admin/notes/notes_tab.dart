import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/datetime_id.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/stock_note.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/store_repository.dart';
import '../../../l10n/strings_id.dart';

/// Tab Catatan: Catatan Belanja Harian satu halaman.
/// Isi: modal belanja, daftar catatan (manual + dari Belanja Stok).
/// Ubah/hapus HANYA mengubah arsip — pembukuan & stok tidak dihitung ulang.
class NotesTab extends ConsumerWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(stockNotesProvider).valueOrNull ?? const [];
    final store = ref.watch(storeInfoProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.adminBg,
        icon: const Icon(Icons.add),
        label: const Text(Strings.tambahCatatan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModalCard(
            modal: store?.modal,
            onIsi: () => _openModalDialog(context, ref, store?.modal),
          ),
          const SizedBox(height: 16),
          const Text(
            Strings.catatanHarian,
            style: TextStyle(
              color: AppColors.warmText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            const EmptyState(
              icon: Icons.note_alt_outlined,
              title: Strings.belumAdaData,
              hint: Strings.belumAdaModalHint,
            )
          else
            ...notes.map((n) => _NoteCard(note: n)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NoteFormSheet(),
    );
  }

  void _openModalDialog(
      BuildContext context, WidgetRef ref, int? current) {
    final c = TextEditingController(
        text: current == null ? '' : '$current');
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text(Strings.isiModal),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: Strings.nominalModal,
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () async {
              final v = int.tryParse(
                      c.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                  0;
              if (v <= 0) return;
              Navigator.pop(d);
              try {
                await ref
                    .read(adminRepositoryProvider)
                    .saveStoreSettings({'modal': v});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(Strings.berhasilDisimpan)),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(Strings.butuhInternetAdmin)),
                  );
                }
              }
            },
            child: const Text(Strings.simpan),
          ),
        ],
      ),
    );
  }
}

class _ModalCard extends StatelessWidget {
  final int? modal;
  final VoidCallback onIsi;

  const _ModalCard({required this.modal, required this.onIsi});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Strings.modalBelanja,
                  style:
                      TextStyle(color: AppColors.warmMuted, fontSize: 12),
                ),
                Text(
                  modal == null ? Strings.belumAdaModal : formatRp(modal!),
                  style: const TextStyle(
                    color: AppColors.warmText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: Strings.isiModal,
            fullWidth: false,
            kind: AppButtonKind.secondary,
            onPressed: onIsi,
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StockNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(note.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => _openDetail(context),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.supplier,
                          style: const TextStyle(
                            color: AppColors.warmText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _SourceChip(source: note.source),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date == null ? note.date : formatTanggal(date)} · '
                    '${note.items.length} barang',
                    style: const TextStyle(
                        color: AppColors.warmMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRp(note.total),
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteDetailSheet(note: note),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String source;

  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final isAuto = source == 'belanja_stok';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAuto ? AppColors.ok : AppColors.panel2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAuto ? Strings.dariBelanjaStok : Strings.manualTeks,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _NoteDetailSheet extends ConsumerWidget {
  final StockNote note;

  const _NoteDetailSheet({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.tryParse(note.date);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.supplier,
                  style: const TextStyle(
                    color: AppColors.warmText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SourceChip(source: note.source),
            ],
          ),
          Text(
            date == null ? note.date : formatTanggal(date),
            style: const TextStyle(color: AppColors.warmMuted),
          ),
          const SizedBox(height: 12),
          ...note.items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it.name} × ${it.qty}',
                        style: const TextStyle(
                            color: AppColors.warmText),
                      ),
                    ),
                    Text(
                      formatRp(it.subtotal),
                      style: const TextStyle(
                          color: AppColors.warmMuted),
                    ),
                  ],
                ),
              )),
          const Divider(color: AppColors.adminLine),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(Strings.totalBelanja,
                  style: TextStyle(color: AppColors.warmMuted)),
              Text(
                formatRp(note.total),
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            Strings.arsipSaja,
            style: TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: Strings.ubah,
                  kind: AppButtonKind.secondary,
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _NoteFormSheet(existing: note),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: Strings.hapus,
                  kind: AppButtonKind.danger,
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text(Strings.hapus),
        content: const Text(Strings.arsipSaja),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(Strings.hapus,
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      // Hapus arsip saja (lokal + antrean).
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteStockNote(note.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

/// Form tambah/ubah catatan (sheet tugas cepat).
class _NoteFormSheet extends ConsumerStatefulWidget {
  final StockNote? existing;

  const _NoteFormSheet({this.existing});

  @override
  ConsumerState<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _ItemRow {
  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

class _NoteFormSheetState extends ConsumerState<_NoteFormSheet> {
  final _supplier = TextEditingController();
  final _rows = <_ItemRow>[_ItemRow()];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _supplier.text = e.supplier;
      _rows.clear();
      for (final it in e.items) {
        final r = _ItemRow();
        r.name.text = it.name;
        r.qty.text = '${it.qty}';
        r.price.text = '${it.price}';
        _rows.add(r);
      }
      if (_rows.isEmpty) _rows.add(_ItemRow());
    }
  }

  @override
  void dispose() {
    _supplier.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  int get _total {
    var t = 0;
    for (final r in _rows) {
      final q = int.tryParse(r.qty.text) ?? 0;
      final p =
          int.tryParse(r.price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      t += q * p;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
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
              widget.existing == null
                  ? Strings.tambahCatatan
                  : Strings.ubah,
              style: const TextStyle(
                color: AppColors.warmText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _supplier,
              style: const TextStyle(color: AppColors.warmText),
              decoration: const InputDecoration(
                labelText: Strings.namaSupplier,
                labelStyle: TextStyle(color: AppColors.warmMuted),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.adminLine),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              Strings.daftarBarang,
              style: TextStyle(
                  color: AppColors.warmText, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._rows.asMap().entries.map((en) {
              final i = en.key;
              final r = en.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _num(
                        r.name,
                        Strings.namaBarang,
                        TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _num(r.qty, 'Qty', TextInputType.number),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _num(r.price, 'Rp', TextInputType.number),
                    ),
                    if (_rows.length > 1)
                      IconButton(
                        onPressed: () => setState(() {
                          r.dispose();
                          _rows.removeAt(i);
                        }),
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.danger),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _rows.add(_ItemRow())),
              icon: const Icon(Icons.add, color: AppColors.orange),
              label: const Text(Strings.tambahBaris,
                  style: TextStyle(color: AppColors.orange)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(Strings.totalBelanja,
                    style: TextStyle(color: AppColors.warmMuted)),
                Text(
                  formatRp(_total),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: _busy ? '...' : Strings.simpan,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label, TextInputType type) {
    return TextField(
      controller: c,
      keyboardType: type,
      inputFormatters: type == TextInputType.text
          ? null
          : [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.warmText, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.warmMuted, fontSize: 13),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.adminLine),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _save() async {
    if (_supplier.text.trim().isEmpty || _total <= 0) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final items = _rows
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => StockNoteItem(
                name: r.name.text.trim(),
                qty: int.tryParse(r.qty.text) ?? 0,
                price: int.tryParse(
                        r.price.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0,
              ))
          .where((e) => e.qty > 0)
          .toList();
      if (items.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final isEdit = widget.existing != null;
      final note = StockNote(
        id: isEdit ? widget.existing!.id : '',
        date: isEdit ? widget.existing!.date : date,
        supplier: _supplier.text.trim(),
        items: items,
        total: items.fold(0, (s, e) => s + e.subtotal),
        source: isEdit ? widget.existing!.source : 'manual',
        createdAt: isEdit ? widget.existing!.createdAt : now,
      );
      final noteId = await repo.saveStockNote(note);
      if (!isEdit) {
        // Catatan baru: jurnal kulakan + kurangi modal.
        // Modal sebagai delta antrean: tidak dilewati diam-diam saat offline.
        await repo.addJournal(
          kind: 'kulakan',
          label: 'Kulakan · ${note.supplier}',
          amount: -note.total,
          refId: noteId,
        );
        await repo.adjustModal(-note.total);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.berhasilDisimpan)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(Strings.butuhInternetAdmin)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
