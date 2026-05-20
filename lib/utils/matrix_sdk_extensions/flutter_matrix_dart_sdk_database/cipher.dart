import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/client_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

const _passwordStorageKey = 'database_password';

Future<String?> getDatabaseCipher() async {
  // The Linux Secret Service (gnome-keyring/KWallet) causes the process to
  // be killed when unavailable. Skip keyring access on Linux.
  if (!kIsWeb && Platform.isLinux) return null;

  String? password;

  try {
    const secureStorage = FlutterSecureStorage();
    const kStorageTimeout = Duration(seconds: 5);
    final existingKey = await secureStorage
        .read(key: _passwordStorageKey)
        .timeout(kStorageTimeout, onTimeout: () => null);
    if (existingKey == null) {
      final rng = Random.secure();
      final list = Uint8List(32);
      list.setAll(0, Iterable.generate(list.length, (i) => rng.nextInt(256)));
      final newPassword = base64UrlEncode(list);
      await secureStorage
          .write(key: _passwordStorageKey, value: newPassword)
          .timeout(kStorageTimeout, onTimeout: () {});
    }
    // workaround for if we just wrote to the key and it still doesn't exist
    password = await secureStorage
        .read(key: _passwordStorageKey)
        .timeout(kStorageTimeout, onTimeout: () => null);
    if (password == null) throw MissingPluginException();
  } on MissingPluginException catch (e) {
    const FlutterSecureStorage()
        .delete(key: _passwordStorageKey)
        .catchError((_) {});
    Logs().w('Database encryption is not supported on this platform', e);
    _sendNoEncryptionWarning(e);
  } catch (e, s) {
    const FlutterSecureStorage()
        .delete(key: _passwordStorageKey)
        .catchError((_) {});
    Logs().w('Unable to init database encryption', e, s);
    _sendNoEncryptionWarning(e);
  }

  return password;
}

Future<void> _sendNoEncryptionWarning(Object exception) async {
  final isStored = AppSettings.noEncryptionWarningShown.value;

  if (isStored == true) return;

  final l10n = await lookupL10n(PlatformDispatcher.instance.locale);
  ClientManager.sendInitNotification(
    l10n.noDatabaseEncryption,
    exception.toString(),
  );

  await AppSettings.noEncryptionWarningShown.setItem(true);
}
