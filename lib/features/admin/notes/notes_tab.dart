import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/datetime_id.dart';
import '../../../data/models/product.dart';
import '../../../data/models/stock_note.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/strings_id.dart';
import '../menu/stock_shopping_sheet.dart';

/// Fungsi murni (di-test): label pil sumber catatan.
/// Perbaikan bug: 'impor' selama ini tampil 'Manual'.
String labelSumberCatatan(String source) => switch (source) {
      'belanja_stok' => Strings.dariBelanjaStok,
      'impor' => Strings.labelImpor,
      _ => Strings.manualTeks,
    };

/// Fungsi murni (di-test): label satu baris barang di kartu.
String labelItemBarang(StockNoteItem it) =>
    it.qty > 1 ? '${it.name} · ${formatStok(it.qty)}' : it.name;



/// Fungsi murni (di-test): kunci tanggal YYYY-MM-DD untuk filter.
String kunciTanggal(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Fungsi murni (di-test): nilai stok = Σ stok × modal/pcs.
/// Stok desimal dipertahankan (3,75 × 4000 = 15000, bukan 12000).
double nilaiStokModal(List<Product> products) =>
    products.fold(0.0, (s, p) => s + p.stock * p.cost);

/// Mode Admin > Tab Catatan: Catatan Belanja Harian satu halaman.
/// Acuan tampilan = PWA (halaman Catatan Belanja).
/// Ubah/hapus HANYA mengubah arsip — pembukuan & stok tidak dihitung ulang.
class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  DateTime _tanggal = DateTime.now();

  String get _kunci => kunciTanggal(_tanggal);

  void _geserHari(int delta) {
    setState(() => _tanggal = _tanggal.add(Duration(days: delta)));
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  void _bukaBelanjaStok() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StockShoppingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(stockNotesProvider).valueOrNull ?? const [];
    // NILAI STOK dihitung dari SEMUA produk tanpa filter isActive
    // (ikut PWA) — jalur baca khusus, bukan productsProvider.
    final products = ref.watch(allProductsProvider).valueOrNull ?? const [];
    final hariIni = notes.where((n) => n.date == _kunci).toList();
    final totalHari = hariIni.fold(0, (s, n) => s + n.total);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kepala halaman: kicker + judul + tombol Belanja Stok.
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.kickerKulakan,
                      style: TextStyle(
                          color: AppColors.warmMuted, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      Strings.judulCatatanBelanja,
                      style: TextStyle(
                        color: AppColors.warmText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: Strings.modulBelanjaStok,
                fullWidth: false,
                kind: AppButtonKind.secondary,
                onPressed: _bukaBelanjaStok,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NilaiStokCard(nilai: nilaiStokModal(products)),
          const SizedBox(height: 16),
          // Navigator tanggal: ‹ tanggal ›
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _geserHari(-1),
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.warmText),
              ),
              TextButton(
                onPressed: _pilihTanggal,
                child: Text(
                  DateFormat('d MMM yyyy', 'id_ID').format(_tanggal),
                  style: const TextStyle(
                    color: AppColors.warmText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _geserHari(1),
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.warmText),
              ),
            ],
          ),
          // Header hari: tanggal + "N catatan · total RpX".
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_tanggal),
            style: const TextStyle(
              color: AppColors.warmText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            Strings.labelCatatanHari(
                hariIni.length, formatRp(totalHari)),
            style: const TextStyle(
                color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (hariIni.isEmpty)
            const EmptyState(
              icon: Icons.note_alt_outlined,
              title: Strings.belumAdaCatatanTanggal,
            )
          else
            ...hariIni.map((n) => _NoteCard(note: n)),
          const SizedBox(height: 16),
          _FormTambah(tanggal: _kunci),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

}

/// Kartu NILAI STOK · MODAL DI RAK (paling atas).
class _NilaiStokCard extends StatelessWidget {
  final double nilai;
  const _NilaiStokCard({required this.nilai});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            Strings.nilaiStokModalRak,
            style:
                TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            formatRp(nilai.round()),
            style: const TextStyle(
              color: AppColors.warmText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            Strings.nilaiStokDeskripsi,
            style:
                TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Kartu catatan ala PWA: judul + pil sumber, "N jenis barang",
/// daftar isi barang, footer total, chevron ›. Tap → detail arsip.
class _NoteCard extends StatelessWidget {
  final StockNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _NoteDetailSheet(note: note),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.supplier,
                        style: const TextStyle(
                          color: AppColors.warmText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Strings.labelJenisBarang(note.items.length),
                        style: const TextStyle(
                            color: AppColors.warmMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _SourcePill(source: note.source),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    color: AppColors.warmMuted),
              ],
            ),
            if (note.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...note.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• ${labelItemBarang(it)}',
                      style: const TextStyle(
                          color: AppColors.warmText, fontSize: 13),
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  Strings.totalBelanja,
                  style: TextStyle(
                      color: AppColors.warmMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  formatRp(note.total),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String source;

  const _SourcePill({required this.source});

  @override
  Widget build(BuildContext context) {
    final otomatis = source == 'belanja_stok';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: otomatis ? AppColors.ok : AppColors.panel2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labelSumberCatatan(source),
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
              _SourcePill(source: note.source),
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
                        labelItemBarang(it),
                        style: const TextStyle(
                            color: AppColors.warmText),
                      ),
                    ),
                    if (it.subtotal > 0)
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
        // Aturan 3: dialog = L3.
        backgroundColor: AppColors.panel2,
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

/// Form "Tambah catatan" di bawah daftar (ikut PWA):
/// Supplier, Barang yang dibeli (satu per baris), Total habis.
class _FormTambah extends ConsumerStatefulWidget {
  final String tanggal;
  const _FormTambah({required this.tanggal});

  @override
  ConsumerState<_FormTambah> createState() => _FormTambahState();
}

class _FormTambahState extends ConsumerState<_FormTambah> {
  final _supplier = TextEditingController();
  final _items = TextEditingController();
  final _total = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _supplier.dispose();
    _items.dispose();
    _total.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _simpan() async {
    final supplier = _supplier.text.trim();
    final baris = _items.text
        .split(RegExp(r'\n|,'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final total =
        int.tryParse(_total.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (supplier.isEmpty || baris.isEmpty || total <= 0) {
      _snack(Strings.lengkapiCatatanBelanja);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final note = StockNote(
        id: '',
        date: widget.tanggal,
        supplier: supplier,
        items: baris
            .map((b) =>
                StockNoteItem(name: b, qty: 1.0, price: 0))
            .toList(),
        total: total,
        source: 'manual',
        createdAt: DateTime.now(),
      );
      final noteId = await repo.saveStockNote(note);
      // Catatan baru: jurnal kulakan + kurangi modal (seperti sebelumnya).
      await repo.addJournal(
        kind: 'kulakan',
        label: 'Kulakan · $supplier',
        amount: -total,
        refId: noteId,
      );
      await repo.adjustModal(-total);
      _supplier.clear();
      _items.clear();
      _total.clear();
      _snack(Strings.berhasilDisimpan);
    } catch (_) {
      _snack(Strings.butuhInternetAdmin);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.warmMuted),
        filled: true,
        fillColor: AppColors.panel2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            Strings.tambahCatatan,
            style: TextStyle(
              color: AppColors.warmText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            Strings.labelSupplier,
            style:
                TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _supplier,
            style: const TextStyle(color: AppColors.warmText),
            decoration: _deco(Strings.contohSupplier),
          ),
          const SizedBox(height: 12),
          const Text(
            Strings.barangDibeli,
            style:
                TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _items,
            style: const TextStyle(color: AppColors.warmText),
            maxLines: 3,
            decoration: _deco(Strings.contohBarang),
          ),
          const SizedBox(height: 12),
          const Text(
            Strings.totalHabis,
            style:
                TextStyle(color: AppColors.warmMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _total,
            style: const TextStyle(color: AppColors.warmText),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: _deco(Strings.contohTotal),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _busy ? '...' : Strings.simpanCatatanBelanja,
            onPressed: _busy ? null : _simpan,
          ),
        ],
      ),
    );
  }
}

/// Form ubah catatan (dipakai dari sheet detail; sifat arsip).
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
        r.qty.text = formatStok(it.qty);
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
      final q = parseDesimal(r.qty.text);
      final p =
          int.tryParse(r.price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      t += (q * p).round();
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
                      child: _num(r.qty, 'Qty',
                          const TextInputType.numberWithOptions(decimal: true),
                          decimal: true),
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

  Widget _num(TextEditingController c, String label, TextInputType type,
      {bool decimal = false}) {
    return TextField(
      controller: c,
      keyboardType: type,
      inputFormatters: type == TextInputType.text
          ? null
          : decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]
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
                qty: parseDesimal(r.qty.text),
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
        total: items.fold(0.0, (s, e) => s + e.subtotal).round(),
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
