import 'package:flutter/material.dart';

import '../dracula_base.dart';
import '../dracula_colors.dart';

/// Dracula theme with Red accent (#FF5555).
/// 
/// Bold, urgent, attention-grabbing vibe.
/// Uses a darker red variant for error states to maintain distinction.
class DraculaRed {
  DraculaRed._();

  /// Darker red for error states (to avoid confusion with primary)
  static const Color _errorRed = Color(0xFFCC4444);

  static ColorScheme get colorScheme => DraculaBase.buildColorScheme(
        accentColor: DraculaColors.red,
        errorColor: _errorRed,
      );

  static ThemeData buildTheme(BuildContext context, {bool isColumnMode = false}) {
    return DraculaBase.buildTheme(
      colorScheme: colorScheme,
      context: context,
      isColumnMode: isColumnMode,
    );
  }
}
