import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/settings_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'settings_advanced.dart';

class AdvancedSettingsView extends StatelessWidget {
  final AdvancedSettingsController controller;

  const AdvancedSettingsView(this.controller, {super.key});

  Future<void> _setNotificationDeliveryEndpoint(BuildContext context) async {
    final currentValue = AppSettings.pushNotificationsGatewayUrl.value;
    final l10n = L10n.of(context);
    final value = await showTextInputDialog(
      context: context,
      title: l10n.useCustomNotificationDelivery,
      hintText: AppSettings.pushNotificationsGatewayUrl.defaultValue,
      initialText: currentValue,
      message: l10n.useCustomNotificationDeliveryDialogDescription,
    );
    if (value == null || value.trim().isEmpty) return;
    await AppSettings.pushNotificationsGatewayUrl.setItem(value.trim());
  }

  Future<void> _clearCache(BuildContext context) async {
    final l10n = L10n.of(context);
    final consent = await showOkCancelAlertDialog(
      context: context,
      title: l10n.freeUpStorageSpace,
      message: l10n.freeUpStorageSpaceDialogDescription,
      okLabel: l10n.freeSpaceAction,
      cancelLabel: l10n.cancel,
    );
    if (consent != OkCancelResult.ok || !context.mounted) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).client.clearCache(),
    );
  }

  Future<void> _setStringSetting(
    BuildContext context,
    AppSettings<String> setting,
    String title,
    String dialogDescription,
  ) async {
    final value = await showTextInputDialog(
      context: context,
      title: title,
      hintText: setting.defaultValue,
      initialText: setting.value,
      message: dialogDescription,
    );
    if (value == null) return;
    await setting.setItem(value.trim());
  }

  Future<void> _setIntSetting(
    BuildContext context,
    AppSettings<int> setting,
    String title,
    String dialogDescription,
  ) async {
    final value = await showTextInputDialog(
      context: context,
      title: title,
      hintText: setting.defaultValue.toString(),
      initialText: setting.value.toString(),
      message: dialogDescription,
    );
    if (value == null) return;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).invalidInput)),
        );
      }
      return;
    }
    await setting.setItem(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final isDefaultGateway =
        AppSettings.pushNotificationsGatewayUrl.value ==
        AppSettings.pushNotificationsGatewayUrl.defaultValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advancedSettings),
        automaticallyImplyLeading: !GloomThemes.isColumnMode(context),
        centerTitle: GloomThemes.isColumnMode(context),
      ),
      body: MaxWidthBody(
        child: Column(
          children: [
            // Messages
            ListTile(
              title: Text(
                l10n.messages,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.showFormattedMessagesPlain,
              subtitle: l10n.showFormattedMessagesPlainDescription,
              setting: AppSettings.renderHtml,
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_outlined),
              title: Text(l10n.textMessageMaxLengthTitle),
              subtitle: Text(
                '${l10n.textMessageMaxLengthDescription} (${AppSettings.textMessageMaxLength.value})',
              ),
              onTap: () async {
                await _setIntSetting(
                  context,
                  AppSettings.textMessageMaxLength,
                  l10n.textMessageMaxLengthTitle,
                  l10n.textMessageMaxLengthDialogDescription,
                );
                if (context.mounted) controller.setState(() {});
              },
            ),
            Divider(color: theme.dividerColor),
            // Notifications
            ListTile(
              title: Text(
                l10n.notifications,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l10n.useCustomNotificationDelivery),
              subtitle: Text(
                isDefaultGateway
                    ? l10n.useCustomNotificationDeliveryDescriptionDefault
                    : l10n.useCustomNotificationDeliveryDescriptionCustom,
              ),
              onTap: () async {
                await _setNotificationDeliveryEndpoint(context);
                if (context.mounted) controller.setState(() {});
              },
            ),
            Divider(color: theme.dividerColor),
            // Privacy
            ListTile(
              title: Text(
                l10n.privacy,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.blockScreenshots,
              subtitle: l10n.blockScreenshotsDescription,
              setting: AppSettings.blockScreenshots,
            ),
            Divider(color: theme.dividerColor),
            // Session
            ListTile(
              title: Text(
                l10n.account,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.enableSoftLogout,
              subtitle: l10n.enableSoftLogoutDescription,
              setting: AppSettings.enableSoftLogout,
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.enableMatrixNativeOIDC,
              subtitle: l10n.enableMatrixNativeOIDCDescription,
              setting: AppSettings.enableMatrixNativeOIDC,
            ),
            Divider(color: theme.dividerColor),
            // Video calls
            ListTile(
              title: Text(
                l10n.videoCalls,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.jitsiFeatureTitle,
              subtitle: l10n.jitsiFeatureDescription,
              setting: AppSettings.jitsiFeature,
            ),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(l10n.jitsiDomainTitle),
              subtitle: Text(
                '${l10n.jitsiDomainDescription} (${AppSettings.jitsiDomain.value})',
              ),
              onTap: () async {
                await _setStringSetting(
                  context,
                  AppSettings.jitsiDomain,
                  l10n.jitsiDomainTitle,
                  l10n.jitsiDomainDialogDescription,
                );
                if (context.mounted) controller.setState(() {});
              },
            ),
            Divider(color: theme.dividerColor),
            // Voice message recording
            ListTile(
              title: Text(
                l10n.audioRecordingSection,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.audioRecordingAutoGain,
              subtitle: l10n.audioRecordingAutoGainDescription,
              setting: AppSettings.audioRecordingAutoGain,
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.audioRecordingEchoCancel,
              subtitle: l10n.audioRecordingEchoCancelDescription,
              setting: AppSettings.audioRecordingEchoCancel,
            ),
            SettingsSwitchListTile.adaptive(
              title: l10n.audioRecordingNoiseSuppress,
              subtitle: l10n.audioRecordingNoiseSuppressDescription,
              setting: AppSettings.audioRecordingNoiseSuppress,
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq_outlined),
              title: Text(l10n.audioRecordingBitRate),
              subtitle: Text(
                '${l10n.audioRecordingBitRateDescription} (${AppSettings.audioRecordingBitRate.value})',
              ),
              onTap: () async {
                await _setIntSetting(
                  context,
                  AppSettings.audioRecordingBitRate,
                  l10n.audioRecordingBitRate,
                  l10n.audioRecordingBitRateDialogDescription,
                );
                if (context.mounted) controller.setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.waves_outlined),
              title: Text(l10n.audioRecordingSamplingRate),
              subtitle: Text(
                '${l10n.audioRecordingSamplingRateDescription} (${AppSettings.audioRecordingSamplingRate.value})',
              ),
              onTap: () async {
                await _setIntSetting(
                  context,
                  AppSettings.audioRecordingSamplingRate,
                  l10n.audioRecordingSamplingRate,
                  l10n.audioRecordingSamplingRateDialogDescription,
                );
                if (context.mounted) controller.setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_outlined),
              title: Text(l10n.audioRecordingNumChannels),
              subtitle: Text(
                '${l10n.audioRecordingNumChannelsDescription} (${AppSettings.audioRecordingNumChannels.value})',
              ),
              onTap: () async {
                await _setIntSetting(
                  context,
                  AppSettings.audioRecordingNumChannels,
                  l10n.audioRecordingNumChannels,
                  l10n.audioRecordingNumChannelsDialogDescription,
                );
                if (context.mounted) controller.setState(() {});
              },
            ),
            Divider(color: theme.dividerColor),
            // Storage & diagnostics
            ListTile(
              title: Text(
                l10n.storageAndDiagnostics,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(l10n.freeUpStorageSpace),
              subtitle: Text(l10n.freeUpStorageSpaceDescription),
              onTap: () => _clearCache(context),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(l10n.showDetailedConnectionLogs),
              subtitle: Text(l10n.showDetailedConnectionLogsDescription),
              onTap: () => context.go('/logs'),
            ),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: Text(l10n.moreAdvancedOptions),
              subtitle: Text(l10n.moreAdvancedOptionsDescription),
              onTap: () => context.go('/configs'),
            ),
            Divider(color: theme.dividerColor),
          ],
        ),
      ),
    );
  }
}
