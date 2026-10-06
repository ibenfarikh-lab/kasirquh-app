/// Laporan startup: menampung error init agar aplikasi SELALU bisa dibuka.
///
/// Prinsip: kegagalan Firebase/DB/sync tidak boleh membuat aplikasi
/// force close. Error dicatat di sini, aplikasi jalan mode lokal,
/// dan Gateway menampilkan peringatan kecil bila ada error.
class StartupReport {
  StartupReport._();

  static final List<String> errors = [];

  static void add(String step, Object error) {
    errors.add('$step: $error');
  }

  static bool get hasErrors => errors.isNotEmpty;

  static void clear() => errors.clear();
}
