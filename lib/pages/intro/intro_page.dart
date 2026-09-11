import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/intro/flows/restore_backup_flow.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

// ── Dracula palette ──────────────────────────────────────────────────────────
const _kSurface = Color(0xFF44475a);
const _kFg     = Color(0xFFf8f8f2);
const _kMuted  = Color(0xFF6272a4);
const _kRed    = Color(0xFFff5555);
const _kGreen  = Color(0xFF50fa7b);

class IntroPage extends StatelessWidget {
  final bool isLoading, hasPresetHomeserver;
  final String? loggingInToHomeserver, welcomeText;
  final VoidCallback login;

  const IntroPage({
    required this.isLoading,
    required this.loggingInToHomeserver,
    super.key,
    required this.hasPresetHomeserver,
    required this.welcomeText,
    required this.login,
  });

  @override
  Widget build(BuildContext context) {
    final addMultiAccount = Matrix.of(
      context,
    ).widget.clients.any((c) => c.isLogged());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Color(0xCC1e2029),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const _GloomChatLogo(),
        centerTitle: false,
        actions: [
          PopupMenuButton(
            useRootNavigator: true,
            icon: const Icon(Icons.more_vert, color: _kMuted),
            color: _kSurface,
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: isLoading ? null : () => restoreBackupFlow(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.import_export_outlined, color: _kMuted),
                  const SizedBox(width: 12),
                  Text(
                    L10n.of(context).hydrate,
                    style: const TextStyle(color: _kFg, fontFamily: 'FreeMono'),
                  ),
                ]),
              ),
              PopupMenuItem(
                onTap: () => launchUrlString(AppSettings.privacyPolicy.value),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.privacy_tip_outlined, color: _kMuted),
                  const SizedBox(width: 12),
                  Text(
                    L10n.of(context).privacy,
                    style: const TextStyle(color: _kFg, fontFamily: 'FreeMono'),
                  ),
                ]),
              ),
              PopupMenuItem(
                onTap: () => PlatformInfos.showDialog(context),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.info_outlined, color: _kMuted),
                  const SizedBox(width: 12),
                  Text(
                    L10n.of(context).about,
                    style: const TextStyle(color: _kFg, fontFamily: 'FreeMono'),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _RuneRain()),
          const Positioned.fill(child: _ScanlineOverlay()),
          isLoading
              ? _LoadingView(loggingInToHomeserver: loggingInToHomeserver)
              : _HeroContent(
                  hasPresetHomeserver: hasPresetHomeserver,
                  welcomeText: welcomeText,
                  login: login,
                  addMultiAccount: addMultiAccount,
                ),
        ],
      ),
    );
  }
}

// ── GloomChat logo ───────────────────────────────────────────────────────────
class _GloomChatLogo extends StatelessWidget {
  const _GloomChatLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Gloom',
          style: TextStyle(
            color: _kFg,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Chat',
          style: TextStyle(
            color: _kRed,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Scanline overlay ─────────────────────────────────────────────────────────
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

// ── Loading view ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final String? loggingInToHomeserver;
  const _LoadingView({this.loggingInToHomeserver});

  @override
  Widget build(BuildContext context) {
    final host = loggingInToHomeserver;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          if (host != null) ...[
            const SizedBox(height: 16),
            Text(
              L10n.of(context).logInTo(host),
              style: const TextStyle(
                color: _kMuted,
                fontFamily: 'FreeMono',
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hero content ─────────────────────────────────────────────────────────────
class _HeroContent extends StatelessWidget {
  final bool hasPresetHomeserver;
  final bool addMultiAccount;
  final String? welcomeText;
  final VoidCallback login;

  const _HeroContent({
    required this.hasPresetHomeserver,
    required this.addMultiAccount,
    required this.welcomeText,
    required this.login,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.paddingOf(context).top + 72,
          24,
          48,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _EyebrowBadge(),
              const SizedBox(height: 32),
              Image.asset(
                'assets/banner_transparent.png',
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome to the sanctuary.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kMuted,
                  fontFamily: 'FreeMono',
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hasPresetHomeserver) ...[
                      _GlowButton(
                        label: 'CREATE ACCOUNT',
                        color: accent,
                        onPressed: () => context.go(
                          '${GoRouterState.of(context).uri.path}/sign_up',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _OutlineButton(
                      label: 'SIGN IN',
                      color: accent,
                      onPressed: login,
                    ),
                    if (!hasPresetHomeserver) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final client = await Matrix.of(context).getLoginClient();
                          context.go(
                            '${GoRouterState.of(context).uri.path}/login',
                            extra: client,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kMuted,
                          side: const BorderSide(color: _kMuted, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          textStyle: const TextStyle(
                            fontFamily: 'FreeMono',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        child: Text(L10n.of(context).loginWithMatrixId.toUpperCase()),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Eyebrow badge ─────────────────────────────────────────────────────────────
class _EyebrowBadge extends StatefulWidget {
  const _EyebrowBadge();

  @override
  State<_EyebrowBadge> createState() => _EyebrowBadgeState();
}

class _EyebrowBadgeState extends State<_EyebrowBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: _kGreen.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _ctrl,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MATRIX-POWERED  ·  DECENTRALIZED',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: _kGreen,
                fontFamily: 'FreeMono',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Red glow button ───────────────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _GlowButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'FreeMono',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

// ── Purple outline button ─────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _OutlineButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(
          fontFamily: 'FreeMono',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
      child: Text(label),
    );
  }
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
