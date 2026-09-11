import 'package:flutter/material.dart';

class SettingsAdvancedSection extends StatelessWidget {
  final List<Widget> children;
  final String? label;

  const SettingsAdvancedSection({super.key, required this.children, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      leading: Icon(Icons.tune_outlined, color: theme.colorScheme.outline),
      title: Text(
        label ?? 'Advanced',
        style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
      childrenPadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
