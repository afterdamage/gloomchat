import 'package:flutter/material.dart';

/// Typography helpers for the Dracula theme.
///
/// Uses the bundled FreeSans family as the primary face so letters,
/// digits, and punctuation render consistently across platforms.
class DraculaText {
  DraculaText._();

  static const String _fontFamily = 'FreeSans';

  static const List<String> _fontFamilyFallback = <String>[
    'Roboto',
    'Tossface',
  ];

  static TextTheme buildTextTheme(TextTheme base) {
    TextStyle? adjust(
      TextStyle? style, {
        double? height,
        FontWeight? weight,
        double? letterSpacing,
      }) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        height: height ?? style.height ?? 1.2,
        fontWeight: weight ?? style.fontWeight,
        letterSpacing: letterSpacing ?? style.letterSpacing,
      );
    }

    return base.copyWith(
      // Primary body text – used for messages.
      bodyLarge: adjust(
        base.bodyLarge,
        height: 1.5, // more breathing room for multi-line messages
      ),
      bodyMedium: adjust(
        base.bodyMedium,
        height: 1.5,
      ),
      bodySmall: adjust(
        base.bodySmall,
        height: 1.4,
      ),
      // Titles / usernames.
      titleLarge: adjust(
        base.titleLarge,
        weight: FontWeight.w600,
      ),
      titleMedium: adjust(
        base.titleMedium,
        weight: FontWeight.w600,
      ),
      titleSmall: adjust(
        base.titleSmall,
        weight: FontWeight.w600,
      ),
      // Metadata / captions.
      labelSmall: adjust(
        base.labelSmall,
        height: 1.2,
      ),
      labelMedium: adjust(
        base.labelMedium,
        height: 1.2,
      ),
    );
  }
}

