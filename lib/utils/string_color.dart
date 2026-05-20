import 'package:flutter/material.dart';

/// Curated muted palette matching Dracula / Afterdamage aesthetic.
/// 20 hand-picked colors: deep burgundy, plum, slate, muted teal,
/// dusty olive, smoked amber, charcoal-tinted hues — no neon.
const List<Color> afterdamageAvatarPalette = [
  Color(0xFF6D2B3A), // deep burgundy
  Color(0xFF7B3F5E), // plum
  Color(0xFF4A3B5C), // dark violet
  Color(0xFF5B4A6E), // muted purple
  Color(0xFF3D4F6A), // slate blue
  Color(0xFF2C5F6E), // deep teal
  Color(0xFF3A6B5E), // muted teal
  Color(0xFF4E6B4A), // dusty olive
  Color(0xFF5C6644), // sage
  Color(0xFF7A6A3A), // smoked amber
  Color(0xFF8B5E3C), // warm brown
  Color(0xFF6B4F3D), // cocoa
  Color(0xFF5A3E3E), // rosewood
  Color(0xFF4B4453), // charcoal plum
  Color(0xFF3E4E4E), // dark slate
  Color(0xFF556B6B), // muted cyan-grey
  Color(0xFF6E5A6E), // mauve grey
  Color(0xFF5C4B4B), // smoky rose
  Color(0xFF3F5A5A), // deep sea
  Color(0xFF7A5C5C), // dusty rose
];

/// Stable FNV-1a–style 32-bit hash for deterministic palette selection.
/// No randomness, no runtime seed — identical output for identical input.
int _stableStringHash(String s) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Returns [Colors.white] or [Colors.black] depending on which gives
/// better contrast against [bg].  Uses WCAG relative luminance.
Color contrastForeground(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.4 ? Colors.black : Colors.white;
}

/// Soul-Mapping: each Latin letter maps to a pool of three arcane Unicode glyphs
/// drawn from the Gothic (4th c.), Elder Futhark Runic, and Old Italic scripts.
/// All three scripts are covered by the bundled Cardo font.
/// A deterministic hash of the full name string selects one entry from the pool,
/// so the same name always produces the same glyph.
const Map<String, List<String>> _soulCharPools = {
  'A': ['𐌰', 'ᚨ', '𐌀'], // Gothic a,    Runic ansuz,    Old Italic A
  'B': ['𐌱', 'ᛒ', '𐌁'], // Gothic b,    Runic berkanan, Old Italic BE
  'C': ['𐌺', 'ᚳ', '𐌂'], // Gothic k,    Runic cen (Anglo-Saxon C), Old Italic KE
  'D': ['𐌳', 'ᛞ', '𐌃'], // Gothic d,    Runic dagaz,    Old Italic DE
  'E': ['𐌴', 'ᛖ', '𐌄'], // Gothic e,    Runic ehwaz,    Old Italic E
  'F': ['𐍆', 'ᚠ', '𐌅'], // Gothic f,    Runic fehu,     Old Italic VE
  'G': ['𐌲', 'ᚷ', '𐌆'], // Gothic g,    Runic gebo,     Old Italic ZE
  'H': ['𐌷', 'ᚻ', '𐌇'], // Gothic h,    Runic hagalaz,  Old Italic HE
  'I': ['𐌹', 'ᛁ', '𐌉'], // Gothic i,    Runic isa,      Old Italic I
  'J': ['𐌾', 'ᛃ', '𐌊'], // Gothic j,    Runic jera,     Old Italic KA
  'K': ['𐌺', 'ᚲ', '𐌊'], // Gothic k,    Runic kenaz,    Old Italic KA
  'L': ['𐌻', 'ᛚ', '𐌋'], // Gothic l,    Runic laguz,    Old Italic EL
  'M': ['𐌼', 'ᛗ', '𐌌'], // Gothic m,    Runic mannaz,   Old Italic EM
  'N': ['𐌽', 'ᚾ', '𐌍'], // Gothic n,    Runic naudiz,   Old Italic EN
  'O': ['𐍉', 'ᛟ', '𐌏'], // Gothic o,    Runic othalan,  Old Italic O
  'P': ['𐍀', 'ᛈ', '𐌐'], // Gothic p,    Runic pertho,   Old Italic PE
  'Q': ['𐌵', 'ᚴ', '𐌒'], // Gothic q,    Runic (k-var),  Old Italic KU
  'R': ['𐍂', 'ᚱ', '𐌓'], // Gothic r,    Runic raido,    Old Italic ER
  'S': ['𐍃', 'ᛊ', '𐌔'], // Gothic s,    Runic sowilo,   Old Italic ES
  'T': ['𐍄', 'ᛏ', '𐌕'], // Gothic t,    Runic tiwaz,    Old Italic TE
  'U': ['𐌿', 'ᚢ', '𐌖'], // Gothic u,    Runic uruz,     Old Italic UPH
  'V': ['𐍅', 'ᚢ', '𐌅'], // Gothic w/v,  Runic uruz (V sound), Old Italic VE
  'W': ['𐍅', 'ᚹ', '𐌗'], // Gothic w,    Runic wunjo,    Old Italic EKS
  'X': ['𐍇', 'ᛉ', '𐌗'], // Gothic x,    Runic algiz,    Old Italic EKS
  'Y': ['𐌾', 'ᛇ', '𐌝'], // Gothic j/y,  Runic iwaz,     Old Italic II
  'Z': ['𐌶', 'ᛦ', '𐌙'], // Gothic z,    Runic yr,       Old Italic KHE
};

extension StringColor on String {
  // ── Legacy HSL-based helpers (used for sender-name text colors) ──

  static final _colorCache = <String, Map<double, Color>>{};

  Color _getColorLight(double light) {
    var number = 0.0;
    for (var i = 0; i < length; i++) {
      number += codeUnitAt(i);
    }
    number = (number % 12) * 25.5;
    return HSLColor.fromAHSL(0.75, number, 1, light).toColor();
  }

  /// Saturated colour for sender names in light mode.
  Color get color {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.3] ??= _getColorLight(0.3);
  }

  /// Darker variant used in space view.
  Color get darkColor {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.2] ??= _getColorLight(0.2);
  }

  /// Lighter variant used for sender names in dark mode.
  Color get lightColorText {
    _colorCache[this] ??= {};
    return _colorCache[this]![0.7] ??= _getColorLight(0.7);
  }

  // ── New palette-based avatar background ──

  static final _avatarColorCache = <String, Color>{};

  /// Deterministic muted background color for fallback letter avatars.
  Color get avatarBackground {
    return _avatarColorCache[this] ??= afterdamageAvatarPalette[
        _stableStringHash(this).abs() % afterdamageAvatarPalette.length];
  }

  /// Auto-contrast foreground (white or black) for [avatarBackground].
  Color get avatarForeground => contrastForeground(avatarBackground);

  /// Returns a deterministic arcane Unicode glyph for this string, based on
  /// its first character (A–Z) and a stable hash of the full string.
  /// Non-Latin first characters fall back to the Gothic 𐌰 glyph.
  String get soulInitial {
    if (isEmpty) return '𐌰';
    final first = this[0].toUpperCase();
    final pool = _soulCharPools[first] ?? _soulCharPools['A']!;
    return pool[_stableStringHash(this).abs() % pool.length];
  }
}
