import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/beautify_string_extension.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/settings_advanced_section.dart';
import 'package:afterdamage/widgets/settings_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'settings_security.dart';

class SettingsSecurityView extends StatelessWidget {
  final SettingsSecurityController controller;

  const SettingsSecurityView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).security),
        automaticallyImplyLeading: !GloomThemes.isColumnMode(context),
        centerTitle: GloomThemes.isColumnMode(context),
      ),
      body: ListTileTheme(
        iconColor: theme.colorScheme.onSurface,
        child: MaxWidthBody(
          child: FutureBuilder(
            future: Matrix.of(
              context,
            ).client.getCapabilities().timeout(const Duration(seconds: 10)),
            builder: (context, snapshot) {
              final capabilities = snapshot.data;
              final error = snapshot.error;
              if (error == null && capabilities == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      L10n.of(context).privacy,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SettingsSwitchListTile.adaptive(
                    title: L10n.of(context).sendTypingNotifications,
                    subtitle: L10n.of(
                      context,
                    ).sendTypingNotificationsDescription,
                    setting: AppSettings.sendTypingNotifications,
                  ),
                  SettingsSwitchListTile.adaptive(
                    title: L10n.of(context).sendReadReceipts,
                    subtitle: L10n.of(context).sendReadReceiptsDescription,
                    setting: AppSettings.sendPublicReadReceipts,
                  ),
                  ListTile(
                    trailing: const Icon(Icons.chevron_right_outlined),
                    title: Text(L10n.of(context).blockedUsers),
                    subtitle: Text(
                      L10n.of(context).thereAreCountUsersBlocked(
                        Matrix.of(context).client.ignoredUsers.length,
                      ),
                    ),
                    onTap: () =>
                        context.go('/rooms/settings/security/ignorelist'),
                  ),
                  if (Matrix.of(context).client.encryption != null) ...{
                    if (PlatformInfos.isMobile)
                      ListTile(
                        trailing: const Icon(Icons.chevron_right_outlined),
                        title: Text(L10n.of(context).appLock),
                        subtitle: Text(L10n.of(context).appLockDescription),
                        onTap: controller.setAppLockAction,
                      ),
                    if (PlatformInfos.isMobile)
                      SettingsSwitchListTile.adaptive(
                        setting: AppSettings.decoyMode,
                        title: L10n.of(context).decoyMode,
                        subtitle: L10n.of(context).decoyModeDescription,
                      ),
                  },
                  Divider(color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      L10n.of(context).shareKeysWith,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(L10n.of(context).shareKeysWithDescription),
                  ),
                  ListTile(
                    title: Material(
                      borderRadius: BorderRadius.zero,
                      color: theme.colorScheme.onInverseSurface,
                      child: DropdownButton<ShareKeysWith>(
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        borderRadius: BorderRadius.zero,
                        underline: const SizedBox.shrink(),
                        value: Matrix.of(context).client.shareKeysWith,
                        items: ShareKeysWith.values
                            .map(
                              (share) => DropdownMenuItem(
                                value: share,
                                child: Text(share.localized(L10n.of(context))),
                              ),
                            )
                            .toList(),
                        onChanged: controller.changeShareKeysWith,
                      ),
                    ),
                  ),
                  Divider(color: theme.dividerColor),
                  ListTile(
                    title: Text(
                      L10n.of(context).account,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (capabilities?.mChangePassword?.enabled != false ||
                      error != null)
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      trailing: const Icon(Icons.chevron_right_outlined),
                      title: Text(L10n.of(context).changePassword),
                      onTap: () =>
                          context.go('/rooms/settings/security/password'),
                    ),
                  SettingsAdvancedSection(
                    children: [
                      ListTile(
                        title: Text(L10n.of(context).yourPublicKey),
                        leading: const Icon(Icons.vpn_key_outlined),
                        subtitle: SelectableText(
                          Matrix.of(context).client.fingerprintKey.beautified,
                          style: const TextStyle(fontFamily: 'RobotoMono'),
                        ),
                      ),
                      ListTile(
                        iconColor: const Color(0xFFFFB86C),
                        leading: const Icon(Icons.delete_sweep_outlined),
                        title: Text(
                          L10n.of(context).dehydrate,
                          style: const TextStyle(color: Color(0xFFFFB86C)),
                        ),
                        onTap: controller.dehydrateAction,
                      ),
                    ],
                  ),
                  Divider(color: theme.colorScheme.errorContainer),
                  ListTile(
                    iconColor: theme.colorScheme.error,
                    leading: const Icon(Icons.delete_outlined),
                    title: Text(
                      L10n.of(context).deleteAccount,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: controller.deleteAccountAction,
                  ),
                  ListTile(
                    leading: FaIcon(
                      FontAwesomeIcons.radiation,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Panic',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Wipe local data and log out'),
                    onTap: () async {
                      final consent = await showOkCancelAlertDialog(
                        context: context,
                        title: 'Panic',
                        message:
                            'This will wipe all local data and log you out. Are you absolutely sure?',
                        okLabel: 'Burn it',
                        cancelLabel: L10n.of(context).cancel,
                      );
                      if (consent != OkCancelResult.ok || !context.mounted) {
                        return;
                      }
                      await showFutureLoadingDialog(
                        context: context,
                        future: () async {
                          await Matrix.of(context).client.clearCache();
                          try {
                            await Matrix.of(context).client.logout();
                          } catch (_) {}
                        },
                      );
                      if (!context.mounted) return;
                      context.go('/');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on ShareKeysWith {
  String localized(L10n l10n) {
    switch (this) {
      case ShareKeysWith.all:
        return l10n.allDevices;
      case ShareKeysWith.crossVerifiedIfEnabled:
        return l10n.crossVerifiedDevicesIfEnabled;
      case ShareKeysWith.crossVerified:
        return l10n.crossVerifiedDevices;
      case ShareKeysWith.directlyVerifiedOnly:
        return l10n.verifiedDevicesOnly;
    }
  }
}
