import 'package:flutter/material.dart';

import '../dracula_base.dart';
import '../dracula_colors.dart';

/// Dracula theme with Orange accent (#FFB86C).
/// 
/// Warm, energetic, creative vibe.
class DraculaOrange {
  DraculaOrange._();

  static ColorScheme get colorScheme => DraculaBase.buildColorScheme(
        accentColor: DraculaColors.orange,
      );

  static ThemeData buildTheme(BuildContext context, {bool isColumnMode = false}) {
    return DraculaBase.buildTheme(
      colorScheme: colorScheme,
      context: context,
      isColumnMode: isColumnMode,
    );
  }
}
