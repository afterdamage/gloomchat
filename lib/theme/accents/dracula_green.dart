import 'package:flutter/material.dart';

import '../dracula_base.dart';
import '../dracula_colors.dart';

/// Dracula theme with Green accent (#50FA7B).
/// 
/// Natural, positive, success-oriented vibe.
class DraculaGreen {
  DraculaGreen._();

  static ColorScheme get colorScheme => DraculaBase.buildColorScheme(
        accentColor: DraculaColors.green,
      );

  static ThemeData buildTheme(BuildContext context, {bool isColumnMode = false}) {
    return DraculaBase.buildTheme(
      colorScheme: colorScheme,
      context: context,
      isColumnMode: isColumnMode,
    );
  }
}
