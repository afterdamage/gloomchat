import 'dart:math' as math;

import 'package:afterdamage/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'login.dart';

// ── Dracula palette ───────────────────────────────────────────────────────────
const _kSurface = Color(0xFF44475a);
const _kFg      = Color(0xFFf8f8f2);
const _kMuted   = Color(0xFF6272a4);
const _kRed     = Color(0xFFff5555);

class LoginView extends StatelessWidget {
  final LoginController controller;

  const LoginView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    final homeserver = controller.widget.client.homeserver
        ?.toString()
        .replaceFirst('https://', '');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xCC1e2029),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: controller.loading
            ? null
            : BackButton(color: _kMuted, onPressed: Navigator.of(context).pop),
        title: _GloomChatLogo(),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _RuneRain()),
          const Positioned.fill(child: _ScanlineOverlay()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section label
                        Text(
                          '// ENTER YOUR CREDENTIALS',
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'FreeMono',
                            fontSize: 10,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (homeserver != null)
                          Text(
                            homeserver,
                            style: const TextStyle(
                              color: _kMuted,
                              fontFamily: 'FreeMono',
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Matrix ID field
                        TextField(
                          readOnly: controller.loading,
                          autocorrect: false,
                          autofocus: true,
                          onChanged: controller.checkWellKnownWithCoolDown,
                          controller: controller.usernameController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: controller.loading
                              ? null
                              : [AutofillHints.username],
                          style: const TextStyle(
                            color: _kFg,
                            fontFamily: 'FreeMono',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _kSurface.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: _kMuted.withOpacity(0.4)),
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _kMuted.withOpacity(0.3)),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accent, width: 1.5),
                              borderRadius: BorderRadius.zero,
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: _kRed),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: _kRed, width: 1.5),
                              borderRadius: BorderRadius.zero,
                            ),
                            prefixIcon: const Icon(Icons.account_box_outlined, color: _kMuted),
                            errorText: controller.usernameError,
                            errorStyle: const TextStyle(color: _kRed, fontFamily: 'FreeMono', fontSize: 11),
                            hintText: '@username:domain',
                            hintStyle: const TextStyle(color: _kMuted, fontFamily: 'FreeMono', fontSize: 12),
                            labelText: L10n.of(context).matrixId,
                            labelStyle: const TextStyle(color: _kMuted, fontFamily: 'FreeMono'),
                            floatingLabelStyle: TextStyle(color: accent, fontFamily: 'FreeMono'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Password field
                        TextField(
                          readOnly: controller.loading,
                          autocorrect: false,
                          autofillHints: controller.loading
                              ? null
                              : [AutofillHints.password],
                          controller: controller.passwordController,
                          textInputAction: TextInputAction.go,
                          obscureText: !controller.showPassword,
                          onSubmitted: (_) => controller.login(),
                          style: const TextStyle(
                            color: _kFg,
                            fontFamily: 'FreeMono',
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _kSurface.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: _kMuted.withOpacity(0.4)),
                              borderRadius: BorderRadius.zero,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _kMuted.withOpacity(0.3)),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: accent, width: 1.5),
                              borderRadius: BorderRadius.zero,
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: _kRed),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: _kRed, width: 1.5),
                              borderRadius: BorderRadius.zero,
                            ),
                            prefixIcon: const Icon(Icons.lock_outlined, color: _kMuted),
                            errorText: controller.passwordError,
                            errorStyle: const TextStyle(color: _kRed, fontFamily: 'FreeMono', fontSize: 11),
                            suffixIcon: IconButton(
                              onPressed: controller.toggleShowPassword,
                              icon: Icon(
                                controller.showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _kMuted,
                              ),
                            ),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: _kMuted, fontFamily: 'FreeMono', fontSize: 12),
                            labelText: L10n.of(context).password,
                            labelStyle: const TextStyle(color: _kMuted, fontFamily: 'FreeMono'),
                            floatingLabelStyle: TextStyle(color: accent, fontFamily: 'FreeMono'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login button
                        DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: controller.loading
                                ? []
                                : [
                                    BoxShadow(
                                      color: accent.withOpacity(0.35),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                          ),
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: controller.loading ? null : controller.login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _kSurface,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontFamily: 'FreeMono',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                ),
                              ),
                              child: controller.loading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Text(L10n.of(context).login.toUpperCase()),
                            ),
                          ),
                        ),
                        if (homeserver != null) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: controller.loading ? null : controller.passwordForgotten,
                            child: Text(
                              L10n.of(context).passwordForgotten,
                              style: const TextStyle(
                                color: _kMuted,
                                fontFamily: 'FreeMono',
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── GloomChat logo ─────────────────────────────────────────────────────────────
class _GloomChatLogo extends StatelessWidget {
  const _GloomChatLogo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gloom',
          style: TextStyle(
            color: _kFg,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Chat',
          style: TextStyle(
            color: _kRed,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Scanline overlay ──────────────────────────────────────────────────────────
class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.06,
        child: CustomPaint(painter: _ScanlinePainter()),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter _) => false;
}

// ── Rune rain ─────────────────────────────────────────────────────────────────
class _RuneRain extends StatefulWidget {
  const _RuneRain();

  @override
  State<_RuneRain> createState() => _RuneRainState();
}

class _RuneRainState extends State<_RuneRain> with SingleTickerProviderStateMixin {
  static const _glyphs =
      'ᚠᚢᚦᚨᚱᚲᚷᚹᚺᚾᛁᛃᛇᛈᛉᛊᛏᛒᛗᛚᛜᛞᛟψ☿⛧☽⊗◈⸸⛤✠ꙮ♱⊕';
  static const _cell = 22.0;
  static const _tickMs = 90;

  late final Ticker _ticker;
  final _repaint = ValueNotifier<int>(0);
  int _lastMs = 0;
  final _rng = math.Random();
  List<_RuneColumn>? _columns;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration d) {
    final ms = d.inMilliseconds;
    if (ms - _lastMs >= _tickMs) {
      _lastMs = ms;
      _advanceDrops();
    }
  }

  void _advanceDrops() {
    final cols = _columns;
    if (cols == null) return;
    final rows = (_lastSize.height / _cell).ceil().toDouble();
    for (final col in cols) {
      col.position += col.speed;
      col.glyph = _glyphs[_rng.nextInt(_glyphs.length)];
      col.trail.insert(0, col.glyph);
      if (col.trail.length > 8) col.trail.removeLast();
      if (col.position > rows + 8) {
        col.position = -_rng.nextInt(10).toDouble();
        col.trail.clear();
      }
    }
    _repaint.value++;
  }

  void _initColumns(Size size) {
    if (size == _lastSize && _columns != null) return;
    _lastSize = size;
    final cols = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil();
    _columns = List.generate(
      cols,
      (i) => _RuneColumn(
        position: -_rng.nextInt(rows).toDouble(),
        speed: 0.5 + _rng.nextDouble() * 0.8,
        glyph: _glyphs[_rng.nextInt(_glyphs.length)],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _initColumns(constraints.biggest);
          return AnimatedBuilder(
            animation: _repaint,
            builder: (context, _) => CustomPaint(
              painter: _RuneRainPainter(
                columns: _columns!,
                frame: _repaint.value,
                accent: accent,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _RuneColumn {
  double position;
  final double speed;
  String glyph;
  final List<String> trail = [];

  _RuneColumn({
    required this.position,
    required this.speed,
    required this.glyph,
  });
}

class _RuneRainPainter extends CustomPainter {
  final List<_RuneColumn> columns;
  final int frame;
  final Color accent;
  static const _cell = 22.0;

  _RuneRainPainter({required this.columns, required this.frame, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      if (col.position < 0) continue;

      for (var t = 0; t < col.trail.length; t++) {
        final pos = col.position - t;
        if (pos < 0) continue;
        final y = pos * _cell;
        if (y > size.height) continue;

        final alpha = ((1.0 - t / col.trail.length) * 0.14 * 255).round();
        if (alpha <= 0) continue;

        final isAlt = (i + pos.floor()) % 3 == 0;
        final color = isAlt
            ? accent.withAlpha((alpha * 0.6).round())
            : accent.withAlpha(alpha);

        tp.text = TextSpan(
          text: t < col.trail.length ? col.trail[t] : col.glyph,
          style: TextStyle(color: color, fontSize: _cell - 6),
        );
        tp.layout();
        tp.paint(canvas, Offset(i * _cell, y));
      }
    }
  }

  @override
  bool shouldRepaint(_RuneRainPainter old) => old.frame != frame || old.accent != accent;
}
