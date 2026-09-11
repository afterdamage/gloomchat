import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:swipe_to_action/swipe_to_action.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/adaptive_bottom_sheet.dart';
import 'package:afterdamage/utils/date_time_extension.dart';
import 'package:afterdamage/utils/file_description.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/string_color.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/member_actions_popup_menu_button.dart';
import 'package:afterdamage/theme/dracula_theme.dart';
import '../../../config/app_config.dart';
import 'message_content.dart';
import 'message_reactions.dart';
import 'reply_content.dart';
import 'state_message.dart';

final Set<String> _burnedEvents = {};

class Message extends StatelessWidget {
  final Event event;
  final Event? nextEvent;
  final Event? previousEvent;
  final bool displayReadMarker;
  final void Function(Event) onSelect;
  final void Function(Event) onInfoTab;
  final void Function(String) scrollToEventId;
  final void Function() onSwipe;
  final void Function() onMention;
  final void Function() onEdit;
  final void Function(String eventId)? enterThread;
  final bool longPressSelect;
  final bool selected;
  final bool singleSelected;
  final Timeline timeline;
  final bool highlightMarker;
  final bool animateIn;
  final void Function()? resetAnimateIn;
  final bool wallpaperMode;
  final ScrollController scrollController;
  final List<Color> colors;
  final void Function()? onExpand;
  final bool isCollapsed;
  final Set<String> bigEmojis;

  const Message(
    this.event, {
    this.nextEvent,
    this.previousEvent,
    this.displayReadMarker = false,
    this.longPressSelect = false,
    required this.onSelect,
    required this.onInfoTab,
    required this.scrollToEventId,
    required this.onSwipe,
    this.selected = false,
    required this.onEdit,
    required this.singleSelected,
    required this.timeline,
    this.highlightMarker = false,
    this.animateIn = false,
    this.resetAnimateIn,
    this.wallpaperMode = false,
    required this.onMention,
    required this.scrollController,
    required this.colors,
    this.onExpand,
    required this.enterThread,
    this.isCollapsed = false,
    required this.bigEmojis,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!{
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
      EventTypes.CallInvite,
      PollEventContent.startType,
    }.contains(event.type)) {
      if (event.type.startsWith('m.call.')) {
        return const SizedBox.shrink();
      }
      return StateMessage(event, onExpand: onExpand, isCollapsed: isCollapsed);
    }

    if (event.type == EventTypes.Message &&
        event.messageType == EventTypes.KeyVerificationRequest) {
      return StateMessage(event);
    }

    // Goth Matrix: Burn on read logic
    final burnTime = event.content.tryGet<int>('org.goth.burn_time');
    final isBurnMessage = burnTime != null && burnTime > 0;
    final alreadyBurned = _burnedEvents.contains(event.eventId);
    // burnSeconds is only set when the event is live (not yet redacted) and not already burned.
    // FireBurnWrapper owns the countdown timer and plays the animation before calling redactEvent.
    final burnSeconds = (isBurnMessage && !event.redacted && !alreadyBurned) ? burnTime : null;

    final client = Matrix.of(context).client;
    final ownMessage = event.senderId == client.userID;
    final alignment = ownMessage ? Alignment.topRight : Alignment.topLeft;

    var color = theme.colorScheme.surfaceContainerHigh;
    final displayTime =
        event.type == EventTypes.RoomCreate ||
        nextEvent == null ||
        !event.originServerTs.sameEnvironment(nextEvent!.originServerTs);
    final nextEventSameSender =
        nextEvent != null &&
        {
          EventTypes.Message,
          EventTypes.Sticker,
          EventTypes.Encrypted,
        }.contains(nextEvent!.type) &&
        nextEvent!.senderId == event.senderId &&
        !displayTime;

    final previousEventSameSender =
        previousEvent != null &&
        {
          EventTypes.Message,
          EventTypes.Sticker,
          EventTypes.Encrypted,
        }.contains(previousEvent!.type) &&
        previousEvent!.senderId == event.senderId &&
        previousEvent!.originServerTs.sameEnvironment(event.originServerTs);

    final textColor = ownMessage
        ? theme.onBubbleColor
        : theme.colorScheme.onSurface;

    final linkColor = ownMessage
        ? theme.brightness == Brightness.light
              ? theme.colorScheme.primaryFixed
              : theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.primary;

    final rowMainAxisAlignment = ownMessage
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    final displayEvent = event.getDisplayEvent(timeline);
    // Asymmetric bubble geometry:
    // - Main (away from sender) corners: 8px
    // - Sender-side corners: 4px
    // - Grouped same-sender corners: 2px
    const borderRadius = BorderRadius.zero;
    final noBubble =
        ({
              MessageTypes.Video,
              MessageTypes.Image,
              MessageTypes.Sticker,
            }.contains(event.messageType) &&
            event.fileDescription == null &&
            !event.redacted) ||
        (event.messageType == MessageTypes.Text &&
            event.relationshipType == null &&
            event.onlyEmotes &&
            event.numberEmotes > 0 &&
            event.numberEmotes <= 3);

    if (ownMessage) {
      color = displayEvent.status.isError
          ? Colors.redAccent
          : theme.bubbleColor;
    }

    final resetAnimateIn = this.resetAnimateIn;
    var animateIn = this.animateIn;

    final sentReactions = <String>{};
    if (singleSelected) {
      sentReactions.addAll(
        event
            .aggregatedEvents(timeline, RelationshipTypes.reaction)
            .where(
              (event) =>
                  event.senderId == event.room.client.userID &&
                  event.type == 'm.reaction',
            )
            .map(
              (event) => event.content
                  .tryGetMap<String, Object?>('m.relates_to')
                  ?.tryGet<String>('key'),
            )
            .whereType<String>(),
      );
    }

    final showReceiptsRow = event.hasAggregatedEvents(
      timeline,
      RelationshipTypes.reaction,
    );

    final threadChildren = event.aggregatedEvents(
      timeline,
      RelationshipTypes.thread,
    );

    final showReactionPicker =
        singleSelected && event.room.canSendDefaultMessages;

    final enterThread = this.enterThread;

    return Center(
      child: Swipeable(
        key: ValueKey(event.eventId),
        background: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Center(child: FaIcon(FontAwesomeIcons.check)),
        ),
        direction: AppSettings.swipeRightToLeftToReply.value
            ? SwipeDirection.endToStart
            : SwipeDirection.startToEnd,
        onSwipe: (_) => onSwipe(),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: GloomThemes.maxTimelineWidth,
          ),
          padding: EdgeInsets.only(
            left: DraculaTheme.spacingSm,
            right: DraculaTheme.spacingSm,
            top: nextEventSameSender ? 2.0 : DraculaTheme.spacingMd,
            bottom: previousEventSameSender ? 2.0 : DraculaTheme.spacingMd,
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: ownMessage ? .end : .start,
            children: <Widget>[
              if (displayTime || selected)
                Padding(
                  padding: displayTime
                      ? const EdgeInsets.symmetric(vertical: 8.0)
                      : EdgeInsets.zero,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                        child: Material(
                        borderRadius: BorderRadius.zero,
                        color: theme.colorScheme.surface.withValues(alpha: 0.7),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          child: Text(
                            event.originServerTs.localizedTime(context),
                            style: TextStyle(
                              fontSize: 12 * AppSettings.fontSizeFactor.value,
                              fontWeight: FontWeight.w500,
                              color: DraculaTheme.mutedForeground(
                                theme.colorScheme,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              StatefulBuilder(
                builder: (context, setState) {
                  if (animateIn) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      animateIn = false;
                      setState(resetAnimateIn ?? () {});
                    });
                  }
                  return AnimatedSize(
                    duration: GloomThemes.animationDuration,
                    curve: GloomThemes.animationCurve,
                    clipBehavior: Clip.none,
                    alignment: ownMessage
                        ? Alignment.bottomRight
                        : Alignment.bottomLeft,
                    child: (animateIn && !event.status.isSending)
                        ? const SizedBox(height: 0, width: double.infinity)
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: InkWell(
                                  hoverColor: longPressSelect
                                      ? Colors.transparent
                                      : null,
                                  enableFeedback: !selected,
                                  onTap: longPressSelect
                                      ? null
                                      : () => onSelect(event),
                                  borderRadius: BorderRadius.zero,
                                  child: Material(
                                    borderRadius: BorderRadius.zero,
                                    color: selected || highlightMarker
                                        ? theme.colorScheme.secondaryContainer
                                              .withAlpha(128)
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: .start,
                                mainAxisAlignment: rowMainAxisAlignment,
                                children: [
                                  if (longPressSelect && !event.redacted)
                                    SizedBox(
                                      height: 32,
                                      width: Avatar.defaultSize,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        tooltip: L10n.of(context).select,
                                        icon: FaIcon(
                                          selected
                                              ? FontAwesomeIcons.solidCircleCheck
                                              : FontAwesomeIcons.circle,
                                        ),
                                        onPressed: () => onSelect(event),
                                      ),
                                    )
                                  else if (nextEventSameSender || ownMessage)
                                    SizedBox(
                                      width: Avatar.defaultSize,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              event.status == EventStatus.error
                                              ? const FaIcon(
                                                  FontAwesomeIcons.circleExclamation,
                                                  color: Colors.red,
                                                )
                                              : event.fileSendingStatus != null
                                              ? const CircularProgressIndicator(
                                                  strokeWidth: 1,
                                                )
                                              : null,
                                        ),
                                      ),
                                    )
                                  else
                                    FutureBuilder<User?>(
                                      future: event.fetchSenderUser(),
                                      builder: (context, snapshot) {
                                        final user =
                                            snapshot.data ??
                                            event.senderFromMemoryOrFallback;
                                        return Avatar(
                                          mxContent: user.avatarUrl,
                                          name: user.calcDisplayname(),
                                          onTap: () =>
                                              showMemberActionsPopupMenu(
                                                context: context,
                                                user: user,
                                                onMention: onMention,
                                              ),
                                          presenceUserId: user.stateKey,
                                          presenceBackgroundColor: wallpaperMode
                                              ? Colors.transparent
                                              : null,
                                        );
                                      },
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: .start,
                                      mainAxisSize: .min,
                                      children: [
                                        if (!nextEventSameSender)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                              bottom: 4,
                                            ),
                                            child:
                                                ownMessage ||
                                                    event.room.isDirectChat
                                                ? const SizedBox(height: 12)
                                                : FutureBuilder<User?>(
                                                    future: event
                                                        .fetchSenderUser(),
                                                    builder: (context, snapshot) {
                                                      final displayname =
                                                          snapshot.data
                                                              ?.calcDisplayname() ??
                                                          event
                                                              .senderFromMemoryOrFallback
                                                              .calcDisplayname();
                                                      return Text(
                                                        displayname,
                                                        style: theme
                                                            .textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                          color:
                                                              (theme.brightness ==
                                                                  Brightness
                                                                      .light
                                                              ? displayname
                                                                    .color
                                                              : displayname
                                                                    .lightColorText),
                                                          shadows:
                                                              !wallpaperMode
                                                              ? null
                                                              : [
                                                                  const Shadow(
                                                                    offset:
                                                                        Offset(
                                                                          0.0,
                                                                          0.0,
                                                                        ),
                                                                    blurRadius:
                                                                        3,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      );
                                                    },
                                                  ),
                                          ),
                                        Container(
                                          alignment: alignment,
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: GestureDetector(
                                            onLongPress: longPressSelect
                                                ? null
                                                : () {
                                                    HapticFeedback.heavyImpact();
                                                    onSelect(event);
                                                  },
                                            child: FireBurnWrapper(
                                              burnSeconds: burnSeconds,
                                              alreadyBurned: alreadyBurned,
                                              eventId: event.eventId,
                                              onBurnComplete: isBurnMessage ? () {
                                                _burnedEvents.add(event.eventId);
                                                event.room.redactEvent(event.eventId);
                                              } : null,
                                              child: AnimatedOpacity(
                                              opacity: (animateIn && !event.status.isSending)
                                                  ? 0
                                                  : event.messageType ==
                                                            MessageTypes
                                                                .BadEncrypted ||
                                                        event.status.isSending
                                                  ? 0.5
                                                  : 1,
                                              duration: GloomThemes
                                                  .animationDuration,
                                              curve:
                                                  GloomThemes.animationCurve,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: noBubble
                                                      ? Colors.transparent
                                                      : color,
                                                  borderRadius: borderRadius,
                                                  boxShadow: noBubble
                                                      ? null
                                                      : [
                                                          // Subtle shadow for depth
                                                          BoxShadow(
                                                            color: theme
                                                                .colorScheme
                                                                .shadow
                                                                .withValues(
                                                                  alpha: 0.20,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                              0,
                                                              3,
                                                            ),
                                                          ),
                                                          // Subtle accent outline for own messages
                                                          if (ownMessage && theme.brightness == Brightness.dark)
                                                            BoxShadow(
                                                              color: theme.colorScheme.primary
                                                                  .withValues(alpha: 0.10),
                                                              blurRadius: 10,
                                                              spreadRadius: -4,
                                                            ),
                                                        ],
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: BubbleBackground(
                                                  colors: colors,
                                                  ignore:
                                                      noBubble ||
                                                      !ownMessage ||
                                                      MediaQuery.highContrastOf(
                                                        context,
                                                      ),
                                                  scrollController:
                                                      scrollController,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.zero,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth:
                                                              GloomThemes
                                                                  .columnWidth *
                                                              1.5,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize: .min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        if (event.inReplyToEventId(
                                                              includingFallback:
                                                                  false,
                                                            ) !=
                                                            null)
                                                          FutureBuilder<Event?>(
                                                            future: event
                                                                .getReplyEvent(
                                                                  timeline,
                                                                ),
                                                            builder:
                                                                (
                                                                  BuildContext
                                                                  context,
                                                                  snapshot,
                                                                ) {
                                                                  final replyEvent =
                                                                      snapshot
                                                                          .hasData
                                                                      ? snapshot
                                                                            .data!
                                                                      : Event(
                                                                          eventId:
                                                                              event.inReplyToEventId() ??
                                                                              '\$fake_event_id',
                                                                          content: {
                                                                            'msgtype':
                                                                                'm.text',
                                                                            'body':
                                                                                '...',
                                                                          },
                                                                          senderId:
                                                                              event.senderId,
                                                                          type:
                                                                              'm.room.message',
                                                                          room:
                                                                              event.room,
                                                                          status:
                                                                              EventStatus.sent,
                                                                          originServerTs:
                                                                              DateTime.now(),
                                                                        );
                                                                  return Padding(
                                                                    padding:
                                                                        const EdgeInsets.only(
                                                                          left:
                                                                              12,
                                                                          right:
                                                                              12,
                                                                          top:
                                                                              8,
                                                                        ),
                                                                    child: Material(
                                                                      color: Colors
                                                                          .transparent,
                                                                      borderRadius:
                                                                          ReplyContent
                                                                              .borderRadius,
                                                                      child: InkWell(
                                                                        borderRadius:
                                                                            ReplyContent.borderRadius,
                                                                        onTap: () => scrollToEventId(
                                                                          replyEvent
                                                                              .eventId,
                                                                        ),
                                                                        child: AbsorbPointer(
                                                                          child: ReplyContent(
                                                                            replyEvent,
                                                                            ownMessage:
                                                                                ownMessage,
                                                                            timeline:
                                                                                timeline,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                          ),
                                                        MessageContent(
                                                          displayEvent,
                                                          textColor: textColor,
                                                          linkColor: linkColor,
                                                          onInfoTab: onInfoTab,
                                                          borderRadius:
                                                              borderRadius,
                                                          timeline: timeline,
                                                          selected: selected,
                                                          bigEmojis: bigEmojis,
                                                        ),
                                                        if (event
                                                            .hasAggregatedEvents(
                                                              timeline,
                                                              RelationshipTypes
                                                                  .edit,
                                                            ))
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 8.0,
                                                                  left: 12.0,
                                                                  right: 12.0,
                                                                ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              spacing: 4.0,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .edit_outlined,
                                                                  color: textColor
                                                                      .withAlpha(
                                                                        164,
                                                                      ),
                                                                  size: 14,
                                                                ),
                                                                Text(
                                                                  displayEvent
                                                                      .originServerTs
                                                                      .localizedTimeShort(
                                                                        context,
                                                                      ),
                                                                  style: TextStyle(
                                                                    color: textColor
                                                                        .withAlpha(
                                                                          164,
                                                                        ),
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: ownMessage
                                              ? Alignment.bottomRight
                                              : Alignment.bottomLeft,
                                          child: AnimatedSize(
                                            duration:
                                                GloomThemes.animationDuration,
                                            curve: GloomThemes.animationCurve,
                                            child: showReactionPicker
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          4.0,
                                                        ),
                                                    child: Material(
                                                      elevation: 4,
                                                      borderRadius:
                                                          BorderRadius.zero,
                                                      shadowColor: theme
                                                          .colorScheme
                                                          .surface
                                                          .withAlpha(128),
                                                      child: SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: Row(
                                                          mainAxisSize: .min,
                                                          children: [
                                                            ...AppConfig.defaultReactions.map(
                                                              (
                                                                emoji,
                                                              ) => IconButton(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                icon: Center(
                                                                  child: Opacity(
                                                                    opacity:
                                                                        sentReactions.contains(
                                                                          emoji,
                                                                        )
                                                                        ? 0.33
                                                                        : 1,
                                                                    child: Text(
                                                                      emoji,
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            20,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ),
                                                                ),
                                                                onPressed:
                                                                    sentReactions
                                                                        .contains(
                                                                          emoji,
                                                                        )
                                                                    ? null
                                                                    : () {
                                                                        onSelect(
                                                                          event,
                                                                        );
                                                                        event.room.sendReaction(
                                                                          event
                                                                              .eventId,
                                                                          emoji,
                                                                        );
                                                                      },
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .add_reaction_outlined,
                                                              ),
                                                              tooltip: L10n.of(
                                                                context,
                                                              ).customReaction,
                                                              onPressed: () async {
                                                                final emoji = await showAdaptiveBottomSheet<String>(
                                                                  context:
                                                                      context,
                                                                  builder: (context) => Scaffold(
                                                                    appBar: AppBar(
                                                                      title: Text(
                                                                        L10n.of(
                                                                          context,
                                                                        ).customReaction,
                                                                      ),
                                                                      leading: CloseButton(
                                                                        onPressed: () => Navigator.of(
                                                                          context,
                                                                        ).pop(null),
                                                                      ),
                                                                    ),
                                                                    body: SizedBox(
                                                                      height: double
                                                                          .infinity,
                                                                      child: EmojiPicker(
                                                                        onEmojiSelected:
                                                                            (
                                                                              _,
                                                                              emoji,
                                                                            ) =>
                                                                                Navigator.of(
                                                                                  context,
                                                                                ).pop(
                                                                                  emoji.emoji,
                                                                                ),
                                                                        config: Config(
                                                                          locale: Localizations.localeOf(
                                                                            context,
                                                                          ),
                                                                          emojiViewConfig: const EmojiViewConfig(
                                                                            backgroundColor:
                                                                                Colors.transparent,
                                                                          ),
                                                                          bottomActionBarConfig: const BottomActionBarConfig(
                                                                            enabled:
                                                                                false,
                                                                          ),
                                                                          categoryViewConfig: CategoryViewConfig(
                                                                            initCategory:
                                                                                Category.SMILEYS,
                                                                            backspaceColor:
                                                                                theme.colorScheme.primary,
                                                                            iconColor: theme.colorScheme.primary.withAlpha(
                                                                              128,
                                                                            ),
                                                                            iconColorSelected:
                                                                                theme.colorScheme.primary,
                                                                            indicatorColor:
                                                                                theme.colorScheme.primary,
                                                                            backgroundColor:
                                                                                theme.colorScheme.surface,
                                                                          ),
                                                                          skinToneConfig: SkinToneConfig(
                                                                            dialogBackgroundColor: Color.lerp(
                                                                              theme.colorScheme.surface,
                                                                              theme.colorScheme.primaryContainer,
                                                                              0.75,
                                                                            )!,
                                                                            indicatorColor:
                                                                                theme.colorScheme.onSurface,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                                if (emoji ==
                                                                    null) {
                                                                  return;
                                                                }
                                                                if (sentReactions
                                                                    .contains(
                                                                      emoji,
                                                                    )) {
                                                                  return;
                                                                }
                                                                onSelect(event);

                                                                await event.room
                                                                    .sendReaction(
                                                                      event
                                                                          .eventId,
                                                                      emoji,
                                                                    );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  );
                },
              ),
              AnimatedSize(
                duration: GloomThemes.animationDuration,
                curve: GloomThemes.animationCurve,
                alignment: Alignment.bottomCenter,
                child: !showReceiptsRow
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.only(
                          top: 4.0,
                          left: (ownMessage ? 0 : Avatar.defaultSize) + 12.0,
                          right: ownMessage ? 0 : 12.0,
                        ),
                        child: MessageReactions(event, timeline),
                      ),
              ),
              if (enterThread != null)
                AnimatedSize(
                  duration: GloomThemes.animationDuration,
                  curve: GloomThemes.animationCurve,
                  alignment: Alignment.bottomCenter,
                  child: threadChildren.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: 2.0,
                            bottom: 8.0,
                            left: Avatar.defaultSize + 8,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: GloomThemes.columnWidth * 1.5,
                            ),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                              ),
                              onPressed: () => enterThread(event.eventId),
                              icon: const FaIcon(FontAwesomeIcons.solidComment),
                              label: Text(
                                '${L10n.of(context).countReplies(threadChildren.length)} | ${threadChildren.first.calcLocalizedBodyFallback(MatrixLocals(L10n.of(context)), withSenderNamePrefix: true)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                ),
              if (displayReadMarker)
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 16.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: theme.colorScheme.surface.withAlpha(128),
                      ),
                      child: Text(
                        L10n.of(context).readUpToHere,
                        style: TextStyle(
                          fontSize: 12 * AppSettings.fontSizeFactor.value,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class BubbleBackground extends StatelessWidget {
  const BubbleBackground({
    super.key,
    required this.scrollController,
    required this.colors,
    required this.ignore,
    required this.child,
  });

  final ScrollController scrollController;
  final List<Color> colors;
  final bool ignore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ignore) return child;
    return CustomPaint(
      painter: BubblePainter(
        repaint: scrollController,
        colors: colors,
        context: context,
      ),
      child: child,
    );
  }
}

class BubblePainter extends CustomPainter {
  BubblePainter({
    required this.context,
    required this.colors,
    required super.repaint,
  });

  final BuildContext context;
  final List<Color> colors;
  ScrollableState? _scrollable;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollable = _scrollable ??= Scrollable.of(context);
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final scrollableRect = Offset.zero & scrollableBox.size;
    final bubbleBox = context.findRenderObject() as RenderBox;

    final origin = bubbleBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableBox,
    );
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        scrollableRect.topCenter,
        scrollableRect.bottomCenter,
        colors,
        [0.0, 1.0],
        TileMode.clamp,
        Matrix4.translationValues(-origin.dx, -origin.dy, 0.0).storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(BubblePainter oldDelegate) {
    final scrollable = Scrollable.of(context);
    final oldScrollable = _scrollable;
    _scrollable = scrollable;
    return scrollable.position != oldScrollable?.position;
  }
}

class FireBurnWrapper extends StatefulWidget {
  final Widget child;
  final int? burnSeconds;
  final bool alreadyBurned;
  final String? eventId;
  final VoidCallback? onBurnComplete;

  const FireBurnWrapper({
    super.key,
    required this.child,
    this.burnSeconds,
    this.alreadyBurned = false,
    this.eventId,
    this.onBurnComplete,
  });

  @override
  State<FireBurnWrapper> createState() => _FireBurnWrapperState();
}

class _FireBurnWrapperState extends State<FireBurnWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onBurnComplete?.call();
      }
    });
    if (widget.alreadyBurned) {
      _controller.value = 1.0;
    } else if (widget.burnSeconds != null) {
      Future.delayed(Duration(seconds: widget.burnSeconds!), _startBurn);
    }
  }

  void _startBurn() {
    if (!mounted) return;
    _controller.forward();
  }

  @override
  void didUpdateWidget(FireBurnWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alreadyBurned && !oldWidget.alreadyBurned && _controller.value < 1.0) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final progress = _progress.value;
        if (progress >= 1.0 || widget.alreadyBurned) return const SizedBox.shrink();
        if (progress == 0.0) return child!;

        // burnFraction = how much of the message is still visible (top portion).
        // At progress=0 → 1.0 (fully visible). At progress=1 → 0.0 (fully gone).
        final burnFraction = 1.0 - progress;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Message: erased from bottom to top via gradient alpha mask.
            ShaderMask(
              shaderCallback: (Rect bounds) {
                const softEdge = 0.12; // feathered burn edge
                final edgeTop = (burnFraction - softEdge).clamp(0.0, 1.0);
                final edgeBot = burnFraction.clamp(0.01, 1.0);
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, edgeTop, edgeBot],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: child!,
            ),
            // Fire GIF: visible only at the burn line, rising with it.
            Positioned.fill(
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    // Fire band is centred on the burn line and spans ±fireZone.
                    const fireZone = 0.32;
                    final fireTop = (burnFraction - fireZone * 0.35).clamp(0.0, 1.0);
                    final fireMid = burnFraction.clamp(0.0, 1.0);
                    final fireBot = (burnFraction + fireZone * 0.65).clamp(0.0, 1.0);
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.transparent,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [fireTop, fireMid, fireBot],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Opacity(
                    opacity: (progress * 2.5).clamp(0.0, 1.0),
                    child: Image.asset(
                      'assets/icons/burning_message.gif',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
