/// User-editable constants for The Kinetic Ledger physics system.
library;

enum GravityPreset {
  zero('Zero-G', 0.0),
  moon('Moon', 1.6),
  earth('Earth', 9.8),
  jupiter('Jupiter', 24.8);

  final String label;
  final double ms2;
  const GravityPreset(this.label, this.ms2);
}

class PhysicsSettings {
  /// Singleton instance
  static final PhysicsSettings instance = PhysicsSettings._();
  PhysicsSettings._();

  /// Current gravity preset
  GravityPreset gravityPreset = GravityPreset.earth;

  /// Bounciness / restitution coefficient (0.0 = no bounce, 1.0 = perfect bounce)
  double restitution = 0.4;

  /// Friction coefficient (0.0 = frictionless, 1.0 = very sticky)
  double friction = 0.5;

  /// Base mass added to every message body
  double baseMass = 1.0;

  /// Mass added per character in the message
  double massPerChar = 0.1;

  /// Mass added per MB of attachment
  double massPerMB = 5.0;

  /// Velocity threshold (m/s in physics units) above which Word Shatter triggers
  double wordShatterThreshold = 18.0;

  /// Whether Word Shatter mode is enabled
  bool wordShatterEnabled = true;

  /// Reaction impulse magnitude for 💥/🔥 reactions
  double reactionImpulseMagnitude = 12.0;

  /// Number of reactions required to "anchor" a message (increase mass significantly)
  int anchorReactionCount = 20;

  /// Pixels-per-meter scale for the physics world
  double pixelsPerMeter = 50.0;

  /// Computes mass for a given message
  double computeMass({
    required int charCount,
    double attachmentSizeMB = 0.0,
  }) {
    return baseMass + (charCount * massPerChar) + (attachmentSizeMB * massPerMB);
  }

  double get gravityMs2 => gravityPreset.ms2;
}
