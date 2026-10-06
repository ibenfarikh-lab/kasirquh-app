import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/strings_id.dart';

/// Sheet Kalkulator: panel tugas cepat Mode Admin (bottom sheet).
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _current = '0';
  double? _prev;
  String? _op; // internal: '+' '-' '*' '/'

  void _input(String d) {
    setState(() {
      if (_current == Strings.galat) {
        _current = d == '.' ? '0.' : d;
        return;
      }
      if (d == '.') {
        if (_current.contains('.')) return;
        _current = '$_current.';
        return;
      }
      if (_current.replaceAll('.', '').length >= 12) return;
      if (_current == '0') {
        _current = d == '00' ? '0' : d;
      } else {
        _current = '$_current$d';
      }
    });
  }

  double? _compute(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        return b == 0 ? null : a / b;
    }
    return null;
  }

  /// Hilangkan .0: bulat tampil sebagai int.
  String _format(double v) {
    if (v.isInfinite || v.isNaN) return Strings.galat;
    if (v == v.truncateToDouble()) return v.toInt().toString();
    var s = v.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  String _displayOp(String op) => switch (op) {
        '+' => '+',
        '-' => '−',
        '*' => '×',
        '/' => '÷',
        _ => op,
      };

  void _setOp(String op) {
    HapticFeedback.selectionClick();
    setState(() {
      final cur = double.tryParse(_current) ?? 0;
      if (_op != null && _prev != null) {
        final r = _compute(_prev!, _op!, cur);
        if (r == null) {
          _current = Strings.galat;
          _prev = null;
          _op = null;
          return;
        }
        _prev = r;
      } else {
        _prev = cur;
      }
      _op = op;
      _current = '0';
    });
  }

  void _equals() {
    if (_op == null || _prev == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      final cur = double.tryParse(_current) ?? 0;
      final r = _compute(_prev!, _op!, cur);
      _current = r == null ? Strings.galat : _format(r);
      _prev = null;
      _op = null;
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _current = '0';
      _prev = null;
      _op = null;
    });
  }

  void _backspace() {
    setState(() {
      if (_current == Strings.galat || _current.length <= 1) {
        _current = '0';
      } else {
        _current = _current.substring(0, _current.length - 1);
        if (_current == '-') _current = '0';
      }
    });
  }

  void _percent() {
    setState(() {
      final v = double.tryParse(_current);
      if (v != null) _current = _format(v / 100);
    });
  }

  void _press(String label) {
    switch (label) {
      case 'C':
        _clear();
      case '⌫':
        _backspace();
      case '%':
        _percent();
      case '=':
        _equals();
      case '÷':
        _setOp('/');
      case '×':
        _setOp('*');
      case '−':
        _setOp('-');
      case '+':
        _setOp('+');
      default:
        _input(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.adminLine,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  Strings.modulKalkulator,
                  style: TextStyle(
                    color: AppColors.warmText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: Strings.tutup,
                icon: const Icon(Icons.close, color: AppColors.warmMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.adminBg,
              borderRadius: BorderRadius.circular(16),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_op != null && _prev != null)
                  Text(
                    '${_format(_prev!)} ${_displayOp(_op!)}',
                    style: const TextStyle(
                      color: AppColors.warmMuted,
                      fontSize: 15,
                    ),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _current,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.warmText,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final row in const [
            ['C', '⌫', '%', '÷'],
            ['7', '8', '9', '×'],
            ['4', '5', '6', '−'],
            ['1', '2', '3', '+'],
            ['0', '00', '.', '='],
          ])
            Row(
              children: row.map((l) => _CalcButton(label: l, onTap: () => _press(l))).toList(),
            ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CalcButton({required this.label, required this.onTap});

  bool get _isOp => label == '÷' || label == '×' || label == '−' || label == '+' || label == '=';

  @override
  Widget build(BuildContext context) {
    final isClear = label == 'C';
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        height: 56,
        child: Material(
          color: isClear
              ? AppColors.danger
              : _isOp
                  ? AppColors.orange
                  : AppColors.panel2,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isClear || _isOp
                      ? Colors.white
                      : AppColors.warmText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
