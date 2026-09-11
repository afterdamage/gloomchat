import 'package:flutter/material.dart';

import '../dracula_base.dart';
import '../dracula_colors.dart';

/// Dracula theme with Pink accent (#FF79C6).
/// 
/// Playful, bold, expressive vibe.
class DraculaPink {
  DraculaPink._();

  static ColorScheme get colorScheme => DraculaBase.buildColorScheme(
        accentColor: DraculaColors.pink,
      );

  static ThemeData buildTheme(BuildContext context, {bool isColumnMode = false}) {
    return DraculaBase.buildTheme(
      colorScheme: colorScheme,
      context: context,
      isColumnMode: isColumnMode,
    );
  }
}
