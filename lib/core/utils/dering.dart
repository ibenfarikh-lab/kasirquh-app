/// Mode dering notifikasi — satu kosakata untuk kedua pintu.
///
/// Pelanggan memilih dengan istilah Native (bawaan/khas/hening,
/// `deringPelangganProvider`); admin memilih dengan istilah Web
/// di `store_settings.adminSoundSettings` (system/mimi/silent per
/// jenis + vibrate). Keduanya dipetakan ke mode yang sama di sini,
/// lalu `Notify` menerjemahkannya ke kanal Android yang tepat.
enum ModeDering { bawaan, khas, hening }

/// Pilihan pelanggan (SharedPreferences 'deringPelanggan').
ModeDering modeDeringPelanggan(String? pilihan) => switch (pilihan) {
      'khas' => ModeDering.khas,
      'hening' => ModeDering.hening,
      _ => ModeDering.bawaan,
    };

/// Pilihan admin gaya Web (`adminSoundSettings.<jenis>`).
ModeDering modeDeringAdmin(String? suara) => switch (suara) {
      'mimi' => ModeDering.khas,
      'silent' => ModeDering.hening,
      _ => ModeDering.bawaan,
    };

/// ID kanal notifikasi Android per mode (dibuat di `Notify.init`).
String idKanalDering(ModeDering mode) => switch (mode) {
      ModeDering.khas => 'kasirquh_khas',
      ModeDering.hening => 'kasirquh_hening',
      ModeDering.bawaan => 'kasirquh',
    };
