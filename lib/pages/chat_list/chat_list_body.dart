import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/pages/chat_list/chat_list_item.dart';
import 'package:afterdamage/pages/chat_list/dummy_chat_list_item.dart';
import 'package:afterdamage/pages/chat_list/search_title.dart';
import 'package:afterdamage/pages/chat_list/space_view.dart';
import 'package:afterdamage/pages/search/lurk_view.dart';
import 'package:afterdamage/pages/chat_list/status_msg_list.dart';
import 'package:afterdamage/utils/stream_extension.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/public_room_dialog.dart';
import 'package:afterdamage/widgets/avatar.dart';
import '../../config/themes.dart';
import '../../widgets/adaptive_dialogs/user_dialog.dart';
import '../../widgets/app_destinations.dart';
import '../../widgets/matrix.dart';
import 'chat_list_header.dart';

class ChatListViewBody extends StatelessWidget {
  final ChatListController controller;

  const ChatListViewBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final client = Matrix.of(context).client;
    final activeSpace = controller.activeSpaceId;
    if (activeSpace != null) {
      return SpaceView(
        key: ValueKey(activeSpace),
        spaceId: activeSpace,
        onBack: controller.clearActiveSpace,
        onChatTab: (room) => controller.onChatTap(room),
        activeChat: controller.activeChat,
      );
    }
    final spaces = client.rooms.where((r) => r.isSpace);
    final spaceDelegateCandidates = <String, Room>{};
    for (final space in spaces) {
      for (final spaceChild in space.spaceChildren) {
        final roomId = spaceChild.roomId;
        if (roomId == null) continue;
        spaceDelegateCandidates[roomId] = space;
      }
    }

    final publicRooms = controller.roomSearchResult?.chunk
        .where((room) => room.roomType != 'm.space')
        .toList();
    final publicSpaces = controller.roomSearchResult?.chunk
        .where((room) => room.roomType == 'm.space')
        .toList();
    final userSearchResult = controller.userSearchResult;
    const dummyChatCount = 4;
    final filter = controller.searchController.text.toLowerCase();
    return StreamBuilder(
      key: ValueKey(client.userID.toString()),
      stream: client.onSync.stream
          .where((s) => s.hasRoomUpdate)
          .rateLimit(const Duration(seconds: 1)),
      builder: (context, _) {
        final rooms = controller.filteredRooms;

        return SafeArea(
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              ChatListHeader(controller: controller),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (controller.isSearchMode) ...[
                    SearchTitle(
                      title: L10n.of(context).publicRooms,
                      icon: const FaIcon(FontAwesomeIcons.compass),
                    ),
                    PublicRoomsHorizontalList(publicRooms: publicRooms),
                    SearchTitle(
                      title: L10n.of(context).publicSpaces,
                      icon: const FaIcon(FontAwesomeIcons.cubes),
                    ),
                    PublicRoomsHorizontalList(publicRooms: publicSpaces),
                    SearchTitle(
                      title: L10n.of(context).users,
                      icon: const FaIcon(FontAwesomeIcons.users),
                    ),
                    AnimatedContainer(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(),
                      height:
                          userSearchResult == null ||
                              userSearchResult.results.isEmpty
                          ? 0
                          : 106,
                      duration: GloomThemes.animationDuration,
                      curve: GloomThemes.animationCurve,
                      child: userSearchResult == null
                          ? null
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: userSearchResult.results.length,
                              itemBuilder: (context, i) => _SearchItem(
                                title:
                                    userSearchResult.results[i].displayName ??
                                    userSearchResult
                                        .results[i]
                                        .userId
                                        .localpart ??
                                    L10n.of(context).unknownDevice,
                                avatar: userSearchResult.results[i].avatarUrl,
                                onPressed: () => UserDialog.show(
                                  context: context,
                                  profile: userSearchResult.results[i],
                                ),
                              ),
                            ),
                    ),
                  ],
                  if (!controller.isSearchMode &&
                      AppSettings.showPresences.value)
                    GestureDetector(
                      onLongPress: () => controller.dismissStatusList(),
                      child: StatusMessageList(
                        onStatusEdit: controller.setStatus,
                      ),
                    ),
                  if (client.rooms.isNotEmpty &&
                      !controller.isSearchMode &&
                      AppDestinations.isCompact(context))
                    _MobileFilterBar(
                      controller: controller,
                      spaceDelegateCandidates: spaceDelegateCandidates,
                    ),
                  if (controller.isSearchMode)
                    SearchTitle(
                      title: L10n.of(context).chats,
                      icon: const FaIcon(FontAwesomeIcons.comments),
                    ),
                  if (client.prevBatch != null &&
                      rooms.isEmpty &&
                      !controller.isSearchMode) ...[
                    Column(
                      mainAxisAlignment: .center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Column(
                              mainAxisSize: .min,
                              children: [
                                DummyChatListItem(opacity: 0.5, animate: false),
                                DummyChatListItem(opacity: 0.3, animate: false),
                              ],
                            ),
                            FaIcon(
                              FontAwesomeIcons.solidMessage,
                              size: 128,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            client.rooms.isEmpty
                                ? L10n.of(context).noChatsFoundHere
                                : L10n.of(context).noMoreChatsFound,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]),
              ),
              if (client.prevBatch == null)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DummyChatListItem(
                      opacity: (dummyChatCount - i) / dummyChatCount,
                      animate: true,
                    ),
                    childCount: dummyChatCount,
                  ),
                ),
              if (client.prevBatch != null)
                SliverList.builder(
                  itemCount: rooms.length,
                  itemBuilder: (BuildContext context, int i) {
                    final room = rooms[i];
                    final space = spaceDelegateCandidates[room.id];
                    return ChatListItem(
                      room,
                      space: space,
                      key: Key('chat_list_item_${room.id}'),
                      filter: filter,
                      onTap: () => controller.onChatTap(room),
                      onLongPress: (context) =>
                          controller.chatContextAction(room, context, space),
                      activeChat: controller.activeChat == room.id,
                    );
                  },
                ),
              if (controller.isSearchMode) ...[
                SliverToBoxAdapter(
                  child: SearchTitle(
                    title: L10n.of(context).lurk,
                    icon: const FaIcon(FontAwesomeIcons.eye),
                  ),
                ),
                const SliverToBoxAdapter(child: LurkView()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class PublicRoomsHorizontalList extends StatelessWidget {
  const PublicRoomsHorizontalList({super.key, required this.publicRooms});

  final List<PublishedRoomsChunk>? publicRooms;

  @override
  Widget build(BuildContext context) {
    final publicRooms = this.publicRooms;
    return AnimatedContainer(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      height: publicRooms == null || publicRooms.isEmpty ? 0 : 106,
      duration: GloomThemes.animationDuration,
      curve: GloomThemes.animationCurve,
      child: publicRooms == null
          ? null
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: publicRooms.length,
              itemBuilder: (context, i) => _SearchItem(
                title:
                    publicRooms[i].name ??
                    publicRooms[i].canonicalAlias?.localpart ??
                    L10n.of(context).group,
                avatar: publicRooms[i].avatarUrl,
                onPressed: () => showAdaptiveDialog(
                  context: context,
                  builder: (c) => PublicRoomDialog(
                    roomAlias:
                        publicRooms[i].canonicalAlias ?? publicRooms[i].roomId,
                    chunk: publicRooms[i],
                  ),
                ),
              ),
            ),
    );
  }
}

class _MobileFilterBar extends StatelessWidget {
  final ChatListController controller;
  final Map<String, Room> spaceDelegateCandidates;

  const _MobileFilterBar({
    required this.controller,
    required this.spaceDelegateCandidates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = controller.activeFilter;
    final isSecondaryActive =
        active == ActiveFilter.groups || active == ActiveFilter.messages;

    // Normalize: if a secondary filter is active, neither primary segment is selected.
    final primarySelected = isSecondaryActive ? <ActiveFilter>{} : {active};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ActiveFilter>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              emptySelectionAllowed: true,
              segments: [
                ButtonSegment(
                  value: ActiveFilter.allChats,
                  label: Text(ActiveFilter.allChats.toLocalizedString(context)),
                ),
                ButtonSegment(
                  value: ActiveFilter.unread,
                  icon: const FaIcon(FontAwesomeIcons.solidEnvelope, size: 12),
                  label: Text(ActiveFilter.unread.toLocalizedString(context)),
                ),
              ],
              selected: primarySelected,
              onSelectionChanged: (selected) {
                if (selected.isEmpty) return;
                controller.setActiveFilter(selected.first);
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<ActiveFilter>(
            tooltip: '',
            icon: FaIcon(
              isSecondaryActive
                  ? FontAwesomeIcons.filter
                  : FontAwesomeIcons.filter,
              size: 16,
              color: isSecondaryActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            onSelected: controller.setActiveFilter,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ActiveFilter.groups,
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.peopleGroup,
                      size: 14,
                      color: active == ActiveFilter.groups
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(ActiveFilter.groups.toLocalizedString(context)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ActiveFilter.messages,
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.solidComment,
                      size: 14,
                      color: active == ActiveFilter.messages
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(ActiveFilter.messages.toLocalizedString(context)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchItem extends StatelessWidget {
  final String title;
  final Uri? avatar;
  final void Function() onPressed;

  const _SearchItem({
    required this.title,
    this.avatar,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    child: SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: .min,
        children: [
          const SizedBox(height: 8),
          Avatar(mxContent: avatar, name: title),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

