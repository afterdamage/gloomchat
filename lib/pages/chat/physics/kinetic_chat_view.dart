/// The Kinetic Ledger — physics-based chat renderer.
///
/// Renders message bubbles as physics bodies in a [Stack].
/// Supports:
///   - Drag-to-fling gestures
///   - Accelerometer-driven gravity tilt
///   - Shake detection → Big Shake
///   - Reaction impulses
///   - Word Shatter rendering
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forge2d/forge2d.dart' show Vector2;
import 'package:matrix/matrix.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'kinetic_world.dart';
import 'message_body.dart';
import 'physics_settings.dart';

/// Wraps the physics world and provides a full-screen [Stack] renderer.
class KineticChatView extends StatefulWidget {
  const KineticChatView({
    super.key,
    required this.events,
    required this.onToggleLock,
    this.isLocked = false,
  });

  /// The list of Matrix events to render as physics bodies.
  final List<Event> events;

  /// Called when the user taps the gravity-lock toggle.
  final VoidCallback onToggleLock;

  /// When true, physics is paused and messages render as a normal list.
  final bool isLocked;

  @override
  State<KineticChatView> createState() => _KineticChatViewState();
}

class _KineticChatViewState extends State<KineticChatView>
    with SingleTickerProviderStateMixin {
  KineticWorld? _world;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Shake detection
  static const double _shakeThreshold = 25.0;
  static const Duration _shakeCooldown = Duration(seconds: 2);
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  // Drag state
  String? _draggingEventId;

  // Track which events are already spawned
  final Set<String> _spawnedIds = {};

  @override
  void initState() {
    super.initState();
    if (!widget.isLocked) {
      _initWorld();
    }
  }

  @override
  void didUpdateWidget(KineticChatView old) {
    super.didUpdateWidget(old);
    if (old.isLocked != widget.isLocked) {
      if (widget.isLocked) {
        _destroyWorld();
      } else {
        _initWorld();
      }
    }
    if (!widget.isLocked && _world != null) {
      _syncEvents();
    }
  }

  void _initWorld() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      final world = KineticWorld(
        worldWidth: size.width,
        worldHeight: size.height,
        onStep: () {
          if (mounted) setState(() {});
        },
      );
      setState(() => _world = world);
      world.start();
      _syncEvents();
      _startAccelerometer();
    });
  }

  void _destroyWorld() {
    _accelSub?.cancel();
    _accelSub = null;
    _world?.dispose();
    _world = null;
    _spawnedIds.clear();
  }

  void _startAccelerometer() {
    // Accelerometer not available on web
    if (kIsWeb) return;
    _accelSub = accelerometerEventStream().listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final world = _world;
    if (world == null) return;

    // Tilt gravity
    world.updateGravityFromAccelerometer(event.x, -event.y);

    // Shake detection
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude > _shakeThreshold) {
      final now = DateTime.now();
      if (now.difference(_lastShake) > _shakeCooldown) {
        _lastShake = now;
        world.bigShake();
      }
    }
  }

  void _syncEvents() {
    final world = _world;
    if (world == null) return;

    for (final event in widget.events) {
      if (_spawnedIds.contains(event.eventId)) continue;
      if (event.type != EventTypes.Message) continue;

      final text = event.body ?? '';
      final charCount = text.length;
      // Estimate bubble size from text length
      final bubbleWidth = (charCount * 8.0).clamp(80.0, 280.0);
      final bubbleHeight = (charCount / 30 * 20.0 + 48.0).clamp(48.0, 200.0);

      // Attachment size estimation
      double attachMB = 0.0;
      final info = event.content['info'];
      if (info is Map) {
        final size = info['size'];
        if (size is int) attachMB = size / (1024 * 1024);
      }

      // Reaction count — count relation events from the event's unsigned data
      final unsigned = event.unsigned;
      final relations = unsigned?['m.relations'];
      int reactionCount = 0;
      if (relations is Map) {
        final reactionData = relations['m.annotation'];
        if (reactionData is Map) {
          final count = reactionData['count'];
          if (count is int) reactionCount = count;
        }
      }

      world.spawnMessage(
        eventId: event.eventId,
        text: text,
        bubbleWidth: bubbleWidth,
        bubbleHeight: bubbleHeight,
        attachmentSizeMB: attachMB,
        reactionCount: reactionCount,
      );
      _spawnedIds.add(event.eventId);
    }
  }

  @override
  void dispose() {
    _destroyWorld();
    super.dispose();
  }

  // ── Drag / fling ─────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, String eventId) {
    setState(() {
      _draggingEventId = eventId;
    });
    // Freeze the body while dragging
    final mb = _world?.messageBodies.firstWhere(
      (m) => m.eventId == eventId,
      orElse: () => throw StateError(''),
    );
    mb?.body.linearVelocity = Vector2.zero();
    mb?.body.angularVelocity = 0;
    mb?.isDragging = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingEventId == null) return;

    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final mb = _world?.messageBodies.firstWhere(
      (m) => m.eventId == _draggingEventId,
      orElse: () => throw StateError(''),
    );
    if (mb == null) return;
    final pos = details.globalPosition;
    mb.body.setTransform(
      Vector2(pos.dx / ppm, pos.dy / ppm),
      mb.body.angle,
    );
    mb.body.linearVelocity = Vector2.zero();
  }

  void _onPanEnd(DragEndDetails details) {
    final eventId = _draggingEventId;
    if (eventId == null) return;

    final mb = _world?.messageBodies.firstWhere(
      (m) => m.eventId == eventId,
      orElse: () => throw StateError(''),
    );
    mb?.isDragging = false;

    // Convert fling velocity to physics units
    final vel = details.velocity.pixelsPerSecond;
    try {
      _world?.flingMessage(
        eventId,
        Vector2(vel.dx, vel.dy),
      );
    } catch (_) {}

    setState(() {
      _draggingEventId = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final world = _world;

    if (widget.isLocked || world == null) {
      return _buildLockedPlaceholder(theme);
    }

    final size = MediaQuery.sizeOf(context);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background
          Container(
            color: theme.colorScheme.surface.withOpacity(0.95),
          ),

          // Shattered word tokens
          for (final entry in world.shatteredMessages.entries)
            for (final token in entry.value)
              Positioned(
                left: token.screenX - 30,
                top: token.screenY - 12,
                child: Transform.rotate(
                  angle: token.body.angle,
                  child: _WordTokenWidget(word: token.word, theme: theme),
                ),
              ),

          // Message bubbles
          for (final mb in world.messageBodies)
            if (!mb.shattered)
              Positioned(
                left: mb.left(ppm),
                top: mb.top(ppm),
                child: GestureDetector(
                  onPanStart: (d) => _onPanStart(d, mb.eventId),
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Transform.rotate(
                    angle: mb.body.angle,
                    child: _PhysicsBubble(
                      mb: mb,
                      theme: theme,
                    ),
                  ),
                ),
              ),

          // Gravity lock toggle button
          Positioned(
            bottom: 80,
            right: 16,
            child: _GravityLockButton(
              isLocked: widget.isLocked,
              onTap: widget.onToggleLock,
              theme: theme,
            ),
          ),

          // Shake hint (mobile only)
          if (!kIsWeb)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withOpacity(
                      0.8,
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '📳 Shake to scatter  •  Drag to fling',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedPlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Physics locked\nTap 🎱 to unleash chaos',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PhysicsBubble extends StatelessWidget {
  const _PhysicsBubble({required this.mb, required this.theme});

  final MessageBody mb;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isAnchor = mb.isAnchor;
    final color = isAnchor
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.primaryContainer;
    final borderColor = isAnchor
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      width: mb.bubbleWidth,
      height: mb.bubbleHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: borderColor, width: isAnchor ? 2.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              mb.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isAnchor)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '⚓ anchored',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WordTokenWidget extends StatelessWidget {
  const _WordTokenWidget({required this.word, required this.theme});

  final String word;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.5),
        ),
      ),
      child: Text(
        word,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GravityLockButton extends StatelessWidget {
  const _GravityLockButton({
    required this.isLocked,
    required this.onTap,
    required this.theme,
  });

  final bool isLocked;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: isLocked
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.primaryContainer,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.bowlingBall,
            color: isLocked
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
