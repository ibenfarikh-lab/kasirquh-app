import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasirquh_app/core/theme/app_colors.dart';
import 'package:kasirquh_app/core/theme/app_theme.dart';
import 'package:kasirquh_app/data/models/chat.dart';
import 'package:kasirquh_app/data/repositories/admin_repository.dart';
import 'package:kasirquh_app/data/repositories/store_repository.dart';
import 'package:kasirquh_app/features/admin/admin_session.dart';
import 'package:kasirquh_app/features/admin/menu/chat_page.dart';
import 'package:kasirquh_app/l10n/strings_id.dart';

/// Bukti Lapis 1: nama + pratinjau pesan di daftar thread Chat admin
/// wajib terbaca di tema terang maupun gelap (tidak hardcode).
final _threadContoh = ChatThread(
  id: 'uid-iben',
  customerId: 'uid-iben',
  customerName: 'Iben',
  lastMessage: 'Halo',
  updatedAt: DateTime(2026, 10, 7),
);

List<Override> _overrideThread() => [
      chatThreadsProvider.overrideWith((ref) => Stream.value([_threadContoh])),
      adminSessionProvider.overrideWith((ref) => Stream.value(null)),
      storeInfoProvider.overrideWith((ref) => Stream.value(const StoreInfo())),
    ];

Future<void> _bukaTabChatToko(WidgetTester tester) async {
  expect(find.text(Strings.tabAdminChatToko), findsOneWidget);
  await tester.tap(find.text(Strings.tabAdminChatToko));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(find.text('Iben'), findsOneWidget);
}

Color _warnaTeks(WidgetTester tester, String teks) {
  final t = tester.widget<Text>(find.text(teks));
  return t.style!.color!;
}

void main() {
  testWidgets('tema terang: nama gelap, pratinjau abu gelap (terbaca)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrideThread(),
        child: MaterialApp(
          theme: AppTheme.adminLightTheme(),
          home: const ChatPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await _bukaTabChatToko(tester);

    expect(_warnaTeks(tester, 'Iben'), AppColors.ink,
        reason: 'nama harus gelap di tema terang');
    expect(_warnaTeks(tester, 'Halo'), AppColors.muted,
        reason: 'pratinjau harus abu gelap di tema terang');
  });

  testWidgets('tema gelap: nama terang, pratinjau abu terang (terbaca)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrideThread(),
        child: MaterialApp(
          theme: AppTheme.adminTheme(),
          home: const ChatPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await _bukaTabChatToko(tester);

    expect(_warnaTeks(tester, 'Iben'), AppColors.warmText,
        reason: 'nama harus terang di tema gelap');
    expect(_warnaTeks(tester, 'Halo'), AppColors.warmMuted,
        reason: 'pratinjau harus abu terang di tema gelap');
  });
}
