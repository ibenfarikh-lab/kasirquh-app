import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/store_note.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../l10n/strings_id.dart';

/// Sheet Catatan Toko: coretan admin, tersimpan lokal di HP ini.
class StoreNotesSheet extends ConsumerStatefulWidget {
  const StoreNotesSheet({super.key});

  @override
  ConsumerState<StoreNotesSheet> createState() => _StoreNotesSheetState();
}

class _StoreNotesSheetState extends ConsumerState<StoreNotesSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _showForm = false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      _snack('Isi judul dan catatan dulu.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).saveStoreNote(
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      ref.invalidate(storeNotesProvider);
      _title.clear();
      _body.clear();
      setState(() => _showForm = false);
      _snack(Strings.berhasilDisimpan);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(StoreNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text(
          'Hapus catatan ini?',
          style: TextStyle(color: AppColors.warmText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Strings.batal),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              Strings.hapus,
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminRepositoryProvider).deleteStoreNote(note.id);
    ref.invalidate(storeNotesProvider);
    _snack(Strings.berhasilDihapus);
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _showForm
                        ? Strings.tambahCatatanToko
                        : Strings.modulCatatanToko,
                    style: const TextStyle(
                      color: AppColors.warmText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: Strings.tutup,
                  icon:
                      const Icon(Icons.close, color: AppColors.warmMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showForm) _buildForm() else _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final notesAsync = ref.watch(storeNotesProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        notesAsync.when(
          data: (List<StoreNote> notes) {
            if (notes.isEmpty) {
              return const EmptyState(
                icon: Icons.note_alt_outlined,
                title: Strings.belumAdaCatatanToko,
                hint: 'Catatan tersimpan di HP ini.',
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final n = notes[i];
                return Card(
                  color: AppColors.panel2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    title: Text(
                      n.title,
                      style: const TextStyle(
                        color: AppColors.warmText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.warmMuted),
                    ),
                    trailing: IconButton(
                      tooltip: Strings.hapus,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      onPressed: () => _confirmDelete(n),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child:
                  CircularProgressIndicator(color: AppColors.orange),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              Strings.belumAdaCatatanToko,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.warmMuted),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: Strings.tambahCatatanToko,
          onPressed: () => setState(() => _showForm = true),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          style: const TextStyle(color: AppColors.warmText),
          decoration: _deco('Judul'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _body,
          style: const TextStyle(color: AppColors.warmText),
          maxLines: 4,
          decoration: _deco(Strings.isiCatatan),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: Strings.batal,
                kind: AppButtonKind.secondary,
                fullWidth: false,
                onPressed: _busy
                    ? null
                    : () => setState(() => _showForm = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: Strings.simpan,
                fullWidth: false,
                onPressed: _busy ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
