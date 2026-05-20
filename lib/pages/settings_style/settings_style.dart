import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/theme/dracula_colors.dart';
import 'package:afterdamage/utils/account_config.dart';
import 'package:afterdamage/utils/file_selector.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';
import 'package:afterdamage/widgets/theme_builder.dart';
import '../../widgets/matrix.dart';
import 'settings_style_view.dart';

class SettingsStyle extends StatefulWidget {
  const SettingsStyle({super.key});

  @override
  SettingsStyleController createState() => SettingsStyleController();
}

class SettingsStyleController extends State<SettingsStyle> {
  void setChatColor(Color? color) async {
    AppSettings.colorSchemeSeedInt.setItem(
      color?.toARGB32() ?? AppSettings.colorSchemeSeedInt.defaultValue,
    );
    ThemeController.of(context).setPrimaryColor(color);
  }

  void setWallpaper() async {
    final client = Matrix.of(context).client;
    final picked = await selectFiles(context, type: FileType.image);
    final pickedFile = picked.firstOrNull;
    if (pickedFile == null) return;

    await showFutureLoadingDialog(
      context: context,
      future: () async {
        final url = await client.uploadContent(
          await pickedFile.readAsBytes(),
          filename: pickedFile.name,
        );
        await client.updateApplicationAccountConfig(
          ApplicationAccountConfig(wallpaperUrl: url),
        );
      },
    );
  }

  double get wallpaperOpacity =>
      _wallpaperOpacity ??
      Matrix.of(context).client.applicationAccountConfig.wallpaperOpacity ??
      0.5;

  double? _wallpaperOpacity;

  void saveWallpaperOpacity(double opacity) async {
    final client = Matrix.of(context).client;
    final result = await showFutureLoadingDialog(
      context: context,
      future: () => client.updateApplicationAccountConfig(
        ApplicationAccountConfig(wallpaperOpacity: opacity),
      ),
    );
    if (result.isValue) return;

    setState(() {
      _wallpaperOpacity = client.applicationAccountConfig.wallpaperOpacity;
    });
  }

  void updateWallpaperOpacity(double opacity) {
    setState(() {
      _wallpaperOpacity = opacity;
    });
  }

  double get wallpaperBlur =>
      _wallpaperBlur ??
      Matrix.of(context).client.applicationAccountConfig.wallpaperBlur ??
      0.5;
  double? _wallpaperBlur;

  void saveWallpaperBlur(double blur) async {
    final client = Matrix.of(context).client;
    final result = await showFutureLoadingDialog(
      context: context,
      future: () => client.updateApplicationAccountConfig(
        ApplicationAccountConfig(wallpaperBlur: blur),
      ),
    );
    if (result.isValue) return;

    setState(() {
      _wallpaperBlur = client.applicationAccountConfig.wallpaperBlur;
    });
  }

  void updateWallpaperBlur(double blur) {
    setState(() {
      _wallpaperBlur = blur;
    });
  }

  void deleteChatWallpaper() => showFutureLoadingDialog(
    context: context,
    future: () => Matrix.of(context).client.setApplicationAccountConfig(
      const ApplicationAccountConfig(wallpaperUrl: null, wallpaperBlur: null),
    ),
  );

  ThemeMode get currentTheme => ThemeController.of(context).themeMode;
  Color? get currentColor => ThemeController.of(context).primaryColor;

  static final List<Color?> customColors = [
    null,
    AppConfig.chatColor,
    Colors.indigo,
    Colors.blue,
    Colors.blueAccent,
    Colors.teal,
    Colors.tealAccent,
    Colors.green,
    Colors.greenAccent,
    Colors.yellow,
    Colors.yellowAccent,
    Colors.orange,
    Colors.orangeAccent,
    Colors.red,
    Colors.redAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.purple,
    Colors.purpleAccent,
    Colors.blueGrey,
    Colors.grey,
    Colors.white,
    Colors.black,
  ];

  void switchTheme(ThemeMode? newTheme) {
    if (newTheme == null) return;
    switch (newTheme) {
      case ThemeMode.light:
        ThemeController.of(context).setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.dark:
        ThemeController.of(context).setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.system:
        ThemeController.of(context).setThemeMode(ThemeMode.system);
        break;
    }
    setState(() {});
  }

  void changeFontSizeFactor(double d) async {
    await AppSettings.fontSizeFactor.setItem(d);
    setState(() {});
  }

  // Dracula accent theme methods
  DraculaAccent get currentDraculaAccent {
    final accentName = AppSettings.draculaAccent.value;
    return DraculaAccent.values.firstWhere(
      (accent) => accent.name == accentName,
      orElse: () => DraculaAccent.red,  // Default to red accent
    );
  }

  Future<void> setDraculaAccent(DraculaAccent accent) async {
    await AppSettings.draculaAccent.setItem(accent.name);
    ThemeController.of(context).setDraculaAccent(accent);
    setState(() {});
  }

  // Background color methods
  Color? get currentBackgroundColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorInt = isDark
        ? AppSettings.backgroundColorDark.value
        : AppSettings.backgroundColorLight.value;
    return colorInt == 0 ? null : Color(colorInt);
  }

  /// Preset background colors complementary to Dracula accents.
  ///
  /// Dark presets use deep tones that pair well with Dracula's vibrant accents.
  /// Light presets use soft tinted whites that echo each accent color.
  List<Map<String, dynamic>> get backgroundColorPresets {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        {'label': 'Default', 'color': null},
        // Dracula base
        {'label': 'Dracula', 'color': DraculaColors.background},
        // AMOLED black
        {'label': 'AMOLED Black', 'color': const Color(0xFF000000)},
        // Cyan complement: deep navy/teal
        {'label': 'Deep Navy', 'color': const Color(0xFF0D1B2A)},
        {'label': 'Dark Teal', 'color': const Color(0xFF0B2027)},
        // Green complement: dark forest
        {'label': 'Deep Forest', 'color': const Color(0xFF0B1A0B)},
        {'label': 'Moss', 'color': const Color(0xFF1A2F1A)},
        // Orange complement: warm dark brown
        {'label': 'Espresso', 'color': const Color(0xFF1C1008)},
        {'label': 'Dark Umber', 'color': const Color(0xFF2A1A0A)},
        // Pink complement: deep plum
        {'label': 'Deep Plum', 'color': const Color(0xFF1A0A1A)},
        {'label': 'Dark Rose', 'color': const Color(0xFF2A0E22)},
        // Purple complement: deep indigo
        {'label': 'Deep Indigo', 'color': const Color(0xFF110B22)},
        {'label': 'Midnight', 'color': const Color(0xFF1A1032)},
        // Red complement: dark crimson/wine
        {'label': 'Dark Wine', 'color': const Color(0xFF1A0808)},
        {'label': 'Charred', 'color': const Color(0xFF2A0F0F)},
        // Yellow complement: dark olive/gold
        {'label': 'Dark Olive', 'color': const Color(0xFF1A1A08)},
        {'label': 'Deep Gold', 'color': const Color(0xFF2A2510)},
      ];
    } else {
      return [
        {'label': 'Default', 'color': null},
        {'label': 'White', 'color': const Color(0xFFFFFFFF)},
        // Cyan complement
        {'label': 'Ice Blue', 'color': const Color(0xFFE8F8FC)},
        {'label': 'Frost', 'color': const Color(0xFFF0FAFD)},
        // Green complement
        {'label': 'Honeydew', 'color': const Color(0xFFF0FFF0)},
        {'label': 'Mint Cream', 'color': const Color(0xFFE8FCE8)},
        // Orange complement
        {'label': 'Peach', 'color': const Color(0xFFFFF5EB)},
        {'label': 'Warm Ivory', 'color': const Color(0xFFFDF5E6)},
        // Pink complement
        {'label': 'Rose White', 'color': const Color(0xFFFFF0F5)},
        {'label': 'Blush', 'color': const Color(0xFFFCE8F0)},
        // Purple complement
        {'label': 'Lavender', 'color': const Color(0xFFF0ECFF)},
        {'label': 'Soft Violet', 'color': const Color(0xFFF5F0FF)},
        // Red complement
        {'label': 'Shell', 'color': const Color(0xFFFFF0F0)},
        {'label': 'Petal', 'color': const Color(0xFFFCECEC)},
        // Yellow complement
        {'label': 'Cream', 'color': const Color(0xFFFFFFF0)},
        {'label': 'Butter', 'color': const Color(0xFFFCFCE8)},
      ];
    }
  }

  Future<void> setBackgroundColor(Color? color) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorInt = color?.toARGB32() ?? 0;
    if (isDark) {
      await AppSettings.backgroundColorDark.setItem(colorInt);
    } else {
      await AppSettings.backgroundColorLight.setItem(colorInt);
    }
    ThemeController.of(context).setBackgroundColor(color, isDark: isDark);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => SettingsStyleView(this);
}
