import 'package:flutter/material.dart';

import 'dracula_base.dart';
import 'dracula_colors.dart';
import 'dracula_text.dart';
import 'dracula_accents.dart';

/// Centralized Dracula design system.
///
/// This file provides backward compatibility and convenience methods.
/// For the new accent theme system, see [DraculaAccent] and [DraculaThemeResolver].
///
/// Exposes:
/// - ColorScheme factory for dark mode
/// - TextTheme tweaks
/// - Standard border radii and spacing tokens
class DraculaTheme {
  DraculaTheme._();

  /// Build a Dracula-flavoured dark [ColorScheme].
  ///
  /// [seedOverride] can be used to slightly shift accents while keeping
  /// the base Dracula palette intact.
  /// 
  /// For the new accent system, use [DraculaThemeResolver.getColorScheme] instead.
  static ColorScheme darkColorScheme({Color? seedOverride}) {
    return DraculaBase.buildColorScheme(
      accentColor: seedOverride ?? DraculaColors.purple,
    );
  }

  /// Apply Dracula colors & typography to a base [ThemeData].
  /// 
  /// This is kept for backward compatibility.
  /// For the new accent system, use [DraculaThemeResolver.getTheme] instead.
  static ThemeData applyDraculaTheme(ThemeData base) {
    final colorScheme = base.colorScheme;
    final textTheme = DraculaText.buildTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: DraculaText.buildTextTheme(base.primaryTextTheme),
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerHighest,
    );
  }

  // === Radius tokens (sharp, editorial geometry) ===
  // Delegated to DraculaBase for consistency

  static const double radiusSmall = DraculaBase.radiusSmall;
  static const double radiusMedium = DraculaBase.radiusMedium;
  static const double radiusLarge = DraculaBase.radiusLarge;
  static const double radiusSheet = DraculaBase.radiusSheet;

  static const BorderRadius radiusXsAll = DraculaBase.radiusSmAll;
  static const BorderRadius radiusMdAll = DraculaBase.radiusMdAll;
  static const BorderRadius radiusLgAll = DraculaBase.radiusLgAll;

  // === Standard spacing / padding tokens ===
  // Delegated to DraculaBase for consistency

  static const double spacingXs = DraculaBase.spacingXs;
  static const double spacingSm = DraculaBase.spacingSm;
  static const double spacingMd = DraculaBase.spacingMd;
  static const double spacingLg = DraculaBase.spacingLg;
  static const double spacingXl = DraculaBase.spacingXl;

  /// Muted foreground color for timestamps / metadata.
  static Color mutedForeground(ColorScheme colorScheme) =>
      DraculaBase.mutedForeground();
}


