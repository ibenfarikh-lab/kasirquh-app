import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../l10n/strings_id.dart';

/// Tab Chat — Fase 2: placeholder jujur (tanpa data siluman).
/// Chat Rumpi + Chat Toko dibangun di Fase 4.
class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.chat_bubble_outline,
      title: Strings.chatSegeraHadir,
      hint: Strings.chatSegeraHadirHint,
    );
  }
}
