import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:matrix/matrix.dart';

import 'package:afterdamage/utils/avatar_sigil.dart';
import 'package:afterdamage/utils/string_color.dart';
import 'package:afterdamage/widgets/mxc_image.dart';
import 'package:afterdamage/widgets/presence_builder.dart';
import 'package:afterdamage/widgets/hover_builder.dart';
import 'package:afterdamage/config/themes.dart';

class Avatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final void Function()? onTap;
  static const double defaultSize = 44;
  final Client? client;
  final String? presenceUserId;
  final Color? presenceBackgroundColor;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final BorderSide? border;
  final Color? backgroundColor;
  final Color? textColor;
  final ShapeBorder? shapeBorder;

  const Avatar({
    this.mxContent,
    this.name,
    this.size = defaultSize,
    this.onTap,
    this.client,
    this.presenceUserId,
    this.presenceBackgroundColor,
    this.borderRadius,
    this.border,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.shapeBorder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = this.name;
    final fallbackLetters = name == null || name.isEmpty
        ? '𐌰'
        : name.soulInitial;

    final noPic =
        mxContent == null ||
        mxContent.toString().isEmpty ||
        mxContent.toString() == 'null';
    final borderRadius = this.borderRadius ?? BorderRadius.zero;
    final presenceUserId = this.presenceUserId;

    // Palette-based avatar colors with auto-contrast
    final avatarBg = backgroundColor ?? name?.avatarBackground;
    final avatarFg = textColor ?? (name != null ? name.avatarForeground : Colors.white);

    // Subtle neutral border for fallback avatars (theme-aware)
    final fallbackBorder = noPic
        ? BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            width: 1,
          )
        : null;

    final container = Stack(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: border ?? fallbackBorder ?? BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: MxcImage(
              client: client,
              borderRadius: borderRadius,
              key: ValueKey(mxContent.toString()),
              cacheKey: '${mxContent}_$size',
              uri: mxContent,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (_) => noPic
                  ? Container(
                      decoration: BoxDecoration(
                        color: avatarBg,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fallbackLetters,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cardo',
                          color: avatarFg,
                          fontWeight: FontWeight.bold,
                          fontSize: (size / 2.2).roundToDouble(),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        FontAwesomeIcons.user,
                        color: theme.colorScheme.tertiary,
                        size: size / 1.5,
                      ),
                    ),
            ),
          ),
        ),
        if (presenceUserId != null)
          PresenceBuilder(
            client: client,
            userId: presenceUserId,
            builder: (context, presence) {
              if (presence == null ||
                  (presence.presence == PresenceType.offline &&
                      presence.lastActiveTimestamp == null)) {
                return const SizedBox.shrink();
              }
              final dotColor = presence.presence.isOnline
                  ? Colors.green
                  : presence.presence.isUnavailable
                  ? Colors.orange
                  : Colors.grey;
              return Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: presenceBackgroundColor ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.zero,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        width: 1,
                        color: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
    if (onTap == null) return container;
    return HoverBuilder(
      builder: (context, hovered) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            duration: GloomThemes.animationDuration,
            curve: GloomThemes.animationCurve,
            scale: hovered ? 1.05 : 1.0,
            child: container,
          ),
        ),
      ),
    );
  }
}
