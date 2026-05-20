/// Represents a single message bubble as a Forge2D rigid body.
library;

import 'dart:math' as math;

import 'package:forge2d/forge2d.dart';

class MessageBody {
  MessageBody({
    required this.eventId,
    required this.text,
    required this.body,
    required this.bubbleWidth,
    required this.bubbleHeight,
    required this.mass,
    required bool isAnchor,
  }) : _isAnchor = isAnchor;

  /// The Matrix event ID this body represents
  final String eventId;

  /// The plain-text content of the message (used for Word Shatter)
  final String text;

  /// The Forge2D rigid body
  final Body body;

  /// Original bubble dimensions in screen pixels
  final double bubbleWidth;
  final double bubbleHeight;

  /// Computed mass
  final double mass;

  /// Whether this message has been "anchored" by 20+ reactions
  bool _isAnchor;
  bool get isAnchor => _isAnchor;
  set isAnchor(bool v) => _isAnchor = v;

  /// Whether this message has been shattered into word tokens
  bool shattered = false;

  /// Whether the user is currently dragging this bubble
  bool isDragging = false;

  // ── Convenience screen-space accessors ──────────────────────────────────

  /// Current screen X position (centre of bubble), given pixels-per-meter [ppm]
  double screenX(double ppm) => body.position.x * ppm;

  /// Current screen Y position (centre of bubble), given pixels-per-meter [ppm]
  double screenY(double ppm) => body.position.y * ppm;

  /// Current rotation in degrees
  double angleDeg() => body.angle * (180 / math.pi);

  /// Top-left screen position for use with [Positioned]
  double left(double ppm) => screenX(ppm) - bubbleWidth / 2;
  double top(double ppm) => screenY(ppm) - bubbleHeight / 2;

  /// Speed in physics units (m/s)
  double get speed => body.linearVelocity.length;

  @override
  String toString() =>
      'MessageBody($eventId, mass=$mass, anchor=$isAnchor, shattered=$shattered)';
}
