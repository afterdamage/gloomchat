import 'package:flutter/material.dart';

class AdaptiveDialogAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool autofocus;
  final Widget child;
  final bool bigButtons;
  final BorderRadius? borderRadius;

  static const BorderRadius topRadius = BorderRadius.zero;
  static const BorderRadius centerRadius = BorderRadius.zero;
  static const BorderRadius bottomRadius = BorderRadius.zero;

  const AdaptiveDialogAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.autofocus = false,
    this.bigButtons = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (bigButtons) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius ?? BorderRadius.zero,
              ),
              backgroundColor: autofocus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceBright,
              foregroundColor: autofocus
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            onPressed: onPressed,
            autofocus: autofocus,
            child: child,
          ),
        ),
      );
    }
    return TextButton(
      onPressed: onPressed,
      autofocus: autofocus,
      child: child,
    );
  }
}

class AdaptiveDialogInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AdaptiveDialogInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: onTap == null
          ? theme.colorScheme.surfaceContainer
          : theme.colorScheme.surfaceBright,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class AdaptiveIconTextButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const AdaptiveIconTextButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Expanded(
      child: AdaptiveDialogInkWell(
        padding: EdgeInsets.all(8.0),
        onTap: onTap,
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
