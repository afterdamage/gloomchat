import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix_api_lite/utils/logs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afterdamage/utils/platform_infos.dart';

enum AppSettings<T> {
  textMessageMaxLength<int>('textMessageMaxLength', 16384),
  audioRecordingNumChannels<int>('audioRecordingNumChannels', 1),
  audioRecordingAutoGain<bool>('audioRecordingAutoGain', true),
  audioRecordingEchoCancel<bool>('audioRecordingEchoCancel', false),
  audioRecordingNoiseSuppress<bool>('audioRecordingNoiseSuppress', true),
  audioRecordingBitRate<int>('audioRecordingBitRate', 64000),
  audioRecordingSamplingRate<int>('audioRecordingSamplingRate', 44100),
  showNoGoogle<bool>('chat.gloom.show_no_google', false),
  unifiedPushRegistered<bool>('chat.gloom.unifiedpush.registered', false),
  unifiedPushEndpoint<String>('chat.gloom.unifiedpush.endpoint', ''),
  pushNotificationsGatewayUrl<String>(
    'pushNotificationsGatewayUrl',
    'https://matrix.org/_matrix/push/v1/notify',
  ),
  pushNotificationsPusherFormat<String>(
    'pushNotificationsPusherFormat',
    'event_id_only',
  ),
  renderHtml<bool>('chat.gloom.renderHtml', true),
  fontSizeFactor<double>('chat.gloom.font_size_factor', 1.0),
  hideRedactedEvents<bool>('chat.gloom.hideRedactedEvents', false),
  hideUnknownEvents<bool>('chat.gloom.hideUnknownEvents', true),
  autoplayImages<bool>('chat.gloom.autoplay_images', true),
  sendTypingNotifications<bool>('chat.gloom.send_typing_notifications', true),
  sendPublicReadReceipts<bool>('chat.gloom.send_public_read_receipts', true),
  swipeRightToLeftToReply<bool>('chat.gloom.swipeRightToLeftToReply', true),
  sendOnEnter<bool>('chat.gloom.send_on_enter', false),
  showPresences<bool>('chat.gloom.show_presences', false),
  displayNavigationRail<bool>('chat.gloom.display_navigation_rail', false),
  experimentalVoip<bool>('chat.gloom.experimental_voip', true),
  shareKeysWith<String>('chat.gloom.share_keys_with_2', 'all'),
  noEncryptionWarningShown<bool>(
    'chat.gloom.no_encryption_warning_shown',
    false,
  ),
  displayChatDetailsColumn('chat.gloom.display_chat_details_column', false),
  // AppConfig-mirrored settings
  applicationName<String>('chat.gloom.application_name', 'GloomChat'),
  defaultHomeserver<String>('chat.gloom.default_homeserver', 'matrix.org'),
  // colorSchemeSeed stored as ARGB int
  colorSchemeSeedInt<int>('chat.gloom.color_scheme_seed', 0xFF5625BA),
  // Dracula accent theme (purple, cyan, green, orange, pink, red, yellow)
  draculaAccent<String>('chat.gloom.dracula_accent', 'red'),
  // Background color stored as ARGB int, 0 = use theme default
  backgroundColorLight<int>('chat.gloom.background_color_light', 0),
  backgroundColorDark<int>('chat.gloom.background_color_dark', 0),
  emojiSuggestionLocale<String>('emoji_suggestion_locale', ''),
  blockScreenshots<bool>('chat.goth.block_screenshots', false),
  decoyMode<bool>('chat.goth.decoy_mode', false),
  enableSoftLogout<bool>('chat.gloom.enable_soft_logout', false),
  enableMatrixNativeOIDC<bool>('chat.gloom.enable_matrix_native_oidc', false),
  jitsiFeature<bool>('chat.gloom.enable_jitsi', false),
  jitsiDomain<String>('chat.gloom.jitsi_domain', 'meet.jit.si'),
  presetHomeserver<String>('chat.gloom.preset_homeserver', ''),
  welcomeText<String>('chat.gloom.welcome_text', ''),
  website<String>('chat.gloom.website_url', ''),
  logoUrl<String>('chat.gloom.logo_url', ''),
  privacyPolicy<String>('chat.gloom.privacy_policy_url', ''),
  tos<String>('chat.gloom.tos_url', ''),
  sendTimelineEventTimeout<int>('chat.gloom.send_timeline_event_timeout', 15),
  lastSeenSupportBanner<int>('chat.gloom.last_seen_support_banner', 0),
  supportBannerOptOut<bool>('chat.gloom.support_banner_opt_out', false);

  final String key;
  final T defaultValue;

  const AppSettings(this.key, this.defaultValue);

  static SharedPreferences get store => _store!;
  static SharedPreferences? _store;

  static Future<void> reset({bool loadWebConfigFile = true}) async {
    await AppSettings._store!.clear();
    await init(loadWebConfigFile: loadWebConfigFile);
  }

  static Future<SharedPreferences> init({bool loadWebConfigFile = true}) async {
    if (AppSettings._store != null) return AppSettings.store;

    final store = AppSettings._store = await SharedPreferences.getInstance();

    // Migrate wrong datatype for fontSizeFactor
    final fontSizeFactorString = Result(
      () => store.getString(AppSettings.fontSizeFactor.key),
    ).asValue?.value;
    if (fontSizeFactorString != null) {
      Logs().i('Migrate wrong datatype for fontSizeFactor!');
      await store.remove(AppSettings.fontSizeFactor.key);
      final fontSizeFactor = double.tryParse(fontSizeFactorString);
      if (fontSizeFactor != null) {
        await store.setDouble(AppSettings.fontSizeFactor.key, fontSizeFactor);
      }
    }

    if (store.getBool(AppSettings.sendOnEnter.key) == null) {
      await store.setBool(AppSettings.sendOnEnter.key, !PlatformInfos.isMobile);
    }

    // Migration: clear stale experimentalVoip=false so config.json can apply.
    // Remove this migration after a few releases.
    if (kIsWeb &&
        store.getBool(AppSettings.experimentalVoip.key) == false &&
        store.getBool('chat.gloom.voip_migrated_v1') != true) {
      await store.remove(AppSettings.experimentalVoip.key);
      await store.setBool('chat.gloom.voip_migrated_v1', true);
    }

    if (kIsWeb && loadWebConfigFile) {
      try {
        final configJsonString = utf8.decode(
          (await http.get(Uri.parse('config.json'))).bodyBytes,
        );
        final configJson =
            json.decode(configJsonString) as Map<String, Object?>;
        for (final setting in AppSettings.values) {
          if (store.get(setting.key) != null) continue;
          final configValue = configJson[setting.name];
          if (configValue == null) continue;
          if (configValue is bool) {
            await store.setBool(setting.key, configValue);
          }
          if (configValue is String) {
            await store.setString(setting.key, configValue);
          }
          if (configValue is int) {
            await store.setInt(setting.key, configValue);
          }
          if (configValue is double) {
            await store.setDouble(setting.key, configValue);
          }
        }
      } on FormatException catch (_) {
        Logs().v('[ConfigLoader] config.json not found');
      } catch (e) {
        Logs().v('[ConfigLoader] config.json not found', e);
      }
    }

    return store;
  }
}

extension AppSettingsBoolExtension on AppSettings<bool> {
  bool get value {
    final value = Result(() => AppSettings.store.getBool(key));
    final error = value.asError;
    if (error != null) {
      Logs().e(
        'Unable to fetch $key from storage. Removing entry...',
        error.error,
        error.stackTrace,
      );
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(bool value) => AppSettings.store.setBool(key, value);
}

extension AppSettingsStringExtension on AppSettings<String> {
  String get value {
    final value = Result(() => AppSettings.store.getString(key));
    final error = value.asError;
    if (error != null) {
      Logs().e(
        'Unable to fetch $key from storage. Removing entry...',
        error.error,
        error.stackTrace,
      );
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(String value) => AppSettings.store.setString(key, value);
}

extension AppSettingsIntExtension on AppSettings<int> {
  int get value {
    final value = Result(() => AppSettings.store.getInt(key));
    final error = value.asError;
    if (error != null) {
      Logs().e(
        'Unable to fetch $key from storage. Removing entry...',
        error.error,
        error.stackTrace,
      );
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(int value) => AppSettings.store.setInt(key, value);
}

extension AppSettingsDoubleExtension on AppSettings<double> {
  double get value {
    final value = Result(() => AppSettings.store.getDouble(key));
    final error = value.asError;
    if (error != null) {
      Logs().e(
        'Unable to fetch $key from storage. Removing entry...',
        error.error,
        error.stackTrace,
      );
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(double value) => AppSettings.store.setDouble(key, value);
}
