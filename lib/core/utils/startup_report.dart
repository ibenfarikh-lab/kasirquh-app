class StartupReport {
  StartupReport._();

  static final List<String> errors = [];

  static void add(String step, Object error) {
    errors.add('$step: $error');
  }

  static bool get hasErrors => errors.isNotEmpty;

  static void clear() => errors.clear();
}
