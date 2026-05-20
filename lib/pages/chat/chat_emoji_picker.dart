import 'package:flutter/material.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat/sticker_picker_dialog.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'chat.dart';

class ChatEmojiPicker extends StatelessWidget {
  final ChatController controller;
  const ChatEmojiPicker(this.controller, {super.key});

  /// On web/desktop: floating card (Discord-style).
  /// On mobile: classic bottom-sheet expansion.
  static bool get _useFloating =>
      PlatformInfos.isWeb || PlatformInfos.isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pickerContent = DefaultTabController(
                  length: 2,
                  child: Column( // floating inner
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: L10n.of(context).emojis),
                          Tab(text: L10n.of(context).stickers),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            EmojiPicker(
                              onEmojiSelected: controller.onEmojiSelected,
                              onBackspacePressed:
                                  controller.emojiPickerBackspace,
                              config: Config(
                                locale: Localizations.localeOf(context),
                                checkPlatformCompatibility: false,
                                emojiTextStyle: const TextStyle(
                                  fontFamily: 'Tossface',
                                  fontSize: 28.0,
                                ),
                                emojiViewConfig: EmojiViewConfig(
                                  noRecents: const NoRecent(),
                                  backgroundColor:
                                      theme.colorScheme.onInverseSurface,
                                ),
                                bottomActionBarConfig:
                                    const BottomActionBarConfig(
                                  enabled: false,
                                ),
                                categoryViewConfig: CategoryViewConfig(
                                  backspaceColor: theme.colorScheme.primary,
                                  iconColor: theme.colorScheme.primary
                                      .withAlpha(128),
                                  iconColorSelected: theme.colorScheme.primary,
                                  indicatorColor: theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.surface,
                                ),
                                skinToneConfig: SkinToneConfig(
                                  dialogBackgroundColor: Color.lerp(
                                    theme.colorScheme.surface,
                                    theme.colorScheme.primaryContainer,
                                    0.75,
                                  )!,
                                  indicatorColor: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            StickerPickerDialog(
                              room: controller.room,
                              onSelected: (sticker) {
                                controller.room.sendEvent(
                                  {
                                    'body': sticker.body,
                                    'info': sticker.info ?? {},
                                    'url': sticker.url.toString(),
                                  },
                                  type: EventTypes.Sticker,
                                  threadRootEventId:
                                      controller.activeThreadId,
                                  threadLastEventId:
                                      controller.threadLastEventId,
                                );
                                controller.hideEmojiPicker();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
    );

    if (_useFloating) {
      return IgnorePointer(
        ignoring: !controller.showEmojiPicker,
        child: AnimatedScale(
          scale: controller.showEmojiPicker ? 1.0 : 0.85,
          duration: GloomThemes.animationDuration,
          curve: GloomThemes.animationCurve,
          alignment: Alignment.bottomRight,
          child: AnimatedOpacity(
            opacity: controller.showEmojiPicker ? 1.0 : 0.0,
            duration: GloomThemes.animationDuration,
            curve: GloomThemes.animationCurve,
            child: Material(
              elevation: 12,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.zero,
              shadowColor: Colors.black.withAlpha(80),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: SizedBox(
                  width: 340,
                  height: 310,
                  child: pickerContent,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Mobile: classic animated bottom panel
    return AnimatedContainer(
      duration: GloomThemes.animationDuration,
      curve: GloomThemes.animationCurve,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.zero,
        boxShadow: controller.showEmojiPicker
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      height: controller.showEmojiPicker ? 260.0 : 0,
      child: controller.showEmojiPicker ? pickerContent : null,
    );
  }
}

class NoRecent extends StatelessWidget {
  const NoRecent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          L10n.of(context).emoteKeyboardNoRecents,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
