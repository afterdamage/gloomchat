import 'package:flutter/material.dart';

import '../dracula_base.dart';
import '../dracula_colors.dart';

/// Dracula theme with Cyan accent (#8BE9FD).
/// 
/// Cool, fresh, tech-forward vibe.
class DraculaCyan {
  DraculaCyan._();

  static ColorScheme get colorScheme => DraculaBase.buildColorScheme(
        accentColor: DraculaColors.cyan,
      );

  static ThemeData buildTheme(BuildContext context, {bool isColumnMode = false}) {
    return DraculaBase.buildTheme(
      colorScheme: colorScheme,
      context: context,
      isColumnMode: isColumnMode,
    );
  }
}
