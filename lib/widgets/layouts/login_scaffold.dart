import 'dart:math' as math;

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? bottomNavigationBar;

  const LoginScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileMode = !GloomThemes.isColumnModeByWidth(
          constraints.maxWidth,
        );

        final surface = Theme.of(context).colorScheme.surface;

        if (isMobileMode) {
          return Scaffold(
            key: const Key('LoginScaffold'),
            backgroundColor: surface,
            extendBodyBehindAppBar: true,
            appBar: appBar,
            body: Stack(
              children: [
                const Positioned.fill(child: _RuneRain()),
                const Positioned.fill(child: _ScanlineOverlay()),
                SafeArea(child: body),
              ],
            ),
            bottomNavigationBar: bottomNavigationBar,
          );
        }

        return Container(
          color: surface,
          child: Stack(
            children: [
              const Positioned.fill(child: _RuneRain()),
              const Positioned.fill(child: _ScanlineOverlay()),
              Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Material(
                          color: surface,
                          borderRadius: BorderRadius.zero,
                          clipBehavior: Clip.hardEdge,
                          elevation: Theme.of(context).appBarTheme.scrolledUnderElevation ?? 4,
                          shadowColor: Theme.of(context).appBarTheme.shadowColor,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 480,
                              maxHeight: 640,
                            ),
                            child: Scaffold(
                              key: const Key('LoginScaffold'),
                              backgroundColor: Colors.transparent,
                              appBar: appBar,
                              body: SafeArea(child: body),
                              bottomNavigationBar: bottomNavigationBar,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const _PrivacyButtons(mainAxisAlignment: MainAxisAlignment.center),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrivacyButtons extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  const _PrivacyButtons({required this.mainAxisAlignment});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Color(0xFF6272a4));
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            TextButton(
              onPressed: () => launchUrlString(AppSettings.website.value),
              child: Text(L10n.of(context).website, style: style),
            ),
            TextButton(
              onPressed: () => launchUrlString(AppConfig.supportUrl),
              child: Text(L10n.of(context).help, style: style),
            ),
            TextButton(
              onPressed: () => launchUrlString(AppSettings.privacyPolicy.value),
              child: Text(L10n.of(context).privacy, style: style),
            ),
            TextButton(
              onPressed: () => PlatformInfos.showDialog(context),
              child: Text(L10n.of(context).about, style: style),
            ),
          ],
        ),
      ),
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

  _RuneRainPainter({
    required this.columns,
    required this.frame,
    required this.accent,
  });

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
  bool shouldRepaint(_RuneRainPainter old) =>
      old.frame != frame || old.accent != accent;
}
