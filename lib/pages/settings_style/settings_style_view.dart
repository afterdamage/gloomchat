import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat/events/state_message.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/utils/account_config.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/mxc_image.dart';
import '../../config/app_config.dart';
import '../../widgets/settings_advanced_section.dart';
import '../../widgets/settings_switch_list_tile.dart';
import 'settings_style.dart';

class SettingsStyleView extends StatelessWidget {
  final SettingsStyleController controller;

  const SettingsStyleView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final client = Matrix.of(context).client;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !GloomThemes.isColumnMode(context),
        centerTitle: GloomThemes.isColumnMode(context),
        title: Text(L10n.of(context).changeTheme),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: MaxWidthBody(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SegmentedButton<ThemeMode>(
                style: SegmentedButton.styleFrom(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                selected: {controller.currentTheme},
                onSelectionChanged: (selected) =>
                    controller.switchTheme(selected.single),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(L10n.of(context).lightTheme),
                    icon: const FaIcon(FontAwesomeIcons.sun),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(L10n.of(context).darkTheme),
                    icon: const FaIcon(FontAwesomeIcons.moon),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(L10n.of(context).systemTheme),
                    icon: const FaIcon(FontAwesomeIcons.circleHalfStroke),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).setColorTheme,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: DraculaAccent.values.map((accent) {
                  final isSelected = controller.currentDraculaAccent == accent;
                  return GestureDetector(
                    onTap: () => controller.setDraculaAccent(accent),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: accent.previewColor,
                        borderRadius: BorderRadius.zero,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.previewColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            accent.displayName,
                            style: TextStyle(
                              color: theme.colorScheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4),
                            FaIcon(
                              FontAwesomeIcons.solidCircleCheck,
                              color: theme.colorScheme.surface,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).setWallpaper,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                theme.brightness == Brightness.dark
                    ? L10n.of(context).darkTheme
                    : L10n.of(context).lightTheme,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  // "Default" option (no custom bg)
                  ...controller.backgroundColorPresets.map((preset) {
                    final isSelected = controller.currentBackgroundColor == preset['color'];
                    final color = preset['color'] as Color?;
                    return GestureDetector(
                      onTap: () => controller.setBackgroundColor(color),
                      child: Tooltip(
                        message: preset['label'] as String,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color ?? theme.colorScheme.surface,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.check,
                                    size: 16,
                                    color: color != null
                                        ? (ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                            ? Colors.white
                                            : Colors.black)
                                        : theme.colorScheme.onSurface,
                                  ),
                                )
                              : color == null
                                  ? Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.ban,
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    )
                                  : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              title: Text(
                L10n.of(context).messagesStyle,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder(
              stream: client.onSync.stream.where(
                (syncUpdate) =>
                    syncUpdate.accountData?.any(
                      (accountData) =>
                          accountData.type ==
                          ApplicationAccountConfigExtension.accountDataKey,
                    ) ??
                    false,
              ),
              builder: (context, snapshot) {
                final accountConfig = client.applicationAccountConfig;

                return Column(
                  mainAxisSize: .min,
                  children: [
                    AnimatedContainer(
                      duration: GloomThemes.animationDuration,
                      curve: GloomThemes.animationCurve,
                      decoration: const BoxDecoration(),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (accountConfig.wallpaperUrl != null)
                            Opacity(
                              opacity: controller.wallpaperOpacity,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: controller.wallpaperBlur,
                                  sigmaY: controller.wallpaperBlur,
                                ),
                                child: MxcImage(
                                  key: ValueKey(accountConfig.wallpaperUrl),
                                  uri: accountConfig.wallpaperUrl,
                                  fit: BoxFit.cover,
                                  isThumbnail: true,
                                  width: GloomThemes.columnWidth * 2,
                                  height: 212,
                                ),
                              ),
                            ),
                          Column(
                            mainAxisSize: .min,
                            children: [
                              const SizedBox(height: 16),
                              StateMessage(
                                Event(
                                  eventId: 'style_dummy',
                                  room: Room(
                                    id: '!style_dummy',
                                    client: client,
                                  ),
                                  content: {'membership': 'join'},
                                  type: EventTypes.RoomMember,
                                  senderId: client.userID!,
                                  originServerTs: DateTime.now(),
                                  stateKey: client.userID!,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 12 + 12 + Avatar.defaultSize,
                                  right: 12,
                                  top: accountConfig.wallpaperUrl == null
                                      ? 0
                                      : 12,
                                  bottom: 12,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.bubbleColor,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
                                      style: TextStyle(
                                        color: theme.onBubbleColor,
                                        fontSize:
                                            AppConfig.messageFontSize *
                                            AppSettings.fontSizeFactor.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: 12,
                                    left: 12,
                                    top: accountConfig.wallpaperUrl == null
                                        ? 0
                                        : 12,
                                    bottom: 12,
                                  ),
                                  child: Material(
                                    color:
                                        theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Lorem ipsum dolor sit amet',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize:
                                              AppConfig.messageFontSize *
                                              AppSettings.fontSizeFactor.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: theme.dividerColor),
                    ListTile(
                      title: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                        ),
                        onPressed: controller.setWallpaper,
                        icon: const FaIcon(FontAwesomeIcons.penToSquare),
                        label: Text(L10n.of(context).setWallpaper),
                      ),
                      trailing: accountConfig.wallpaperUrl == null
                          ? null
                          : IconButton(
                              icon: const FaIcon(FontAwesomeIcons.trash),
                              color: theme.colorScheme.error,
                              onPressed: controller.deleteChatWallpaper,
                            ),
                    ),
                    if (accountConfig.wallpaperUrl != null) ...[
                      ListTile(title: Text(L10n.of(context).opacity)),
                      Slider(
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperOpacity,
                        onChanged: controller.updateWallpaperOpacity,
                        onChangeEnd: controller.saveWallpaperOpacity,
                      ),
                      ListTile(title: Text(L10n.of(context).blur)),
                      Slider(
                        min: 0.0,
                        max: 10.0,
                        divisions: 10,
                        semanticFormatterCallback: (d) => d.toString(),
                        value: controller.wallpaperBlur,
                        onChanged: controller.updateWallpaperBlur,
                        onChangeEnd: controller.saveWallpaperBlur,
                      ),
                    ],
                  ],
                );
              },
            ),
            ListTile(
              title: Text(L10n.of(context).fontSize),
              trailing: Text('Ã— ${AppSettings.fontSizeFactor.value}'),
            ),
            Slider(
              min: 0.5,
              max: 2.5,
              divisions: 20,
              value: AppSettings.fontSizeFactor.value,
              semanticFormatterCallback: (d) => d.toString(),
              onChanged: controller.changeFontSizeFactor,
            ),
            SettingsAdvancedSection(
              children: [
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context).presencesToggle,
                  setting: AppSettings.showPresences,
                ),
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context).displayNavigationRail,
                  setting: AppSettings.displayNavigationRail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
