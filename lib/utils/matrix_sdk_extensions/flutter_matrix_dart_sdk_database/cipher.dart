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
  return null;
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
