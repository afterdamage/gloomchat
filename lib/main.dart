import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/utils/client_manager.dart';
import 'package:afterdamage/utils/notification_background_handler.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:screen_protector/screen_protector.dart';
import 'config/setting_keys.dart';
import 'utils/background_push.dart';
import 'widgets/gloom_chat_app.dart';

ReceivePort? mainIsolateReceivePort;

void main() async {
  if (PlatformInfos.isAndroid) {
    final port = mainIsolateReceivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(AppConfig.mainIsolatePortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      AppConfig.mainIsolatePortName,
    );
    await waitForPushIsolateDone();
  }

  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();

  final store = await AppSettings.init();
  Logs().i('Welcome to ${AppSettings.applicationName.value} <3');

  if (!PlatformInfos.isWeb) {
    if (AppSettings.blockScreenshots.value) {
      try { await ScreenProtector.preventScreenshotOn(); } catch(e) {}
    }

    try {
      await vod.init(wasmPath: './assets/assets/vodozemac/');
    } catch (e) {
      Logs().w('Failed to initialize vodozemac (encryption will not work): $e');
    }
  } else {
    Logs().w('Skipping vodozemac initialization on web (encryption disabled)');
  }

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients(store: store);

  // If the app starts in detached mode, we assume that it is in
  // background fetch mode for processing push notifications. This is
  // currently only supported on Android.
  if (PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState) {
    // Do not send online presences when app is in background fetch mode.
    for (final client in clients) {
      client.backgroundSync = false;
      client.syncPresence = PresenceType.offline;
    }

    // In the background fetch mode we do not want to waste ressources with
    // starting the Flutter engine but process incoming push notifications.
    BackgroundPush.clientOnly(clients.first);
    // To start the flutter engine afterwards we add an custom observer.
    WidgetsBinding.instance.addObserver(AppStarter(clients, store));
    Logs().i(
      '${AppSettings.applicationName.value} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
    );
    return;
  }

  // Started in foreground mode.
  Logs().i(
    '${AppSettings.applicationName.value} started in foreground mode. Rendering GUI...',
  );
  await startGui(clients, store);
}

/// Fetch the pincode for the applock and start the flutter engine.
Future<void> startGui(List<Client> clients, SharedPreferences store) async {
  // Fetch the pin for the applock if existing for mobile applications.
  String? pin;
  if (PlatformInfos.isMobile) {
    try {
      pin = await const FlutterSecureStorage().read(
        key: 'im.gloomchat.app_lock',
      );
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }

  runZonedGuarded(
    () => runApp(GloomChatApp(clients: clients, pincode: pin, store: store)),
    (error, stack) {
      // Swallow 429 rate-limit errors from the Matrix SDK (e.g.
      // m.call.sdp_stream_metadata_changed). These are harmless
      // but the SDK doesn't catch them, causing Uncaught Error crashes.
      final msg = error.toString();
      if (msg.contains('429') || msg.contains('Too Many Requests')) {
        Logs().w('Rate-limited by server (429), ignoring: $msg');
        return;
      }
      if (msg.contains('NotAllowedError') || msg.contains('play()')) {
        Logs().w('Autoplay blocked by browser, ignoring: $msg');
        return;
      }
      Logs().e('Uncaught error', error, stack);
    },
  );
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  final SharedPreferences store;
  bool guiStarted = false;

  AppStarter(this.clients, this.store);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (guiStarted) return;
    if (state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppSettings.applicationName.value} switches from the detached background-fetch mode to ${state.name} mode. Rendering GUI...',
    );
    // Switching to foreground mode needs to reenable send online sync presence.
    for (final client in clients) {
      client.backgroundSync = true;
      client.syncPresence = PresenceType.online;
    }
    startGui(clients, store);
    // We must make sure that the GUI is only started once.
    guiStarted = true;
  }
}
