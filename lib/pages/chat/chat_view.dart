import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:badges/badges.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat/chat.dart';
import 'package:afterdamage/pages/chat/chat_app_bar_list_tile.dart';
import 'package:afterdamage/pages/chat/chat_app_bar_title.dart';
import 'package:afterdamage/pages/chat/chat_event_list.dart';
import 'package:afterdamage/pages/chat/encryption_button.dart';
import 'package:afterdamage/pages/chat/pinned_events.dart';
import 'package:afterdamage/pages/chat/reply_display.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/utils/account_config.dart';
import 'package:afterdamage/utils/localized_exception_extension.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip_plugin.dart';
import 'package:afterdamage/widgets/chat_settings_popup_menu.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/mxc_image.dart';
import 'package:afterdamage/widgets/unread_rooms_badge.dart';
import '../../utils/stream_extension.dart';
import 'chat_emoji_picker.dart';
import 'chat_input_row.dart';

enum _EventContextAction { info, report }

class ChatView extends StatelessWidget {
  final ChatController controller;

  const ChatView(this.controller, {super.key});

  List<Widget> _appBarActions(BuildContext context) {
    if (controller.selectMode) {
      return [
        if (controller.canEditSelectedEvents)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare),
            tooltip: L10n.of(context).edit,
            onPressed: controller.editSelectedEventAction,
          ),
        if (controller.selectedEvents.length == 1 &&
            controller.activeThreadId == null &&
            controller.room.canSendDefaultMessages)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.comment),
            tooltip: L10n.of(context).replyInThread,
            onPressed: () => controller.enterThread(
              controller.selectedEvents.single.eventId,
            ),
          ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.copy),
          tooltip: L10n.of(context).copyToClipboard,
          onPressed: controller.copyEventsAction,
        ),
        if (controller.canRedactSelectedEvents)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.trash),
            tooltip: L10n.of(context).redactMessage,
            onPressed: controller.redactEventsAction,
          ),
        if (controller.selectedEvents.length == 1)
          PopupMenuButton<_EventContextAction>(
            useRootNavigator: true,
            onSelected: (action) {
              switch (action) {
                case _EventContextAction.info:
                  controller.showEventInfo();
                  controller.clearSelectedEvents();
                  break;
                case _EventContextAction.report:
                  controller.reportEventAction();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (controller.canPinSelectedEvents)
                PopupMenuItem(
                  onTap: controller.pinEvent,
                  value: null,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const FaIcon(FontAwesomeIcons.thumbtack),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).pinMessage),
                    ],
                  ),
                ),
              if (controller.canSaveSelectedEvent)
                PopupMenuItem(
                  onTap: () => controller.saveSelectedEvent(context),
                  value: null,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const FaIcon(FontAwesomeIcons.download),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).downloadFile),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: _EventContextAction.info,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    const FaIcon(FontAwesomeIcons.circleInfo),
                    const SizedBox(width: 12),
                    Text(L10n.of(context).messageInfo),
                  ],
                ),
              ),
              if (controller.selectedEvents.single.status.isSent)
                PopupMenuItem(
                  value: _EventContextAction.report,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const FaIcon(FontAwesomeIcons.shield, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).reportMessage),
                    ],
                  ),
                ),
            ],
          ),
      ];
    } else if (!controller.room.isArchived) {
      return [
        if (controller.room.isDirectChat)
          IconButton(
            onPressed: controller.onVoiceCallTap,
            icon: const FaIcon(FontAwesomeIcons.phone),
            tooltip: L10n.of(context).voiceCall,
          ),
        if (controller.room.isDirectChat)
          IconButton(
            onPressed: controller.onVideoCallTap,
            icon: const FaIcon(FontAwesomeIcons.video),
            tooltip: L10n.of(context).videoCall,
          ),
        if (!controller.room.isDirectChat)
          IconButton(
            onPressed: controller.onGroupCallButtonTap,
            icon: const FaIcon(FontAwesomeIcons.video),
            tooltip: L10n.of(context).videoCall,
          ),
        EncryptionButton(controller.room),
        ChatSettingsPopupMenu(controller.room, true),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.room.membership == Membership.invite) {
      showFutureLoadingDialog(
        context: context,
        future: () => controller.room.join(),
        exceptionContext: ExceptionContext.joinRoom,
      );
    }
    final bottomSheetPadding = GloomThemes.isColumnMode(context) ? 16.0 : 8.0;
    final scrollUpBannerEventId = controller.scrollUpBannerEventId;

    final accountConfig = Matrix.of(context).client.applicationAccountConfig;

    return PopScope(
      canPop:
          controller.selectedEvents.isEmpty &&
          !controller.showEmojiPicker &&
          controller.activeThreadId == null,
      onPopInvokedWithResult: (pop, _) async {
        if (pop) return;
        if (controller.selectedEvents.isNotEmpty) {
          controller.clearSelectedEvents();
        } else if (controller.showEmojiPicker) {
          controller.emojiPickerAction();
        } else if (controller.activeThreadId != null) {
          controller.closeThread();
        }
      },
      child: StreamBuilder(
        stream: controller.room.client.onRoomState.stream
            .where((update) => update.roomId == controller.room.id)
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, snapshot) => FutureBuilder(
          future: controller.loadTimelineFuture,
          builder: (BuildContext context, snapshot) {
            var appbarBottomHeight = 0.0;
            final activeThreadId = controller.activeThreadId;
            if (activeThreadId != null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            if (controller.room.pinnedEventIds.isNotEmpty &&
                activeThreadId == null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            if (scrollUpBannerEventId != null && activeThreadId == null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            return Scaffold(
              appBar: AppBar(
                actionsIconTheme: IconThemeData(
                  color: controller.selectedEvents.isEmpty
                      ? null
                      : theme.colorScheme.onTertiaryContainer,
                ),
                backgroundColor: controller.selectedEvents.isEmpty
                    ? controller.activeThreadId != null
                          ? theme.colorScheme.secondaryContainer
                          : null
                    : theme.colorScheme.tertiaryContainer,
                automaticallyImplyLeading: false,
                leading: controller.selectMode
                    ? IconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark),
                        onPressed: controller.clearSelectedEvents,
                        tooltip: L10n.of(context).close,
                        color: theme.colorScheme.onTertiaryContainer,
                      )
                    : activeThreadId != null
                    ? IconButton(
                        icon: const FaIcon(FontAwesomeIcons.xmark),
                        onPressed: controller.closeThread,
                        tooltip: L10n.of(context).backToMainChat,
                        color: theme.colorScheme.onSecondaryContainer,
                      )
                    : GloomThemes.isColumnMode(context)
                    ? null
                    : StreamBuilder<Object>(
                        stream: Matrix.of(context).client.onSync.stream.where(
                          (syncUpdate) => syncUpdate.hasRoomUpdate,
                        ),
                        builder: (context, _) => UnreadRoomsBadge(
                          filter: (r) => r.id != controller.roomId,
                          badgePosition: BadgePosition.topEnd(end: 8, top: 4),
                          child: const Center(child: BackButton()),
                        ),
                      ),
                titleSpacing: GloomThemes.isColumnMode(context) ? 24 : 0,
                title: ChatAppBarTitle(controller),
                actions: _appBarActions(context),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(appbarBottomHeight),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      PinnedEvents(controller),
                      if (activeThreadId != null)
                        SizedBox(
                          height: ChatAppBarListTile.fixedHeight,
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  controller.scrollToEventId(activeThreadId),
                              icon: const FaIcon(FontAwesomeIcons.solidComment),
                              label: Text(L10n.of(context).replyInThread),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (scrollUpBannerEventId != null &&
                          activeThreadId == null)
                        ChatAppBarListTile(
                          leading: IconButton(
                            color: theme.colorScheme.onSurfaceVariant,
                            icon: const FaIcon(FontAwesomeIcons.xmark),
                            tooltip: L10n.of(context).close,
                            onPressed: () {
                              controller.discardScrollUpBannerEventId();
                              controller.setReadMarker();
                            },
                          ),
                          title: L10n.of(context).jumpToLastReadMessage,
                          trailing: TextButton(
                            onPressed: () {
                              controller.scrollToEventId(scrollUpBannerEventId);
                              controller.discardScrollUpBannerEventId();
                            },
                            child: Text(L10n.of(context).jump),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              floatingActionButton:
                  controller.showScrollDownButton &&
                      controller.selectedEvents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 56.0),
                      child: FloatingActionButton(
                        onPressed: controller.scrollDown,
                        heroTag: null,
                        mini: true,
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.onSurface,
                        child: const FaIcon(FontAwesomeIcons.arrowDown),
                      ),
                    )
                  : null,
              body: DropTarget(
                onDragDone: controller.onDragDone,
                onDragEntered: controller.onDragEntered,
                onDragExited: controller.onDragExited,
                child: Stack(
                  children: <Widget>[
                    if (accountConfig.wallpaperUrl != null)
                      Opacity(
                        opacity: accountConfig.wallpaperOpacity ?? 0.5,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: accountConfig.wallpaperBlur ?? 0.0,
                            sigmaY: accountConfig.wallpaperBlur ?? 0.0,
                          ),
                          child: MxcImage(
                            cacheKey: accountConfig.wallpaperUrl.toString(),
                            uri: accountConfig.wallpaperUrl,
                            fit: BoxFit.cover,
                            height: MediaQuery.sizeOf(context).height,
                            width: MediaQuery.sizeOf(context).width,
                            isThumbnail: false,
                            placeholder: (_) => Container(),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.clearSingleSelectedEvent,
                              child: ChatEventList(controller: controller),
                            ),
                          ),
                          if (controller.showScrollDownButton)
                            Divider(height: 1, color: theme.dividerColor),
                          if (controller.room.isExtinct)
                            Container(
                              margin: EdgeInsets.all(bottomSheetPadding),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const FaIcon(FontAwesomeIcons.chevronRight),
                                label: Text(L10n.of(context).enterNewChat),
                                onPressed: controller.goToNewRoomAction,
                              ),
                            )
                          else if (controller.room.canSendDefaultMessages &&
                              controller.room.membership == Membership.join)
                            Container(
                              margin: EdgeInsets.all(bottomSheetPadding),
                              constraints: const BoxConstraints(
                                maxWidth: GloomThemes.maxTimelineWidth,
                              ),
                              alignment: Alignment.center,
                              child: Material(
                                clipBehavior: Clip.hardEdge,
                                color: controller.selectedEvents.isNotEmpty
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.zero,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.zero,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow
                                            .withOpacity(0.2),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: controller.room.isAbandonedDMRoom == true
                                    ? Row(
                                        mainAxisAlignment: .spaceEvenly,
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.all(16),
                                              foregroundColor:
                                                  theme.colorScheme.error,
                                            ),
                                            icon: const Icon(
                                              FontAwesomeIcons.boxArchive,
                                            ),
                                            onPressed: controller.leaveChat,
                                            label: Text(L10n.of(context).leave),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.all(16),
                                            ),
                                            icon: const Icon(
                                              FontAwesomeIcons.comments,
                                            ),
                                            onPressed: controller.recreateChat,
                                            label: Text(
                                              L10n.of(context).reopenChat,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: .min,
                                        children: [
                                          if (!PlatformInfos.isWeb &&
                                              !PlatformInfos.isDesktop)
                                            ChatEmojiPicker(controller),
                                          ReplyDisplay(controller),
                                          ChatInputRow(controller),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (PlatformInfos.isWeb || PlatformInfos.isDesktop)
                      Positioned(
                        bottom: 72,
                        right: 8,
                        child: ChatEmojiPicker(controller),
                      ),
                    if (controller.dragging)
                      Container(
                        color: theme.scaffoldBackgroundColor.withAlpha(230),
                        alignment: Alignment.center,
                        child: const FaIcon(FontAwesomeIcons.upload, size: 100),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
