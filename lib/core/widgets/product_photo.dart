import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../theme/app_colors.dart';

/// Foto produk tanpa Firebase Storage (keputusan dikunci: tanpa Blaze).
/// Sumber foto:
/// - data URI (`data:image/...;base64,...`) — foto lokal per-perangkat,
///   dipilih dari HP lalu di-resize ≤300px PNG;
/// - URL online (`http...`) — foto dari internet;
/// - path file lokal — cadangan bila tersimpan sebagai file.
/// Bila kosong/gagal → ikon kemasan (bukan kotak putih siluman).
class ProductPhoto extends StatelessWidget {
  final String? photoPath;
  final double size;
  final double borderRadius;

  const ProductPhoto({
    super.key,
    required this.photoPath,
    this.size = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final provider = photoImageProvider(photoPath);
    if (provider == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.panel2,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: size * 0.45,
          color: AppColors.warmMuted,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.panel2,
          child: Icon(
            Icons.inventory_2_outlined,
            size: size * 0.45,
            color: AppColors.warmMuted,
          ),
        ),
      ),
    );
  }
}

/// ImageProvider dari photoPath produk. null bila kosong/tak dikenal.
ImageProvider? photoImageProvider(String? photoPath) {
  if (photoPath == null || photoPath.isEmpty) return null;
  if (photoPath.startsWith('data:image')) {
    try {
      final b64 = photoPath.split(',').last;
      return MemoryImage(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }
  if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
    return NetworkImage(photoPath);
  }
  final file = File(photoPath);
  if (file.existsSync()) return FileImage(file);
  return null;
}

/// Pilih foto dari galeri HP → resize ≤300px → PNG data URI.
/// Pola yang sama dipakai form Rumpi (compose_post_sheet).
/// Mengembalikan data URI, atau null bila dibatalkan/gagal.
Future<String?> pickProductPhoto() async {
  try {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final kecil = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 300 : null,
      height: decoded.height > decoded.width ? 300 : null,
    );
    final png = img.encodePng(kecil);
    if (png.length > 800 * 1024) return null;
    return 'data:image/png;base64,${base64Encode(png)}';
  } catch (_) {
    return null;
  }
}
