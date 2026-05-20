import 'package:flutter/material.dart';

import 'accents/dracula_cyan.dart';
import 'accents/dracula_green.dart';
import 'accents/dracula_orange.dart';
import 'accents/dracula_pink.dart';
import 'accents/dracula_purple.dart';
import 'accents/dracula_red.dart';
import 'accents/dracula_yellow.dart';

/// Available Dracula accent themes.
/// 
/// Each accent theme shares the same base surfaces (background, currentLine)
/// but uses a different accent color for primary UI elements.
enum DraculaAccent {
  /// Cyan (#8BE9FD) - Cool, fresh, tech-forward
  cyan,
  
  /// Green (#50FA7B) - Natural, positive, success
  green,
  
  /// Orange (#FFB86C) - Warm, energetic, creative
  orange,
  
  /// Pink (#FF79C6) - Playful, bold, expressive
  pink,
  
  /// Purple (#BD93F9) - Classic Dracula, elegant, premium
  purple,
  
  /// Red (#FF5555) - Bold, urgent, attention-grabbing
  red,
  
  /// Yellow (#F1FA8C) - Bright, optimistic, cheerful
  yellow,
}

/// Extension to get display names for accent themes.
extension DraculaAccentExtension on DraculaAccent {
  /// Human-readable name for the accent theme.
  String get displayName {
    switch (this) {
      case DraculaAccent.cyan:
        return 'Cyan';
      case DraculaAccent.green:
        return 'Green';
      case DraculaAccent.orange:
        return 'Orange';
      case DraculaAccent.pink:
        return 'Pink';
      case DraculaAccent.purple:
        return 'Purple';
      case DraculaAccent.red:
        return 'Red';
      case DraculaAccent.yellow:
        return 'Yellow';
    }
  }

  /// Description of the accent theme's vibe.
  String get description {
    switch (this) {
      case DraculaAccent.cyan:
        return 'Cool, fresh, tech-forward';
      case DraculaAccent.green:
        return 'Natural, positive, success-oriented';
      case DraculaAccent.orange:
        return 'Warm, energetic, creative';
      case DraculaAccent.pink:
        return 'Playful, bold, expressive';
      case DraculaAccent.purple:
        return 'Classic Dracula, elegant, premium';
      case DraculaAccent.red:
        return 'Bold, urgent, attention-grabbing';
      case DraculaAccent.yellow:
        return 'Bright, optimistic, cheerful';
    }
  }

  /// Preview color for theme selection UI.
  Color get previewColor {
    switch (this) {
      case DraculaAccent.cyan:
        return const Color(0xFF8BE9FD);
      case DraculaAccent.green:
        return const Color(0xFF50FA7B);
      case DraculaAccent.orange:
        return const Color(0xFFFFB86C);
      case DraculaAccent.pink:
        return const Color(0xFFFF79C6);
      case DraculaAccent.purple:
        return const Color(0xFFBD93F9);
      case DraculaAccent.red:
        return const Color(0xFFFF5555);
      case DraculaAccent.yellow:
        return const Color(0xFFF1FA8C);
    }
  }
}

/// Resolver for Dracula accent themes.
/// 
/// Provides a clean interface to get ThemeData for any accent.
class DraculaThemeResolver {
  DraculaThemeResolver._();

  /// Get ThemeData for the specified accent.
  /// 
  /// [accent] - The accent theme to use
  /// [context] - Build context (required for responsive adaptations)
  /// [isColumnMode] - Whether the app is in column/desktop mode
  static ThemeData getTheme(
    DraculaAccent accent,
    BuildContext context, {
    bool isColumnMode = false,
  }) {
    switch (accent) {
      case DraculaAccent.cyan:
        return DraculaCyan.buildTheme(context, isColumnMode: isColumnMode);
      case DraculaAccent.green:
        return DraculaGreen.buildTheme(context, isColumnMode: isColumnMode);
      case DraculaAccent.orange:
        return DraculaOrange.buildTheme(context, isColumnMode: isColumnMode);  
      case DraculaAccent.pink:
        return DraculaPink.buildTheme(context, isColumnMode: isColumnMode);
      case DraculaAccent.purple:
        return DraculaPurple.buildTheme(context, isColumnMode: isColumnMode);
      case DraculaAccent.red:
        return DraculaRed.buildTheme(context, isColumnMode: isColumnMode);
      case DraculaAccent.yellow:
        return DraculaYellow.buildTheme(context, isColumnMode: isColumnMode);
    }
  }

  /// Get ColorScheme for the specified accent.
  /// 
  /// Useful for previews or when you need just the colors without full ThemeData.
  static ColorScheme getColorScheme(DraculaAccent accent) {
    switch (accent) {
      case DraculaAccent.cyan:
        return DraculaCyan.colorScheme;
      case DraculaAccent.green:
        return DraculaGreen.colorScheme;
      case DraculaAccent.orange:
        return DraculaOrange.colorScheme;
      case DraculaAccent.pink:
        return DraculaPink.colorScheme;
      case DraculaAccent.purple:
        return DraculaPurple.colorScheme;
      case DraculaAccent.red:
        return DraculaRed.colorScheme;
      case DraculaAccent.yellow:
        return DraculaYellow.colorScheme;
    }
  }
}
