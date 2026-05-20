import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/theme/dracula_theme.dart';
import 'package:afterdamage/theme/dracula_accents.dart';

abstract class GloomThemes {
  static const double columnWidth = 380.0;

  static const double maxTimelineWidth = columnWidth * 2;

  static const double navRailWidth = 80.0;

  /// Get custom background color for the given brightness, or null for default.
  static Color? getCustomBackgroundColor(Brightness brightness) {
    final colorInt = brightness == Brightness.dark
        ? AppSettings.backgroundColorDark.value
        : AppSettings.backgroundColorLight.value;
    return colorInt == 0 ? null : Color(colorInt);
  }

  static bool isColumnModeByWidth(double width) =>
      width > columnWidth * 2 + navRailWidth;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.sizeOf(context).width);

  static bool isThreeColumnMode(BuildContext context) =>
      MediaQuery.sizeOf(context).width > GloomThemes.columnWidth * 3.5;

  static LinearGradient backgroundGradient(BuildContext context, int alpha) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      colors: [
        colorScheme.primaryContainer.withAlpha(alpha),
        colorScheme.secondaryContainer.withAlpha(alpha),
        colorScheme.tertiaryContainer.withAlpha(alpha),
        colorScheme.primaryContainer.withAlpha(alpha),
      ],
    );
  }

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeInOut;

  /// Build theme using the new Dracula accent system.
  /// 
  /// This provides access to the 7 accent themes while maintaining
  /// consistent base surfaces and typography.
  /// 
  /// Available accents: cyan, green, orange, pink, purple, red, yellow
  static ThemeData buildAccentTheme(
    BuildContext context,
    DraculaAccent accent,
  ) {
    final isColumnMode = GloomThemes.isColumnMode(context);
    var theme = DraculaThemeResolver.getTheme(
      accent,
      context,
      isColumnMode: isColumnMode,
    );
    // Apply custom background color if set
    final customBg = getCustomBackgroundColor(Brightness.dark);
    if (customBg != null) {
      final hsl = HSLColor.fromColor(customBg);
      final containerHighest = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
      theme = theme.copyWith(
        scaffoldBackgroundColor: customBg,
        canvasColor: customBg,
        cardColor: containerHighest,
        dividerColor: containerHighest,
        colorScheme: theme.colorScheme.copyWith(
          surface: customBg,
          surfaceContainerLowest: hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor(),
          surfaceContainerLow: hsl.withLightness((hsl.lightness + 0.03).clamp(0.0, 1.0)).toColor(),
          surfaceContainer: hsl.withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0)).toColor(),
          surfaceContainerHigh: hsl.withLightness((hsl.lightness + 0.09).clamp(0.0, 1.0)).toColor(),
          surfaceContainerHighest: containerHighest,
        ),
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: customBg,
          systemOverlayStyle: theme.appBarTheme.systemOverlayStyle?.copyWith(
            systemNavigationBarColor: customBg,
          ),
        ),
        dialogTheme: theme.dialogTheme.copyWith(
          backgroundColor: customBg,
        ),
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          backgroundColor: customBg,
        ),
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          color: containerHighest,
        ),
        snackBarTheme: theme.snackBarTheme.copyWith(
          backgroundColor: containerHighest,
        ),
      );
    }
    return theme;
  }

  static ThemeData buildTheme(
    BuildContext context,
    Brightness brightness, [
    Color? seed,
  ]) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? DraculaTheme.darkColorScheme(
            seedOverride: seed ?? Color(AppSettings.colorSchemeSeedInt.value),
          )
        : ColorScheme.fromSeed(
            brightness: brightness,
            seedColor: seed ?? Color(AppSettings.colorSchemeSeedInt.value),
          );
    final isColumnMode = GloomThemes.isColumnMode(context);
    final baseTheme = ThemeData(
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      dividerColor: brightness == Brightness.dark
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainer,
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerLow,
        iconColor: colorScheme.onSurface,
        textStyle: TextStyle(color: colorScheme.onSurface),
        shape: const RoundedRectangleBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          iconColor: colorScheme.onSurface,
          disabledIconColor: colorScheme.onSurface,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: colorScheme.onSurface.withAlpha(128),
        selectionHandleColor: colorScheme.secondary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: EdgeInsets.all(12),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: colorScheme.surfaceContainer,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnMode ? 72 : 56,
        shadowColor: isColumnMode
            ? colorScheme.surfaceContainer.withAlpha(128)
            : null,
        surfaceTintColor: isColumnMode ? colorScheme.surface : null,
        backgroundColor: isColumnMode ? colorScheme.surface : null,
        actionsPadding: isColumnMode
            ? const EdgeInsets.symmetric(horizontal: 16.0)
            : null,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness.reversed,
          statusBarBrightness: brightness,
          systemNavigationBarIconBrightness: brightness.reversed,
          systemNavigationBarColor: colorScheme.surface,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(width: 1, color: colorScheme.primary),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        strokeCap: StrokeCap.round,
        color: colorScheme.primary,
        refreshBackgroundColor: colorScheme.primaryContainer,
      ),
      snackBarTheme: isColumnMode
          ? const SnackBarThemeData(
              showCloseIcon: true,
              behavior: SnackBarBehavior.floating,
              width: GloomThemes.columnWidth * 1.5,
            )
          : const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: DraculaTheme.spacingLg,
            vertical: DraculaTheme.spacingMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: DraculaTheme.spacingLg,
            vertical: DraculaTheme.spacingMd,
          ),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );

    // Apply Dracula-specific typography and surfaces for dark mode only.
    var finalTheme = isDark ? DraculaTheme.applyDraculaTheme(baseTheme) : baseTheme;

    // Apply custom background color if set
    final customBg = getCustomBackgroundColor(brightness);
    if (customBg != null) {
      final hsl = HSLColor.fromColor(customBg);
      final containerHighest = hsl.withLightness((hsl.lightness + (isDark ? 0.12 : -0.06)).clamp(0.0, 1.0)).toColor();
      finalTheme = finalTheme.copyWith(
        scaffoldBackgroundColor: customBg,
        canvasColor: customBg,
        cardColor: containerHighest,
        dividerColor: containerHighest,
        colorScheme: finalTheme.colorScheme.copyWith(
          surface: customBg,
          surfaceContainerLowest: hsl.withLightness((hsl.lightness + (isDark ? -0.05 : 0.03)).clamp(0.0, 1.0)).toColor(),
          surfaceContainerLow: hsl.withLightness((hsl.lightness + (isDark ? 0.03 : -0.02)).clamp(0.0, 1.0)).toColor(),
          surfaceContainer: hsl.withLightness((hsl.lightness + (isDark ? 0.06 : -0.03)).clamp(0.0, 1.0)).toColor(),
          surfaceContainerHigh: hsl.withLightness((hsl.lightness + (isDark ? 0.09 : -0.05)).clamp(0.0, 1.0)).toColor(),
          surfaceContainerHighest: containerHighest,
        ),
        appBarTheme: finalTheme.appBarTheme.copyWith(
          backgroundColor: customBg,
        ),
        dialogTheme: finalTheme.dialogTheme?.copyWith(
          backgroundColor: customBg,
        ),
        bottomSheetTheme: finalTheme.bottomSheetTheme.copyWith(
          backgroundColor: customBg,
        ),
        popupMenuTheme: finalTheme.popupMenuTheme.copyWith(
          color: containerHighest,
        ),
      );
    }
    return finalTheme;
  }
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}

extension BubbleColorTheme on ThemeData {
  Color get bubbleColor => brightness == Brightness.light
      ? colorScheme.primary
      : colorScheme.primaryContainer;

  /// Bubble text color: always high-contrast, never accent-tinted.
  /// Uses the actual bubble color luminance to determine black or white text.
  Color get onBubbleColor {
    final bg = bubbleColor;
    return ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color get secondaryBubbleColor => HSLColor.fromColor(
    brightness == Brightness.light
        ? colorScheme.tertiary
        : colorScheme.tertiaryContainer,
  ).withSaturation(0.5).toColor();
}
