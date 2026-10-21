import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/social_repository.dart';
import '../../../l10n/strings_id.dart';
import '../session.dart';

class GameConfig {
  final String id;
  final String title;
  final String assetPath;
  final String messageType;
  final String reason;
  final String label;
  final String dateField;
  final String todayField;

  const GameConfig({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.messageType,
    required this.reason,
    required this.label,
    required this.dateField,
    required this.todayField,
  });
}

const gameTangkapDiskon = GameConfig(
  id: 'tangkap_diskon',
  title: 'Tangkap Diskon',
  assetPath: 'assets/games/tangkap-diskon.html',
  messageType: 'tangkapDiskonScore',
  reason: 'game_tangkap_diskon',
  label: 'Tangkap Diskon',
  dateField: 'gameCoinsDate',
  todayField: 'gameCoinsToday',
);

const gameBuruDiskon = GameConfig(
  id: 'buru_diskon',
  title: 'Buru Diskon',
  assetPath: 'assets/games/buru-diskon.html',
  messageType: 'buruDiskonScore',
  reason: 'game_buru_diskon',
  label: 'Buru Diskon',
  dateField: 'buruGameCoinsDate',
  todayField: 'buruGameCoinsToday',
);

const _pointsPerCoin = 1000;
const _maxPoints = 60000;
const _minDurationMs = 20000;
const _maxCoinsPerDay = 500;

class GameWebViewPage extends ConsumerStatefulWidget {
  final GameConfig config;

  const GameWebViewPage({super.key, required this.config});

  @override
  ConsumerState<GameWebViewPage> createState() => _GameWebViewPageState();
}

class _GameWebViewPageState extends ConsumerState<GameWebViewPage> {
  late final WebViewController _controller;
  int? _points;
  int? _coins;
  String? _note;
  bool _busy = false;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GameChannel',
        onMessageReceived: _onGameMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _injectBridge(),
        ),
      );
    _loadGame();
  }

  Future<void> _loadGame() async {
    final html = await rootBundle.loadString(widget.config.assetPath);
    await _controller.loadHtmlString(html);
  }

  Future<void> _injectBridge() async {
    await _controller.runJavaScript('''
      (function() {
        if (window.__gameBridgeInjected) return;
        window.__gameBridgeInjected = true;
        var originalPostMessage = null;
        try {
          // Override parent.postMessage
          window.parent = window.parent || {};
          originalPostMessage = window.parent.postMessage;
          window.parent.postMessage = function(data, target) {
            try {
              GameChannel.postMessage(JSON.stringify(data));
            } catch (e) {}
            if (originalPostMessage) {
              try { originalPostMessage.call(window.parent, data, target); } catch (e) {}
            }
          };
        } catch (e) {}
      })();
    ''');
  }

  void _onGameMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['type'] != widget.config.messageType) return;
      final points = (data['points'] as num?)?.toInt() ?? 0;
      final durationMs = (data['durationMs'] as num?)?.toInt() ?? 0;
      _onScore(points, durationMs);
    } catch (_) {
    }
  }

  void _onScore(int points, int durationMs) {
    final sane = points > 0 &&
        points <= _maxPoints &&
        durationMs >= _minDurationMs;
    final session = ref.read(sessionProvider).valueOrNull;
    final loggedIn = session != null && !session.isGuest;
    final coins = points ~/ _pointsPerCoin;

    setState(() {
      _points = points;
      if (!sane) {
        _coins = null;
        _note = 'Skor tidak wajar. Mainkan gamenya sampai selesai ya.';
      } else if (!loggedIn) {
        _coins = coins;
        _note = 'Login/daftar dulu untuk klaim koinmu.';
      } else if (coins <= 0) {
        _coins = 0;
        _note = 'Belum cukup untuk 1 koin (butuh 1000 poin).';
      } else {
        _coins = coins;
        _note = 'Maksimal $_maxCoinsPerDay koin/hari dari game.';
      }
      _claimed = false;
    });
  }

  Future<void> _klaim() async {
    final coins = _coins;
    final points = _points;
    if (coins == null || coins <= 0 || points == null || _busy) return;
    final session = ref.read(sessionProvider).valueOrNull;
    final uid = session != null && !session.isGuest ? session.user?.uid : null;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      final result =
          await ref.read(socialRepositoryProvider).grantGameCoins(
                uid,
                coins,
                points: points,
                reason: widget.config.reason,
                label: widget.config.label,
                dateField: widget.config.dateField,
                todayField: widget.config.todayField,
                eventKey: widget.config.id == 'tangkap_diskon'
                    ? 'tangkapDiskon'
                    : 'buruDiskon',
              );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _claimed = true;
      });
      final messenger = ScaffoldMessenger.of(context);
      if (result.granted > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '+${result.granted} Koin Warga'
              '${result.capped ? ' (batas $_maxCoinsPerDay/hari tercapai)' : ''}',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Batas $_maxCoinsPerDay koin game hari ini sudah tercapai'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.butuhInternetUmum)),
      );
    }
  }

  void _mainLagi() {
    setState(() {
      _points = null;
      _coins = null;
      _note = null;
      _claimed = false;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final loggedIn = session != null && !session.isGuest;
    final showPanel = _points != null && !_claimed;
    final canClaim =
        _coins != null && _coins! > 0 && loggedIn && !_busy && !_claimed;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          if (showPanel)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.permukaanKartu,
                border: Border(top: BorderSide(color: context.garis)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_points!.toString()} poin',
                    style: TextStyle(
                      color: context.teksUtama,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _coins != null && _coins! > 0
                        ? '= ${_coins!} koin'
                        : (_note ?? ''),
                    style: TextStyle(
                      color: context.teksRedup,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_note != null &&
                      (_coins == null || _coins! <= 0 || !loggedIn))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _note!,
                        style: TextStyle(
                          color: context.teksRedup,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Main Lagi',
                          onPressed: _mainLagi,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: _busy
                              ? '...'
                              : 'Klaim +${_coins ?? 0} koin',
                          onPressed: canClaim ? _klaim : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
