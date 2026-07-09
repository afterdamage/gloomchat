import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';

import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/chat_list/chat_list.dart';
import 'package:afterdamage/pages/dialer/call_banner.dart';
import 'package:afterdamage/ui/icons/afterdamage_icons.dart';
import 'package:afterdamage/widgets/app_destinations.dart';
import 'package:afterdamage/widgets/app_navigation_shell.dart';
import 'package:afterdamage/widgets/navigation_rail.dart';
import 'chat_list_body.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    // Use custom navigation shell only when NOT in column mode
    // and navigation rail is not explicitly enabled
    final useCustomNavigation = !GloomThemes.isColumnMode(context) &&
        !AppSettings.displayNavigationRail.value;

    final scaffoldBody = PopScope(
      canPop: !controller.isSearchMode && controller.activeSpaceId == null,
      onPopInvokedWithResult: (pop, _) {
        if (pop) return;
        if (controller.activeSpaceId != null) {
          controller.clearActiveSpace();
          return;
        }
        if (controller.isSearchMode) {
          controller.cancelSearch();
          return;
        }
      },
      child: Row(
        children: [
          if (GloomThemes.isColumnMode(context) ||
              AppSettings.displayNavigationRail.value) ...[
            SpacesNavigationRail(
              activeSpaceId: controller.activeSpaceId,
              onGoToChats: controller.clearActiveSpace,
              onGoToSpaceId: controller.setActiveSpace,
            ),
            Container(color: Theme.of(context).dividerColor, width: 1),
          ],
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: FocusManager.instance.primaryFocus?.unfocus,
                    excludeFromSemantics: true,
                    behavior: HitTestBehavior.translucent,
                    child: ChatListViewBody(controller),
                  ),
                ),
                // Discord-style "Voice Connected" bar at the bottom of the
                // room list. On narrow layouts AppNavigationShell already
                // mounts it via AppNavRail, so only add it in column mode.
                if (GloomThemes.isColumnMode(context))
                  const GlobalCallSidebar(),
              ],
            ),
          ),
        ],
      ),
    );

    // Only show FAB on mobile — desktop uses an inline header button instead
    final isDesktop = GloomThemes.isColumnMode(context);
    final fab = !isDesktop &&
            !controller.isSearchMode &&
            controller.activeSpaceId == null
        ? FloatingActionButton(
            onPressed: () => context.go('/rooms/newprivatechat'),
            child: AfterdamageIcons.newChat(context, size: 24),
          )
        : null;

    // Wrap with AppNavigationShell if using custom navigation
    if (useCustomNavigation) {
      return AppNavigationShell(
        body: scaffoldBody,
        floatingActionButton: fab,
      );
    }

    // When not using custom navigation, still need a Scaffold for FAB
    return Scaffold(
      body: scaffoldBody,
      floatingActionButton: fab,
    );
  }
}
