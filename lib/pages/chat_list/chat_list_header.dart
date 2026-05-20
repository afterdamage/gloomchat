import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/ui/icons/afterdamage_icons.dart';
import 'package:afterdamage/utils/sync_status_localization.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import '../../widgets/matrix.dart';

class ChatListHeader extends StatelessWidget implements PreferredSizeWidget {
  final ChatListController controller;
  final bool globalSearch;

  const ChatListHeader({
    super.key,
    required this.controller,
    this.globalSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;

    // Show hamburger menu on compact layouts when not using column mode or navigation rail
    final showMenuButton = AppDestinations.isCompact(context) &&
        !GloomThemes.isColumnMode(context) &&
        !AppSettings.displayNavigationRail.value;

    final isDesktop = GloomThemes.isColumnMode(context);

    return SliverAppBar(
      floating: true,
      toolbarHeight: 72,
      pinned: isDesktop,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: isDesktop
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: () => context.go('/rooms/newprivatechat'),
                  icon: AfterdamageIcons.newChat(
                    context,
                    size: 22,
                    color: theme.colorScheme.onPrimary,
                  ),
                  tooltip: L10n.of(context).newChat,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ]
          : null,
      leading: showMenuButton
          ? IconButton(
              icon: const FaIcon(FontAwesomeIcons.bars),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Open menu',
            )
          : null,
      title: StreamBuilder(
        stream: client.onSyncStatus.stream,
        builder: (context, snapshot) {
          final status =
              client.onSyncStatus.value ??
              const SyncStatusUpdate(SyncStatus.waitingForResponse);
          final hide =
              client.onSync.value != null &&
              status.status != SyncStatus.error &&
              client.prevBatch != null;
          return TextField(
            controller: controller.searchController,
            focusNode: controller.searchFocusNode,
            textInputAction: TextInputAction.search,
            onChanged: (text) =>
                controller.onSearchEnter(text, globalSearch: globalSearch),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.secondaryContainer,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.zero,
              ),
              contentPadding: EdgeInsets.zero,
              hintText: hide
                  ? L10n.of(context).searchChatsRooms
                  : status.calcLocalizedString(context),
              hintStyle: TextStyle(
                color: status.error != null
                    ? Colors.orange
                    : theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: hide
                  ? controller.isSearchMode
                        ? IconButton(
                            tooltip: L10n.of(context).cancel,
                            icon: const FaIcon(FontAwesomeIcons.xmark),
                            onPressed: controller.cancelSearch,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : IconButton(
                            onPressed: controller.startSearch,
                            icon: Icon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                  : Container(
                      margin: const EdgeInsets.all(12),
                      width: 8,
                      height: 8,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: status.progress,
                          valueColor: status.error != null
                              ? const AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                )
                              : null,
                        ),
                      ),
                    ),
              suffixIcon: controller.isSearchMode && globalSearch
                  ? controller.isSearching
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 12,
                            ),
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: controller.setServer,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                            label: Text(
                              controller.searchServer ??
                                  Matrix.of(context).client.homeserver!.host,
                              maxLines: 2,
                            ),
                          )
                  : const SizedBox(width: 0),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
