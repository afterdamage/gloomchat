import 'package:flutter/material.dart';

class SquareSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeThumbColor;
  final Color? activeTrackColor;

  const SquareSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeThumbColor,
    this.activeTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onChanged != null;

    final trackColor = value
        ? (activeTrackColor ?? colorScheme.primary).withOpacity(0.5)
        : colorScheme.surfaceContainerHighest;
    final thumbColor = value
        ? (activeThumbColor ?? colorScheme.primary)
        : colorScheme.outline;

    return GestureDetector(
      onTap: isEnabled ? () => onChanged!(!value) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.38,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          width: 52,
          height: 28,
          color: trackColor,
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.all(3),
              color: thumbColor,
            ),
          ),
        ),
      ),
    );
  }
}

class SquareSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry? contentPadding;

  const SquareSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.secondary,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: secondary,
      title: title,
      subtitle: subtitle,
      contentPadding: contentPadding,
      trailing: SquareSwitch(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}
