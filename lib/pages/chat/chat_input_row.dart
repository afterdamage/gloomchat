import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:animations/animations.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat/recording_input_row.dart';
import 'package:afterdamage/pages/chat/recording_view_model.dart';
import 'package:afterdamage/utils/other_party_can_receive.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';
import '../../config/themes.dart';
import 'package:afterdamage/theme/dracula_theme.dart';
import 'chat.dart';
import 'input_bar.dart';

class ChatInputRow extends StatelessWidget {
  final ChatController controller;

  const ChatInputRow(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const height = 48.0;

    if (!controller.room.otherPartyCanReceiveMessages) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            L10n.of(context).otherPartyNotLoggedIn,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedTextButtonStyle = TextButton.styleFrom(
      foregroundColor: theme.colorScheme.onTertiaryContainer,
    );

    return RecordingViewModel(
      builder: (context, recordingViewModel) {
        if (recordingViewModel.isRecording) {
          return RecordingInputRow(
            state: recordingViewModel,
            onSend: controller.onVoiceMessageSend,
          );
        }
        return Row(
          crossAxisAlignment: .end,
          mainAxisAlignment: .spaceBetween,
          children: controller.selectMode
              ? <Widget>[
                  if (controller.selectedEvents.every(
                    (event) => event.status == EventStatus.error,
                  ))
                    SizedBox(
                      height: height,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: controller.deleteErrorEventsAction,
                        child: Row(
                          children: <Widget>[
                            const FaIcon(FontAwesomeIcons.trash),
                            Text(L10n.of(context).delete),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: height,
                      child: TextButton(
                        style: selectedTextButtonStyle,
                        onPressed: controller.forwardEventsAction,
                        child: Row(
                          children: <Widget>[
                            const FaIcon(FontAwesomeIcons.chevronLeft),
                            Text(L10n.of(context).forward),
                          ],
                        ),
                      ),
                    ),
                  controller.selectedEvents.length == 1
                      ? controller.selectedEvents.first
                                .getDisplayEvent(controller.timeline!)
                                .status
                                .isSent
                            ? SizedBox(
                                height: height,
                                child: TextButton(
                                  style: selectedTextButtonStyle,
                                  onPressed: controller.replyAction,
                                  child: Row(
                                    children: <Widget>[
                                      Text(L10n.of(context).reply),
                                      const FaIcon(FontAwesomeIcons.chevronRight),
                                    ],
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: height,
                                child: TextButton(
                                  style: selectedTextButtonStyle,
                                  onPressed: controller.sendAgainAction,
                                  child: Row(
                                    children: <Widget>[
                                      Text(L10n.of(context).tryToSendAgain),
                                      const SizedBox(width: 4),
                                      const FaIcon(FontAwesomeIcons.wind, size: 16),
                                    ],
                                  ),
                                ),
                              )
                      : const SizedBox.shrink(),
                ]
              : <Widget>[
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: GloomThemes.animationDuration,
                    curve: GloomThemes.animationCurve,
                    width: controller.sendController.text.isNotEmpty
                        ? 0
                        : height,
                    height: height,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(),
                    clipBehavior: Clip.hardEdge,
                    child: PopupMenuButton<AddPopupMenuActions>(
                      useRootNavigator: true,
                      icon: const FaIcon(FontAwesomeIcons.circlePlus),
                      iconColor: theme.colorScheme.onPrimaryContainer,
                      onSelected: controller.onAddPopupMenuButtonSelected,
                      itemBuilder: (BuildContext context) => [
                        if (PlatformInfos.isMobile)
                          PopupMenuItem(
                            value: AddPopupMenuActions.location,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                child: const FaIcon(FontAwesomeIcons.crosshairs),
                              ),
                              title: Text(L10n.of(context).shareLocation),
                              contentPadding: const EdgeInsets.all(0),
                            ),
                          ),
                        PopupMenuItem(
                          value: AddPopupMenuActions.poll,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              child: const FaIcon(FontAwesomeIcons.squarePollVertical),
                            ),
                            title: Text(L10n.of(context).startPoll),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                        PopupMenuItem(
                          value: AddPopupMenuActions.image,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              child: const FaIcon(FontAwesomeIcons.image),
                            ),
                            title: Text(L10n.of(context).sendImage),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                        PopupMenuItem(
                          value: AddPopupMenuActions.video,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              child: const FaIcon(
                                FontAwesomeIcons.video,
                              ),
                            ),
                            title: Text(L10n.of(context).sendVideo),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                        PopupMenuItem(
                          value: AddPopupMenuActions.file,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              child: const FaIcon(FontAwesomeIcons.paperclip),
                            ),
                            title: Text(L10n.of(context).sendFile),
                            contentPadding: const EdgeInsets.all(0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (PlatformInfos.isMobile)
                    AnimatedContainer(
                      duration: GloomThemes.animationDuration,
                      curve: GloomThemes.animationCurve,
                      width: controller.sendController.text.isNotEmpty
                          ? 0
                          : height,
                      height: height,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(),
                      clipBehavior: Clip.hardEdge,
                      child: PopupMenuButton(
                        useRootNavigator: true,
                        icon: const FaIcon(FontAwesomeIcons.camera),
                        onSelected: controller.onAddPopupMenuButtonSelected,
                        iconColor: theme.colorScheme.onPrimaryContainer,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: AddPopupMenuActions.videoCamera,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                foregroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: const FaIcon(FontAwesomeIcons.video),
                              ),
                              title: Text(L10n.of(context).recordAVideo),
                              contentPadding: const EdgeInsets.all(0),
                            ),
                          ),
                          PopupMenuItem(
                            value: AddPopupMenuActions.photoCamera,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                                foregroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: const FaIcon(FontAwesomeIcons.camera),
                              ),
                              title: Text(L10n.of(context).takeAPhoto),
                              contentPadding: const EdgeInsets.all(0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  AnimatedContainer(
                    duration: GloomThemes.animationDuration,
                    curve: GloomThemes.animationCurve,
                    width: controller.sendController.text.isNotEmpty
                        ? 0
                        : height,
                    height: height,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(),
                    clipBehavior: Clip.hardEdge,
                    child: PopupMenuButton<int>(
                      useRootNavigator: true,
                      tooltip: 'Burn on Read',
                      initialValue: controller.burnTime,
                      icon: FaIcon(
                        FontAwesomeIcons.fire,
                        color: controller.burnTime > 0
                            ? Colors.orange
                            : theme.colorScheme.onPrimaryContainer,
                        size: 16,
                      ),
                      onSelected: controller.setBurnTime,
                      itemBuilder: (context) => [
                        const PopupMenuItem<int>(
                          value: 0,
                          child: Text('Off'),
                        ),
                        const PopupMenuItem<int>(
                          value: 3,
                          child: Text('3 seconds'),
                        ),
                        const PopupMenuItem<int>(
                          value: 5,
                          child: Text('5 seconds'),
                        ),
                        const PopupMenuItem<int>(
                          value: 10,
                          child: Text('10 seconds'),
                        ),
                        const PopupMenuItem<int>(
                          value: 30,
                          child: Text('30 seconds'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: height,
                    width: height,
                    alignment: Alignment.center,
                    child: IconButton(
                      tooltip: L10n.of(context).emojis,
                      color: theme.colorScheme.onPrimaryContainer,
                      icon: PageTransitionSwitcher(
                        transitionBuilder: (
                          Widget child,
                          Animation<double> primaryAnimation,
                          Animation<double> secondaryAnimation,
                        ) {
                          return SharedAxisTransition(
                            animation: primaryAnimation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Colors.transparent,
                            child: child,
                          );
                        },
                        child: FaIcon(
                          controller.showEmojiPicker
                              ? FontAwesomeIcons.keyboard
                              : FontAwesomeIcons.faceSmile,
                          key: ValueKey(controller.showEmojiPicker),
                        ),
                      ),
                      onPressed: controller.emojiPickerAction,
                    ),
                  ),
                  if (Matrix.of(context).isMultiAccount &&
                      Matrix.of(context).hasComplexBundles &&
                      Matrix.of(context).currentBundle!.length > 1)
                    Container(
                      height: height,
                      width: height,
                      alignment: Alignment.center,
                      child: _ChatAccountPicker(controller),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: InputBar(
                        room: controller.room,
                        minLines: 1,
                        maxLines: 8,
                        autofocus: !PlatformInfos.isMobile,
                        keyboardType: TextInputType.multiline,
                        textInputAction:
                            AppSettings.sendOnEnter.value == true &&
                                PlatformInfos.isMobile
                            ? TextInputAction.send
                            : null,
                        onSubmitted: controller.onInputBarSubmitted,
                        onSubmitImage: controller.sendImageFromClipBoard,
                        focusNode: controller.inputFocus,
                        controller: controller.sendController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                            left: DraculaTheme.spacingSm,
                            right: DraculaTheme.spacingSm,
                            bottom: DraculaTheme.spacingSm,
                            top: DraculaTheme.spacingXs,
                          ),
                          counter: const SizedBox.shrink(),
                          hintText: L10n.of(context).writeAMessage,
                          hintMaxLines: 1,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: controller.onInputBarChanged,
                        suggestionEmojis:
                            getDefaultEmojiLocale(
                              AppSettings.emojiSuggestionLocale.value.isNotEmpty
                                  ? Locale(
                                      AppSettings.emojiSuggestionLocale.value,
                                    )
                                  : Localizations.localeOf(context),
                            ).fold(
                              [],
                              (emojis, category) =>
                                  emojis..addAll(category.emoji),
                            ),
                      ),
                    ),
                  ),
                  Container(
                    height: height,
                    width: height,
                    alignment: Alignment.center,
                    child:
                        PlatformInfos.platformCanRecord &&
                            controller.sendController.text.isEmpty
                        ? IconButton(
                            tooltip: L10n.of(context).voiceMessage,
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      L10n.of(
                                        context,
                                      ).longPressToRecordVoiceMessage,
                                    ),
                                  ),
                                ),
                            onLongPress: () => recordingViewModel
                                .startRecording(controller.room),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.bubbleColor,
                              foregroundColor: theme.onBubbleColor,
                            ),
                            icon: const FaIcon(FontAwesomeIcons.microphone),
                          )
                        : IconButton(
                            tooltip: L10n.of(context).send,
                            onPressed: controller.send,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.bubbleColor,
                              foregroundColor: theme.onBubbleColor,
                            ),
                            icon: const FaIcon(FontAwesomeIcons.wind),
                          ),
                  ),
                ],
        );
      },
    );
  }
}

class _ChatAccountPicker extends StatelessWidget {
  final ChatController controller;

  const _ChatAccountPicker(this.controller);

  void _popupMenuButtonSelected(String mxid, BuildContext context) {
    final client = Matrix.of(
      context,
    ).currentBundle!.firstWhere((cl) => cl!.userID == mxid, orElse: () => null);
    if (client == null) {
      Logs().w('Attempted to switch to a non-existing client $mxid');
      return;
    }
    controller.setSendingClient(client);
  }

  @override
  Widget build(BuildContext context) {
    final clients = controller.currentRoomBundle;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<Profile>(
        future: controller.sendingClient.fetchOwnProfile(),
        builder: (context, snapshot) => PopupMenuButton<String>(
          useRootNavigator: true,
          onSelected: (mxid) => _popupMenuButtonSelected(mxid, context),
          itemBuilder: (BuildContext context) => clients
              .map(
                (client) => PopupMenuItem(
                  value: client!.userID,
                  child: FutureBuilder<Profile>(
                    future: client.fetchOwnProfile(),
                    builder: (context, snapshot) => ListTile(
                      leading: Avatar(
                        mxContent: snapshot.data?.avatarUrl,
                        name:
                            snapshot.data?.displayName ??
                            client.userID!.localpart,
                        size: 20,
                      ),
                      title: Text(snapshot.data?.displayName ?? client.userID!),
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              )
              .toList(),
          child: Avatar(
            mxContent: snapshot.data?.avatarUrl,
            name:
                snapshot.data?.displayName ??
                Matrix.of(context).client.userID!.localpart,
            size: 20,
          ),
        ),
      ),
    );
  }
}
