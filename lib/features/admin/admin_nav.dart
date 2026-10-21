import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_settings.dart';

void openAdminPage(BuildContext context, Widget page) {
  final pilihan =
      ProviderScope.containerOf(context).read(temaAdminProvider);
  final sistem = MediaQuery.platformBrightnessOf(context);
  final tema = temaAdminAktif(pilihan, sistem);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => Theme(data: tema, child: page)),
  );
}
