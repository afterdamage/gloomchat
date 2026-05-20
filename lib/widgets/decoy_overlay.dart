import 'package:afterdamage/widgets/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A convincing fake calculator shown when Decoy Mode is active and the app
/// is locked.  Entering the 4-digit PIN and pressing [=] unlocks the app.
class DecoyOverlay extends StatefulWidget {
  const DecoyOverlay({super.key});

  @override
  State<DecoyOverlay> createState() => _DecoyOverlayState();
}

class _DecoyOverlayState extends State<DecoyOverlay> {
  // ── display state ──────────────────────────────────────────────────────────
  String _display = '0';
  String _input = '';
  double? _operand;
  String? _pendingOp;
  bool _afterEval = false;

  // ── calculator logic ───────────────────────────────────────────────────────

  void _digit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_afterEval) {
        _input = d;
        _afterEval = false;
      } else {
        _input = (_input == '0' || _input.isEmpty) ? d : _input + d;
        if (_input.length > 12) _input = _input.substring(_input.length - 12);
      }
      _display = _input;
    });
  }

  void _decimal() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_afterEval) {
        _input = '0.';
        _afterEval = false;
      } else if (!_input.contains('.')) {
        _input = _input.isEmpty ? '0.' : '$_input.';
      }
      _display = _input;
    });
  }

  void _pressOperator(String op) {
    HapticFeedback.selectionClick();
    setState(() {
      _operand = double.tryParse(_input) ?? _operand ?? 0;
      _pendingOp = op;
      _input = '';
      _afterEval = false;
      _display = op;
    });
  }

  void _equals() {
    HapticFeedback.mediumImpact();
    // Try PIN unlock — use the raw digit string so "1234" matches "1234"
    final pin = _input.replaceAll('.', '').replaceAll('-', '');
    if (pin.length == 4 && AppLock.of(context).unlock(_input)) {
      return; // AppLock rebuilds without the overlay
    }
    // Normal calculator evaluation
    setState(() {
      if (_operand != null && _pendingOp != null && _input.isNotEmpty) {
        final b = double.tryParse(_input) ?? 0;
        final double result;
        switch (_pendingOp) {
          case '+':
            result = _operand! + b;
          case '−':
            result = _operand! - b;
          case '×':
            result = _operand! * b;
          case '÷':
            result = b != 0 ? _operand! / b : double.infinity;
          default:
            result = b;
        }
        _display = _formatResult(result);
      } else {
        _display = _input.isEmpty ? '0' : _input;
      }
      _operand = null;
      _pendingOp = null;
      _input = '';
      _afterEval = true;
    });
  }

  void _toggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      final v = double.tryParse(_input);
      if (v == null) return;
      _input = _formatResult(-v);
      _display = _input;
    });
  }

  void _percent() {
    HapticFeedback.selectionClick();
    setState(() {
      final v = double.tryParse(_input);
      if (v == null) return;
      _input = _formatResult(v / 100);
      _display = _input;
    });
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _display = '0';
      _input = '';
      _operand = null;
      _pendingOp = null;
      _afterEval = false;
    });
  }

  String _formatResult(double v) {
    if (v == double.infinity || v.isNaN) return 'Error';
    if (v == v.floorToDouble() && v.abs() < 1e12) return v.toInt().toString();
    return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: _Display(text: _display),
            ),
            const Divider(height: 1, color: Color(0xFF3A3A3C)),
            Expanded(
              flex: 7,
              child: _ButtonGrid(
                onDigit: _digit,
                onDecimal: _decimal,
                onOperator: _pressOperator,
                onEquals: _equals,
                onClear: _clear,
                onToggleSign: _toggleSign,
                onPercent: _percent,
                displayText: _display,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Display ───────────────────────────────────────────────────────────────────

class _Display extends StatelessWidget {
  final String text;
  const _Display({required this.text});

  @override
  Widget build(BuildContext context) {
    final fontSize = text.length > 9 ? 36.0 : text.length > 6 ? 48.0 : 64.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w200,
              fontFamily: 'sans-serif-light',
              letterSpacing: -1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Button grid ───────────────────────────────────────────────────────────────

class _ButtonGrid extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDecimal;
  final void Function(String) onOperator;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onToggleSign;
  final VoidCallback onPercent;
  final String displayText;

  const _ButtonGrid({
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onEquals,
    required this.onClear,
    required this.onToggleSign,
    required this.onPercent,
    required this.displayText,
  });

  static const _orange = Color(0xFFFF9500);
  static const _dark   = Color(0xFF3A3A3C);
  static const _gray   = Color(0xFF636366);

  @override
  Widget build(BuildContext context) {
    final clearLabel = displayText != '0' ? 'C' : 'AC';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          // Row 1: AC/C  +/-  %  ÷
          _Row(children: [
            _Btn(label: clearLabel, bg: _gray,   fg: Colors.black, onTap: onClear),
            _Btn(label: '+/−',       bg: _gray,   fg: Colors.black, onTap: onToggleSign),
            _Btn(label: '%',         bg: _gray,   fg: Colors.black, onTap: onPercent),
            _Btn(label: '÷',         bg: _orange, fg: Colors.white, onTap: () => onOperator('÷')),
          ]),
          // Row 2: 7 8 9 ×
          _Row(children: [
            _Btn(label: '7', bg: _dark, fg: Colors.white, onTap: () => onDigit('7')),
            _Btn(label: '8', bg: _dark, fg: Colors.white, onTap: () => onDigit('8')),
            _Btn(label: '9', bg: _dark, fg: Colors.white, onTap: () => onDigit('9')),
            _Btn(label: '×', bg: _orange, fg: Colors.white, onTap: () => onOperator('×')),
          ]),
          // Row 3: 4 5 6 −
          _Row(children: [
            _Btn(label: '4', bg: _dark, fg: Colors.white, onTap: () => onDigit('4')),
            _Btn(label: '5', bg: _dark, fg: Colors.white, onTap: () => onDigit('5')),
            _Btn(label: '6', bg: _dark, fg: Colors.white, onTap: () => onDigit('6')),
            _Btn(label: '−', bg: _orange, fg: Colors.white, onTap: () => onOperator('−')),
          ]),
          // Row 4: 1 2 3 +
          _Row(children: [
            _Btn(label: '1', bg: _dark, fg: Colors.white, onTap: () => onDigit('1')),
            _Btn(label: '2', bg: _dark, fg: Colors.white, onTap: () => onDigit('2')),
            _Btn(label: '3', bg: _dark, fg: Colors.white, onTap: () => onDigit('3')),
            _Btn(label: '+', bg: _orange, fg: Colors.white, onTap: () => onOperator('+')),
          ]),
          // Row 5: 0 (wide)  .  =
          _Row(children: [
            _Btn(label: '0', bg: _dark, fg: Colors.white, wide: true, onTap: () => onDigit('0')),
            _Btn(label: '.', bg: _dark,   fg: Colors.white, onTap: onDecimal),
            _Btn(label: '=', bg: _orange, fg: Colors.white, onTap: onEquals),
          ]),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> children;
  const _Row({required this.children});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool wide;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        splashColor: Colors.white24,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );

    if (wide) {
      return Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(3), child: child));
    }
    return Expanded(child: Padding(padding: const EdgeInsets.all(3), child: child));
  }
}
