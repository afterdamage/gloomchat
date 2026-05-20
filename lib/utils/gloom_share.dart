import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../widgets/matrix.dart';

abstract class GloomShare {
  static Future<void> share(
    String text,
    BuildContext context, {
    bool copyOnly = false,
  }) async {
    if (PlatformInfos.isMobile && !copyOnly) {
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!PlatformInfos.isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(L10n.of(context).copiedToClipboard),
        ),
      );
    }
    return;
  }

  static Future<void> shareInviteLink(BuildContext context) async {
    final client = Matrix.of(context).client;
    final ownProfile = await client.fetchOwnProfile();
    final inviteLink =
        '${AppConfig.gloomchatInviteUrlPrefix}${Uri.encodeComponent(client.userID!)}';
    await GloomShare.share(
      '${ownProfile.displayName ?? client.userID!} invited you to GloomChat.\n$inviteLink',
      context,
    );
  }
}
