import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/settings_advanced_section.dart';
import 'package:afterdamage/widgets/settings_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'settings_chat.dart';

class SettingsChatView extends StatelessWidget {
  final SettingsChatController controller;
  const SettingsChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).chat),
        automaticallyImplyLeading: !GloomThemes.isColumnMode(context),
        centerTitle: GloomThemes.isColumnMode(context),
      ),
      body: ListTileTheme(
        iconColor: theme.textTheme.bodyLarge!.color,
        child: MaxWidthBody(
          child: Column(
            children: [
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).hideRedactedMessages,
                subtitle: L10n.of(context).hideRedactedMessagesBody,
                setting: AppSettings.hideRedactedEvents,
              ),
              if (PlatformInfos.isMobile)
                SettingsSwitchListTile.adaptive(
                  title: L10n.of(context).autoplayImages,
                  setting: AppSettings.autoplayImages,
                ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).sendOnEnter,
                setting: AppSettings.sendOnEnter,
              ),
              SettingsSwitchListTile.adaptive(
                title: L10n.of(context).swipeRightToLeftToReply,
                setting: AppSettings.swipeRightToLeftToReply,
              ),
              SettingsAdvancedSection(
                children: [
                  SettingsSwitchListTile.adaptive(
                    title: L10n.of(context).hideInvalidOrUnknownMessageFormats,
                    setting: AppSettings.hideUnknownEvents,
                  ),
                  ListTile(
                    title: Text(L10n.of(context).customEmojisAndStickers),
                    subtitle: Text(L10n.of(context).customEmojisAndStickersBody),
                    onTap: () => context.go('/rooms/settings/chat/emotes'),
                    trailing: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.chevron_right_outlined),
                    ),
                  ),
                  SettingsSwitchListTile.adaptive(
                    title: L10n.of(context).experimentalVideoCalls,
                    onChanged: (b) {
                      Matrix.of(context).createVoipPlugin();
                      return;
                    },
                    setting: AppSettings.experimentalVoip,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
