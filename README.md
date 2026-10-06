# KasirQuh-app

Aplikasi warung **Warunge Mimi** — satu aplikasi dua mode (Pelanggan & Admin).
Powered by KasirQuh.

## Prasyarat

- Flutter SDK ≥ 3.4.0 (stable)
- Project Firebase `kasirquh-app` (region Jakarta)
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## Setup

1. Hasilkan konfigurasi Firebase asli:
   ```
   flutterfire configure --project=kasirquh-app
   ```
   Ini menimpa `lib/firebase_options.dart` (saat ini masih PLACEHOLDER)
   dan menaruh `google-services.json` ke `android/app/`.
2. Di Firebase Console: Authentication → Email/Password **diaktifkan**;
   Firestore → database region Jakarta + deploy security rules
   (lihat `FIRESTORE_SCHEMA.md` di dokumen Fase 0).
   Storage **dilewati** (butuh Blaze — keputusan user).
3. Akun admin dibuat manual di Authentication, lalu diberi custom claim
   `admin: true` via Admin SDK (satu kali, bukan dari aplikasi).
4. ```
   flutter pub get
   flutter run
   ```

## Struktur

```
lib/
├── main.dart            # bootstrap: Firebase init, DB lokal, runApp
├── app.dart             # MaterialApp: theme per mode
├── firebase_options.dart# PLACEHOLDER → flutterfire configure
├── core/theme/          # AppColors, AppText, AppTheme (customer/admin)
├── core/widgets/        # AppCard, AppButton, EmptyState
├── core/utils/          # formatRp, formatTanggal (id-ID)
├── data/models/         # product, order, customer, journal_entry
├── data/local/          # AppDatabase (sqflite, offline-first)
├── data/remote/         # auth_service, firestore_service
├── data/sync/           # SyncEngine (queue → push; pull publik)
├── features/gateway/    # 3 slide @4000ms + hotspot admin + tap logo 5x
├── features/auth/       # LoginSheet (Masuk/Daftar), PinScreen, PinService
├── features/customer/   # Mode Pelanggan — Fase 2
├── features/admin/      # Mode Admin — Fase 3
└── l10n/strings_id.dart # semua string Bahasa Indonesia
```

## Build APK

- Debug: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
- Rilis: `flutter build apk --release` (butuh keystore — nanti di Fase 5)
- CI: GitHub Actions membangun APK debug otomatis tiap push ke `main`
  (workflow: `.github/workflows/build-apk.yml`).

## Aturan main

- Header aplikasi = nama warung (**Warunge Mimi**). "KasirQuh" hanya sebagai
  "Powered by KasirQuh" — tidak pernah di header.
- Bahasa Indonesia di semua string (`lib/l10n/strings_id.dart`).
- Prinsip data: tidak ada istilah/keuangan siluman; empty state jujur
  ("Belum ada ...") daripada angka 0.
- Offline-first: tulis ke SQLite lokal dulu, sinkron ke Firestore saat online.
  Konflik stok/status pesanan: server menang.
