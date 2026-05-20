import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/ui/icons/afterdamage_icons.dart';

/// Persistent bottom toolbar with Chats, New Chat (center action), and Spaces.
///
/// Visible on compact (mobile) layouts only. Shows active state for Chats
/// and Spaces tabs. The center New Chat button is a primary action and
/// never has an "active" state.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentRoute =
        GoRouter.of(context).routeInformationProvider.value.uri.path;
    final isOnSpaces = currentRoute.startsWith('/rooms/spaces') ||
        currentRoute.contains('spaceId=');
    final accentColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withAlpha(153);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Chats tab
              _BottomBarTab(
                icon: FontAwesomeIcons.comments,
                label: L10n.of(context).chats,
                isActive: !isOnSpaces,
                activeColor: accentColor,
                inactiveColor: inactiveColor,
                onTap: () {
                  if (isOnSpaces) context.go('/rooms');
                },
              ),

              // New Chat (center, visually emphasized)
              _NewChatButton(
                accentColor: accentColor,
                label: L10n.of(context).newChat,
                onTap: () => context.go('/rooms/newprivatechat'),
              ),

              // Spaces tab
              _BottomBarTab(
                icon: FontAwesomeIcons.globe,
                label: L10n.of(context).spaces,
                isActive: isOnSpaces,
                activeColor: accentColor,
                inactiveColor: inactiveColor,
                onTap: () {
                  if (!isOnSpaces) context.go('/rooms/spaces');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single tab item (Chats or Account) in the bottom bar.
class _BottomBarTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _BottomBarTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isActive,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Center "New Chat" button — larger, filled with accent color, elevated.
class _NewChatButton extends StatelessWidget {
  final Color accentColor;
  final String label;
  final VoidCallback onTap;

  const _NewChatButton({
    required this.accentColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onAccent =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Semantics(
        label: label,
        button: true,
        child: Material(
          color: accentColor,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: accentColor.withAlpha(77),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: AfterdamageIcons.newChat(
                  context,
                  size: 26,
                  color: onAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
