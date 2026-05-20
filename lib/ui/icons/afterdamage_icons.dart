import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Centralized brand-specific icons for GloomChat.
class AfterdamageIcons {
  AfterdamageIcons._(); // non-instantiable

  static Widget newChat(
    BuildContext context, {
    double size = 20,
    Color? color,
  }) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

    return FaIcon(
      FontAwesomeIcons.feather,
      size: size,
      color: effectiveColor,
    );
  }
}
