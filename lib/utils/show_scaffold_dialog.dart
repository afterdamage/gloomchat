import 'package:afterdamage/config/app_config.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:flutter/material.dart';

Future<T?> showScaffoldDialog<T>({
  required BuildContext context,
  Color? barrierColor,
  Color? containerColor,
  double maxWidth = 480,
  double maxHeight = 720,
  required Widget Function(BuildContext context) builder,
}) => showDialog<T>(
  context: context,
  useSafeArea: false,
  builder: GloomThemes.isColumnMode(context)
      ? (context) => Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              color:
                  containerColor ?? Theme.of(context).scaffoldBackgroundColor,
            ),
            clipBehavior: Clip.hardEdge,
            margin: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: builder(context),
          ),
        )
      : builder,
);
