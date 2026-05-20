import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat_list/chat_filter_scope.dart';
import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/pages/chat_list/navi_rail_item.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/stream_extension.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

class SpacesNavigationRail extends StatelessWidget {
  final String? activeSpaceId;
  final void Function() onGoToChats;
  final void Function(String) onGoToSpaceId;

  const SpacesNavigationRail({
    required this.activeSpaceId,
    required this.onGoToChats,
    required this.onGoToSpaceId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final isSettings = GoRouter.of(
      context,
    ).routeInformationProvider.value.uri.path.startsWith('/rooms/settings');
    return Material(
      child: SafeArea(
        child: StreamBuilder(
          key: ValueKey(client.userID.toString()),
          stream: client.onSync.stream
              .where((s) => s.hasRoomUpdate)
              .rateLimit(const Duration(seconds: 1)),
          builder: (context, _) {
            final allSpaces = client.rooms
                .where((room) => room.isSpace)
                .toList();

            return SizedBox(
              width: GloomThemes.isColumnMode(context)
                  ? GloomThemes.navRailWidth
                  : GloomThemes.navRailWidth * 0.75,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: allSpaces.length + 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return NaviRailItem(
                            isSelected: activeSpaceId == null && !isSettings,
                            onTap: onGoToChats,
                            icon: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: FaIcon(FontAwesomeIcons.comments),
                            ),
                            selectedIcon: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: FaIcon(FontAwesomeIcons.solidComments),
                            ),
                            toolTip: L10n.of(context).chats,
                            unreadBadgeFilter: (room) => true,
                          );
                        }
                        i--;
                        if (i == allSpaces.length) {
                          return NaviRailItem(
                            isSelected: false,
                            onTap: () => context.go('/rooms/newspace'),
                            icon: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: FaIcon(FontAwesomeIcons.plus),
                            ),
                            toolTip: L10n.of(context).createNewSpace,
                          );
                        }
                        final space = allSpaces[i];
                        final displayname = allSpaces[i]
                            .getLocalizedDisplayname(
                              MatrixLocals(L10n.of(context)),
                            );
                        final spaceChildrenIds = space.spaceChildren
                            .map((c) => c.roomId)
                            .toSet();
                        return NaviRailItem(
                          toolTip: displayname,
                          isSelected: activeSpaceId == space.id,
                          onTap: () => onGoToSpaceId(allSpaces[i].id),
                          unreadBadgeFilter: (room) =>
                              spaceChildrenIds.contains(room.id),
                          borderRadius: BorderRadius.zero,
                          icon: Avatar(
                            mxContent: allSpaces[i].avatar,
                            name: displayname,
                            border: BorderSide(
                              width: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                        );
                      },
                    ),
                  ),
                  const _SidebarFilterSection(),
                  NaviRailItem(
                    isSelected: isSettings,
                    onTap: () => context.go('/rooms/settings'),
                    icon: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: FaIcon(FontAwesomeIcons.gear),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: FaIcon(FontAwesomeIcons.gear),
                    ),
                    toolTip: L10n.of(context).settings,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SidebarFilterSection extends StatelessWidget {
  const _SidebarFilterSection();

  @override
  Widget build(BuildContext context) {
    final scope = ChatFilterScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();

    final activeFilter = scope.activeFilter;
    final filters = [
      (ActiveFilter.allChats, FontAwesomeIcons.layerGroup),
      (ActiveFilter.unread, FontAwesomeIcons.solidEnvelope),
      (ActiveFilter.groups, FontAwesomeIcons.peopleGroup),
      (ActiveFilter.messages, FontAwesomeIcons.solidComment),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: Theme.of(context).dividerColor),
        for (final (filter, icon) in filters)
          NaviRailItem(
            toolTip: filter.toLocalizedString(context),
            isSelected: activeFilter == filter,
            onTap: () => scope.onFilterChanged(filter),
            icon: Padding(
              padding: const EdgeInsets.all(10.0),
              child: FaIcon(icon, size: 18),
            ),
          ),
      ],
    );
  }
}
