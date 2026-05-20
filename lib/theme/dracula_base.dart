import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dracula_colors.dart';
import 'dracula_text.dart';

/// Shared base for all Dracula accent themes.
/// 
/// Defines:
/// - Background / surface colors (shared across all themes)
/// - TextTheme
/// - BorderRadius tokens
/// - Spacing constants
/// - Elevation defaults
/// 
/// All accent themes extend this base.
class DraculaBase {
  DraculaBase._();

  // === Radius tokens (sharp edges — no rounding) ===
  static const double radiusSmall = 0;
  static const double radiusMedium = 0;
  static const double radiusLarge = 0;
  static const double radiusSheet = 0;

  static const BorderRadius radiusSmAll = BorderRadius.zero;
  static const BorderRadius radiusMdAll = BorderRadius.zero;
  static const BorderRadius radiusLgAll = BorderRadius.zero;

  // === Standard spacing / padding tokens ===
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;

  /// Muted foreground color for timestamps / metadata.
  static Color mutedForeground() => DraculaColors.muted.withOpacity(0.9);

  /// Build base ColorScheme for Dracula themes.
  /// 
  /// [accentColor] is the primary/secondary color for the specific theme.
  /// [errorColor] defaults to Dracula red, but can be overridden (e.g., for red theme).
  static ColorScheme buildColorScheme({
    required Color accentColor,
    Color? errorColor,
  }) {
    return ColorScheme.dark(
      // Base surfaces (shared)
      surface: DraculaColors.background,
      onSurface: DraculaColors.foreground,
      surfaceContainerHighest: DraculaColors.currentLine,
      
      // Accent colors
      primary: accentColor,
      onPrimary: DraculaColors.background,
      primaryContainer: accentColor.withOpacity(0.2),
      onPrimaryContainer: accentColor,
      
      secondary: accentColor.withOpacity(0.8),
      onSecondary: DraculaColors.background,
      secondaryContainer: accentColor.withOpacity(0.15),
      onSecondaryContainer: accentColor,
      
      tertiary: accentColor.withOpacity(0.6),
      onTertiary: DraculaColors.background,
      tertiaryContainer: accentColor.withOpacity(0.1),
      onTertiaryContainer: accentColor,
      
      // Error (red by default, can override)
      error: errorColor ?? DraculaColors.red,
      onError: DraculaColors.background,
      
      // Other
      outline: DraculaColors.muted,
      outlineVariant: DraculaColors.muted.withOpacity(0.5),
      shadow: Colors.black.withOpacity(0.5),
      
      // Surfaces
      surfaceContainer: DraculaColors.currentLine.withOpacity(0.5),
      surfaceContainerLow: DraculaColors.currentLine.withOpacity(0.3),
      surfaceContainerHigh: DraculaColors.currentLine.withOpacity(0.7),
      
      // Inverse
      inverseSurface: DraculaColors.foreground,
      onInverseSurface: DraculaColors.background,
      inversePrimary: accentColor,
    );
  }

  /// Build complete ThemeData with Dracula styling.
  /// 
  /// This is the base that all accent themes extend.
  static ThemeData buildTheme({
    required ColorScheme colorScheme,
    required BuildContext context,
    bool isColumnMode = false,
  }) {
    final textTheme = DraculaText.buildTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // Surfaces
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerHighest,
      dividerColor: colorScheme.surfaceContainerHighest,
      
      // Typography
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        toolbarHeight: isColumnMode ? 72 : 56,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarColor: colorScheme.surface,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(width: 1.5, color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: const CircleBorder(),
      ),
      
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DraculaColors.currentLine.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingMd),
        hintStyle: TextStyle(color: DraculaColors.muted),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        showCheckmark: false,
      ),
      
      // Switch & Checkbox
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return DraculaColors.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return DraculaColors.muted;
        }),
      ),
      
      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      
      // Dialogs
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      
      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      
      // List tile
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.primary,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
      ),
      
      // Navigation
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: DraculaColors.muted);
        }),
      ),
      
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: DraculaColors.muted),
        indicatorColor: colorScheme.primaryContainer,
      ),
      
      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: DraculaColors.muted,
        indicatorColor: colorScheme.primary,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: DraculaColors.currentLine,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
      ),
    );
  }
}
