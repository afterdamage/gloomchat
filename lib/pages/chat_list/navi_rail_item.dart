import 'package:flutter/material.dart';

import 'package:badges/badges.dart';
import 'package:matrix/matrix.dart';

import 'package:afterdamage/widgets/hover_builder.dart';
import 'package:afterdamage/widgets/unread_rooms_badge.dart';
import '../../config/themes.dart';

class NaviRailItem extends StatelessWidget {
  final String toolTip;
  final bool isSelected;
  final void Function() onTap;
  final Widget icon;
  final Widget? selectedIcon;
  final bool Function(Room)? unreadBadgeFilter;
  final BorderRadius borderRadius;

  const NaviRailItem({
    required this.toolTip,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    this.selectedIcon,
    this.unreadBadgeFilter,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = isSelected ? selectedIcon ?? this.icon : this.icon;
    final unreadBadgeFilter = this.unreadBadgeFilter;
    return HoverBuilder(
      builder: (context, hovered) {
        return SizedBox(
          height: 72,
          width: GloomThemes.navRailWidth,
          child: Stack(
            children: [
              Positioned(
                top: 8,
                bottom: 8,
                left: 0,
                child: AnimatedContainer(
                  width: isSelected
                      ? GloomThemes.isColumnMode(context)
                            ? 8
                            : 4
                      : 0,
                  duration: GloomThemes.animationDuration,
                  curve: GloomThemes.animationCurve,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              Center(
                child: AnimatedScale(
                  scale: hovered ? 1.1 : 1.0,
                  duration: GloomThemes.animationDuration,
                  curve: GloomThemes.animationCurve,
                  child: Material(
                    borderRadius: borderRadius,
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHigh,
                    child: Tooltip(
                      message: toolTip,
                      child: InkWell(
                        borderRadius: borderRadius,
                        onTap: onTap,
                        child: unreadBadgeFilter == null
                            ? icon
                            : UnreadRoomsBadge(
                                filter: unreadBadgeFilter,
                                badgePosition: BadgePosition.topEnd(
                                  top: -12,
                                  end: -8,
                                ),
                                child: icon,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
