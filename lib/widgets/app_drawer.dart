import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/gloom_share.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:afterdamage/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/future_loading_dialog.dart';
import 'package:afterdamage/widgets/matrix.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final client = Matrix.of(context).client;
    final matrix = Matrix.of(context);
    final currentRoute = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final destinations = AppDestinations.getDestinations(context);

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            _buildUserHeader(context, client, theme),
            Divider(
              color: colorScheme.outlineVariant,
              height: 1,
            ),

            // Navigation Items + Account Actions
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Account Actions Section
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.userGroup,
                    title: L10n.of(context).createGroup,
                    route: '/rooms/newgroup',
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/rooms/newgroup');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.penToSquare,
                    title: L10n.of(context).setStatus,
                    route: '',
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      _setStatus(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.shareNodes,
                    title: L10n.of(context).inviteContact,
                    route: '',
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      GloomShare.shareInviteLink(context);
                    },
                  ),
                  Divider(
                    color: colorScheme.outlineVariant,
                    height: 1,
                  ),
                  
                  // Main navigation destinations
                  ...destinations.map((dest) => _buildDrawerItem(
                      context: context,
                      icon: dest.icon,
                      title: dest.getLabel(context),
                      route: dest.route,
                      currentRoute: currentRoute,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(dest.route);
                      },
                    ),
                  ),
                  
                  // Account Management Section
                  Divider(
                    color: colorScheme.outlineVariant,
                    height: 1,
                  ),
                  
                  // Show multiple accounts if they exist
                  if (matrix.isMultiAccount) ..._buildAccountSwitcher(context, matrix, theme),
                  
                  // Add Account action
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.userPlus,
                    title: L10n.of(context).addAccount,
                    route: '/rooms/settings/addaccount',
                    currentRoute: currentRoute,
                    onTap: () async {
                      final consent = await showOkCancelAlertDialog(
                        context: context,
                        title: L10n.of(context).addAccount,
                        message: L10n.of(context).enableMultiAccounts,
                        okLabel: L10n.of(context).next,
                        cancelLabel: L10n.of(context).cancel,
                      );
                      if (consent != OkCancelResult.ok || !context.mounted) return;
                      Navigator.pop(context);
                      context.go('/rooms/settings/addaccount');
                    },
                  ),
                  
                  Divider(
                    color: colorScheme.outlineVariant,
                    height: 1,
                  ),

                  // Panic action
                  _buildDrawerItem(
                    context: context,
                    icon: FontAwesomeIcons.radiation,
                    title: 'Panic',
                    route: '',
                    currentRoute: currentRoute,
                    onTap: () async {
                      final consent = await showOkCancelAlertDialog(
                        context: context,
                        title: 'Panic',
                        message: 'This will wipe all local data and log you out. Are you absolutely sure?',
                        okLabel: 'Burn it',
                        cancelLabel: L10n.of(context).cancel,
                      );
                      if (consent != OkCancelResult.ok || !context.mounted) return;
                      
                      Navigator.pop(context); // Close the drawer
                      
                      // Show loading dialog while clearing cache to prevent user interaction
                      await showFutureLoadingDialog(
                        context: context,
                        future: () async {
                          await Matrix.of(context).client.clearCache();
                          // Also try a logout if possible to revoke the token, but clearCache is primary goal.
                          try {
                            await Matrix.of(context).client.logout();
                          } catch (_) {
                            // Ignore if logout fails because of network, cache is already dead.
                          }
                        },
                      );
                      
                      if (!context.mounted) return;
                      context.go('/');
                    },
                  ),

                ],
              ),
            ),

            // Footer with app version
            Divider(
              color: colorScheme.outlineVariant,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'GloomChat',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAccountSwitcher(BuildContext context, MatrixState matrix, ThemeData theme) {
    final widgets = <Widget>[];
    final bundles = matrix.accountBundles.keys.toList()
      ..sort(
        (a, b) => a!.isValidMatrixId == b!.isValidMatrixId
            ? 0
            : a.isValidMatrixId && !b.isValidMatrixId
            ? -1
            : 1,
      );

    for (final bundle in bundles) {
      // Add bundle header if needed
      if (matrix.accountBundles[bundle]!.length != 1 ||
          matrix.accountBundles[bundle]!.single!.userID != bundle) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              bundle!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // Add accounts in bundle
      for (final client in matrix.accountBundles[bundle]!.whereType<Client>().where((c) => c.isLogged())) {
        widgets.add(
          FutureBuilder<Profile?>(
            future: client.fetchOwnProfile(),
            builder: (context, snapshot) {
              final isActive = matrix.client == client;
              return ListTile(
                leading: Avatar(
                  mxContent: snapshot.data?.avatarUrl,
                  name: snapshot.data?.displayName ?? client.userID!.localpart,
                  size: 32,
                ),
                title: Text(
                  snapshot.data?.displayName ?? client.userID!.localpart!,
                  style: TextStyle(
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                tileColor: isActive
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                onTap: () {
                  Navigator.pop(context);
                  matrix.setActiveClient(client);
                },
              );
            },
          ),
        );
      }
    }

    return widgets;
  }

  static void _setStatus(BuildContext context) async {
    final client = Matrix.of(context).client;
    final currentPresence = await client.fetchCurrentPresence(client.userID!);
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: L10n.of(context).setStatus,
      message: L10n.of(context).leaveEmptyToClearStatus,
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
      hintText: L10n.of(context).statusExampleMessage,
      maxLines: 6,
      minLines: 1,
      maxLength: 255,
      initialText: currentPresence.statusMsg,
    );
    if (input == null || !context.mounted) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.setPresence(
        client.userID!,
        PresenceType.online,
        statusMsg: input,
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, Client client, ThemeData theme) {
    final profile = client.fetchOwnProfile();
    
    return FutureBuilder<Profile>(
      future: profile,
      builder: (context, snapshot) {
        final displayName = snapshot.data?.displayName ?? client.userID?.localpart ?? '';
        final avatarUrl = snapshot.data?.avatarUrl;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                mxContent: avatarUrl,
                name: displayName,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                client.userID ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required FaIconData icon,
    required String title,
    required String route,
    required String currentRoute,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isActive = route.isNotEmpty && currentRoute.startsWith(route);
    
    return ListTile(
      leading: FaIcon(
        icon,
        color: iconColor ?? (isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive
          ? theme.colorScheme.primary.withOpacity(0.15)
          : Colors.transparent,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.15),
      hoverColor: theme.colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(),
      onTap: onTap,
    );
  }
}
