import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';

/// Sheet tulis kabar Rumpi: teks + foto opsional dari HP
/// (di-resize maks 300px, PNG base64 — tanpa Firebase Storage).
class ComposePostSheet extends ConsumerStatefulWidget {
  final String uid;
  final String nama;
  const ComposePostSheet(
      {super.key, required this.uid, required this.nama});

  @override
  ConsumerState<ComposePostSheet> createState() =>
      _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _controller = TextEditingController();
  Uint8List? _foto;
  bool _mengirim = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto() async {
    setState(() => _error = null);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // Batasi sisi panjang 600px di picker; resize final 300px di bawah.
        maxWidth: 600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        setState(() => _error = Strings.fotoTidakTerbaca);
        return;
      }
      final kecil = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 300 : null,
        height: decoded.height > decoded.width ? 300 : null,
      );
      final png = Uint8List.fromList(img.encodePng(kecil));
      if (png.lengthInBytes > 800 * 1024) {
        setState(() => _error = Strings.fotoTerlaluBesar);
        return;
      }
      setState(() => _foto = png);
    } catch (_) {
      setState(() => _error = Strings.fotoTidakTerbaca);
    }
  }

  Future<void> _kirim() async {
    final teks = _controller.text.trim();
    if (teks.isEmpty) {
      setState(() => _error = Strings.tulisKabarDulu);
      return;
    }
    setState(() {
      _mengirim = true;
      _error = null;
    });
    try {
      String? dataUri;
      if (_foto != null) {
        dataUri = 'data:image/png;base64,${base64Encode(_foto!)}';
      }
      await ref.read(socialRepositoryProvider).createPost(
            uid: widget.uid,
            authorName: widget.nama,
            text: teks,
            imageUrl: dataUri,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _mengirim = false;
        _error = Strings.butuhInternet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bawah = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bawah),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: SizedBox(
                width: 48,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              Strings.tulisKabar,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: Strings.kabarHint,
                border: OutlineInputBorder(),
              ),
            ),
            if (_foto != null) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_foto!, height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: InkWell(
                      onTap: () => setState(() => _foto = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pilihFoto,
              icon: const Icon(Icons.photo_outlined),
              label: const Text(Strings.tambahFoto),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: _mengirim ? Strings.mengirim : Strings.kirimKabar,
              onPressed: _mengirim ? null : _kirim,
            ),
          ],
        ),
      ),
    );
  }
}
