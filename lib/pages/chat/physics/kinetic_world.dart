/// The Kinetic Ledger — core physics world.
///
/// Wraps a Forge2D [World] and manages:
///   - Bounding walls (left, right, bottom, optional top)
///   - Gravity vector (updated by accelerometer or preset)
///   - Shake detection → random impulse on all bodies
///   - Step loop driven by a [Ticker]
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:forge2d/forge2d.dart';
import 'package:forge2d/src/settings.dart' as forge2d_settings;

import 'message_body.dart';
import 'physics_settings.dart';

class KineticWorld {
  KineticWorld({
    required this.worldWidth,
    required this.worldHeight,
    required this.onStep,
  }) {
    _world = World(Vector2(0, PhysicsSettings.instance.gravityMs2));
    _buildWalls();
    _ticker = Ticker(_tick);
  }

  /// Width of the physics world in pixels (screen width)
  final double worldWidth;

  /// Height of the physics world in pixels (screen height)
  final double worldHeight;

  /// Called every physics step so the UI can rebuild
  final VoidCallback onStep;

  late final World _world;
  late final Ticker _ticker;

  final List<MessageBody> messageBodies = [];

  bool _running = false;

  double _accumulator = 0.0;
  static const double _timeStep = 1 / 60;
  static const int _velocityIterations = 8;
  static const int _positionIterations = 3;

  Duration? _lastTime;

  // ── Wall bodies ──────────────────────────────────────────────────────────

  void _buildWalls() {
    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final w = worldWidth / ppm;
    final h = worldHeight / ppm;
    _addStaticEdge(Vector2(0, 0), Vector2(0, h)); // left
    _addStaticEdge(Vector2(w, 0), Vector2(w, h)); // right
    _addStaticEdge(Vector2(0, h), Vector2(w, h)); // bottom / floor
  }

  void _addStaticEdge(Vector2 a, Vector2 b) {
    final bodyDef = BodyDef()..type = BodyType.static;
    final body = _world.createBody(bodyDef);
    final shape = EdgeShape()..set(a, b);
    body.createFixtureFromShape(shape, density: 0.0);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  void start() {
    if (_running) return;
    _running = true;
    _ticker.start();
  }

  void stop() {
    if (!_running) return;
    _running = false;
    _ticker.stop();
    _lastTime = null;
  }

  void dispose() {
    stop();
    _ticker.dispose();
  }

  // ── Step loop ────────────────────────────────────────────────────────────

  void _tick(Duration elapsed) {
    final last = _lastTime;
    _lastTime = elapsed;
    if (last == null) return;

    final dt = (elapsed - last).inMicroseconds / 1e6;
    _accumulator += dt.clamp(0.0, 0.1); // cap at 100 ms to avoid spiral

    // Set global forge2d iteration settings before stepping
    forge2d_settings.velocityIterations = _velocityIterations;
    forge2d_settings.positionIterations = _positionIterations;

    while (_accumulator >= _timeStep) {
      _world.stepDt(_timeStep);
      _accumulator -= _timeStep;
    }

    // Check for word-shatter collisions
    _checkShatter();

    onStep();
  }

  // ── Gravity ──────────────────────────────────────────────────────────────

  /// Update gravity from accelerometer data.
  /// [x] and [y] are in m/s² (device axes).
  void updateGravityFromAccelerometer(double x, double y) {
    // On a phone lying flat, gravity is ~9.8 on Z axis.
    // When tilted, X/Y axes pick up the component.
    // We map device X → world X, device Y → world Y (inverted for screen coords).
    final magnitude = PhysicsSettings.instance.gravityMs2;
    // Normalise the tilt vector and scale to the preset magnitude
    final len = math.sqrt(x * x + y * y);
    if (len < 0.5) {
      // Nearly flat — use straight down
      _world.gravity = Vector2(0, magnitude);
    } else {
      final nx = x / len;
      final ny = y / len;
      _world.gravity = Vector2(nx * magnitude, ny * magnitude);
    }
  }

  /// Apply the currently selected preset gravity (straight down).
  void applyPresetGravity() {
    _world.gravity = Vector2(0, PhysicsSettings.instance.gravityMs2);
  }

  // ── Message bodies ───────────────────────────────────────────────────────

  /// Spawn a new message bubble at the top of the world.
  MessageBody spawnMessage({
    required String eventId,
    required String text,
    required double bubbleWidth,
    required double bubbleHeight,
    double attachmentSizeMB = 0.0,
    int reactionCount = 0,
  }) {
    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final settings = PhysicsSettings.instance;

    final mass = settings.computeMass(
      charCount: text.length,
      attachmentSizeMB: attachmentSizeMB,
    );

    // Anchor heavy messages (20+ reactions)
    final isAnchor = reactionCount >= settings.anchorReactionCount;
    final effectiveMass = isAnchor ? mass * 10 : mass;

    final w = bubbleWidth / ppm;
    final h = bubbleHeight / ppm;
    final worldW = worldWidth / ppm;

    // Spawn near the top, horizontally centred with slight random offset
    final rng = math.Random();
    final spawnX = (worldW / 2) + (rng.nextDouble() - 0.5) * (worldW * 0.3);
    final spawnY = h / 2 + 0.1; // just below the top edge

    final bodyDef =
        BodyDef()
          ..type = BodyType.dynamic
          ..position = Vector2(spawnX, spawnY)
          ..linearDamping = 0.3
          ..angularDamping = 0.8;

    final body = _world.createBody(bodyDef);

    final shape = PolygonShape()..setAsBoxXY(w / 2, h / 2);

    final fixtureDef =
        FixtureDef(shape)
          ..density = effectiveMass / (w * h)
          ..restitution = settings.restitution
          ..friction = settings.friction;

    body.createFixture(fixtureDef);

    final mb = MessageBody(
      eventId: eventId,
      text: text,
      body: body,
      bubbleWidth: bubbleWidth,
      bubbleHeight: bubbleHeight,
      mass: effectiveMass,
      isAnchor: isAnchor,
    );

    messageBodies.add(mb);
    return mb;
  }

  /// Remove a message body from the world.
  void removeMessage(String eventId) {
    final idx = messageBodies.indexWhere((m) => m.eventId == eventId);
    if (idx == -1) return;
    final mb = messageBodies.removeAt(idx);
    _world.destroyBody(mb.body);
  }

  // ── Interactions ─────────────────────────────────────────────────────────

  /// Apply a random impulse to every body — the "Big Shake."
  void bigShake() {
    final rng = math.Random();
    for (final mb in messageBodies) {
      final impulse = Vector2(
        (rng.nextDouble() - 0.5) * 20,
        -(rng.nextDouble() * 15 + 5),
      );
      mb.body.applyLinearImpulse(impulse);
    }
  }

  /// Apply a radial impulse from [originPx] (screen pixels) outward.
  void applyRadialImpulse(Vector2 originPx, double magnitude) {
    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final origin = originPx / ppm;

    for (final mb in messageBodies) {
      final pos = mb.body.position;
      final delta = pos - origin;
      final dist = delta.length;
      if (dist < 0.01) continue;
      final falloff = (1.0 / (dist + 0.5)).clamp(0.0, 1.0);
      final impulse = delta.normalized() * magnitude * falloff;
      mb.body.applyLinearImpulse(impulse);
    }
  }

  /// Fling a specific message body with a velocity vector (screen pixels/s).
  void flingMessage(String eventId, Vector2 velocityPx) {
    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final mb = messageBodies.firstWhere(
      (m) => m.eventId == eventId,
      orElse: () => throw StateError('Message $eventId not found'),
    );
    mb.body.linearVelocity = velocityPx / ppm;
  }

  /// Update reaction count for a message — may increase mass or trigger impulse.
  void updateReactions(String eventId, int reactionCount, bool isExplosive) {
    final idx = messageBodies.indexWhere((m) => m.eventId == eventId);
    if (idx == -1) return;
    final mb = messageBodies[idx];

    if (reactionCount >= PhysicsSettings.instance.anchorReactionCount &&
        !mb.isAnchor) {
      // Become an anchor — increase density
      mb.isAnchor = true;
      // Re-create fixture with higher density
      final body = mb.body;
      final fixturesToRemove = List<Fixture>.from(body.fixtures);
      for (final fix in fixturesToRemove) {
        body.destroyFixture(fix);
      }
      final ppm = PhysicsSettings.instance.pixelsPerMeter;
      final w = mb.bubbleWidth / ppm;
      final h = mb.bubbleHeight / ppm;
      final shape = PolygonShape()..setAsBoxXY(w / 2, h / 2);
      final settings = PhysicsSettings.instance;
      final fixtureDef =
          FixtureDef(shape)
            ..density = (mb.mass * 10) / (w * h)
            ..restitution = settings.restitution
            ..friction = settings.friction;
      body.createFixture(fixtureDef);
      body.resetMassData();
    }

    if (isExplosive) {
      final ppm = PhysicsSettings.instance.pixelsPerMeter;
      final originPx = mb.body.position * ppm;
      applyRadialImpulse(
        originPx,
        PhysicsSettings.instance.reactionImpulseMagnitude,
      );
    }
  }

  // ── Word Shatter ─────────────────────────────────────────────────────────

  /// Messages that have shattered (eventId → list of word tokens)
  final Map<String, List<WordToken>> shatteredMessages = {};

  void _checkShatter() {
    if (!PhysicsSettings.instance.wordShatterEnabled) return;
    final threshold = PhysicsSettings.instance.wordShatterThreshold;
    final toShatter = <MessageBody>[];

    for (final mb in messageBodies) {
      if (mb.shattered) continue;
      final speed = mb.body.linearVelocity.length;
      if (speed >= threshold) {
        toShatter.add(mb);
      }
    }

    for (final mb in toShatter) {
      _shatterMessage(mb);
    }
  }

  void _shatterMessage(MessageBody mb) {
    mb.shattered = true;
    final words = mb.text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length <= 1) return;

    final ppm = PhysicsSettings.instance.pixelsPerMeter;
    final origin = mb.body.position.clone();
    final velocity = mb.body.linearVelocity.clone();
    final rng = math.Random();

    final tokens = <WordToken>[];
    for (final word in words) {
      final bodyDef =
          BodyDef()
            ..type = BodyType.dynamic
            ..position = origin.clone()
            ..linearDamping = 0.5
            ..angularDamping = 1.0;

      final body = _world.createBody(bodyDef);
      const tokenW = 0.6;
      const tokenH = 0.3;
      final shape = PolygonShape()..setAsBoxXY(tokenW / 2, tokenH / 2);
      final fixtureDef =
          FixtureDef(shape)
            ..density = 0.5
            ..restitution = 0.6
            ..friction = 0.3;
      body.createFixture(fixtureDef);

      // Scatter with random velocity based on original velocity + spread
      final scatter = Vector2(
        velocity.x + (rng.nextDouble() - 0.5) * 8,
        velocity.y + (rng.nextDouble() - 0.5) * 8,
      );
      body.linearVelocity = scatter;

      tokens.add(WordToken(word: word, body: body, ppm: ppm));
    }

    shatteredMessages[mb.eventId] = tokens;

    // Remove the original body
    _world.destroyBody(mb.body);
    messageBodies.remove(mb);
  }

  /// Clean up shattered word tokens
  void clearShatteredTokens(String eventId) {
    final tokens = shatteredMessages.remove(eventId);
    if (tokens == null) return;
    for (final t in tokens) {
      _world.destroyBody(t.body);
    }
  }
}

/// A single word token spawned by Word Shatter mode.
class WordToken {
  final String word;
  final Body body;
  final double ppm;

  const WordToken({
    required this.word,
    required this.body,
    required this.ppm,
  });

  /// Current screen-space position (top-left of the token)
  double get screenX => body.position.x * ppm;
  double get screenY => body.position.y * ppm;
  double get angleDeg => body.angle * (180 / math.pi);
}
