import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/stream_extension.dart';
import 'package:afterdamage/widgets/app_bottom_bar.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/matrix.dart';

/// Full-page Spaces list — shows every space the user has joined.
///
/// Tapping a space navigates to the chat list filtered by that space.
/// On compact (mobile) screens a bottom bar is shown.
class SpacesPage extends StatelessWidget {
  const SpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = Matrix.of(context).client;
    final isCompact = AppDestinations.isCompact(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).spaces),
        automaticallyImplyLeading: !isCompact,
        leading: isCompact ? null : BackButton(onPressed: () => context.go('/rooms')),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            tooltip: L10n.of(context).createNewSpace,
            onPressed: () => context.go('/rooms/newspace'),
          ),
        ],
      ),
      bottomNavigationBar: isCompact ? const AppBottomBar() : null,
      body: StreamBuilder(
        stream: client.onSync.stream
            .where((s) => s.hasRoomUpdate)
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, _) {
          final spaces = client.rooms.where((r) => r.isSpace).toList()
            ..sort(
              (a, b) => a
                  .getLocalizedDisplayname(MatrixLocals(L10n.of(context)))
                  .compareTo(
                    b.getLocalizedDisplayname(MatrixLocals(L10n.of(context))),
                  ),
            );

          if (spaces.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FontAwesomeIcons.globe,
                    size: 48,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L10n.of(context).noSpacesFound,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/rooms/newspace'),
                    icon: const FaIcon(FontAwesomeIcons.plus),
                    label: Text(L10n.of(context).createNewSpace),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];
              final displayname = space.getLocalizedDisplayname(
                MatrixLocals(L10n.of(context)),
              );
              final childCount = space.spaceChildren.length;

              return ListTile(
                leading: Avatar(
                  mxContent: space.avatar,
                  name: displayname,
                  borderRadius:
                      BorderRadius.zero,
                ),
                title: Text(
                  displayname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  L10n.of(context).numberRooms(childCount),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
                trailing: const FaIcon(FontAwesomeIcons.angleRight, size: 16),
                onTap: () {
                  // Navigate to chat list filtered by this space
                  context.go('/rooms?spaceId=${space.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
