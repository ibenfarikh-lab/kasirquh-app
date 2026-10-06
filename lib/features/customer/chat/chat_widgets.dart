import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/rumpi.dart';

/// Gelembung pesan — dipakai Chat Toko & Chat Komunitas (tema terang).
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool milikSaya;
  final String? namaPengirim;
  const ChatBubble({
    super.key,
    required this.message,
    required this.milikSaya,
    this.namaPengirim,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          milikSaya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: milikSaya ? AppColors.orange : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: milikSaya
              ? null
              : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!milikSaya && namaPengirim != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  namaPengirim!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: milikSaya ? Colors.white : AppColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              waktuRelatif(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: milikSaya
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bar input pesan — dipakai Chat Toko & Chat Komunitas.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
