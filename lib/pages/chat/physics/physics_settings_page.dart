/// The Kinetic Ledger — user-facing physics settings page.
library;

import 'package:flutter/material.dart';
import 'package:afterdamage/widgets/square_switch.dart';

import 'physics_settings.dart';

class PhysicsSettingsPage extends StatefulWidget {
  const PhysicsSettingsPage({super.key});

  @override
  State<PhysicsSettingsPage> createState() => _PhysicsSettingsPageState();
}

class _PhysicsSettingsPageState extends State<PhysicsSettingsPage> {
  final _settings = PhysicsSettings.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚗️ Message Physics'),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Gravity Preset ──────────────────────────────────────────────
          _SectionHeader(title: '🌍 Gravity', theme: theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preset',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: GravityPreset.values.map((preset) {
                      final selected = _settings.gravityPreset == preset;
                      return ChoiceChip(
                        label: Text(
                          '${preset.label} (${preset.ms2} m/s²)',
                        ),
                        selected: selected,
                        onSelected: (_) => setState(
                          () => _settings.gravityPreset = preset,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _gravityDescription(_settings.gravityPreset),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Physics Constants ───────────────────────────────────────────
          _SectionHeader(title: '🎱 Physics Constants', theme: theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _SliderTile(
                    label: 'Bounciness',
                    emoji: '🏀',
                    value: _settings.restitution,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) =>
                        setState(() => _settings.restitution = v),
                    description:
                        '0 = dead stop  •  1 = perfect bounce',
                  ),
                  const Divider(),
                  _SliderTile(
                    label: 'Friction',
                    emoji: '🧲',
                    value: _settings.friction,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => setState(() => _settings.friction = v),
                    description: '0 = ice  •  1 = velcro',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Mass Formula ────────────────────────────────────────────────
          _SectionHeader(title: '⚖️ Mass Formula', theme: theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      'm = base + (chars × per_char) + (MB × per_MB)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SliderTile(
                    label: 'Base mass',
                    emoji: '📦',
                    value: _settings.baseMass,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    onChanged: (v) => setState(() => _settings.baseMass = v),
                    description: 'Every message starts with this mass',
                  ),
                  const Divider(),
                  _SliderTile(
                    label: 'Mass per character',
                    emoji: '🔤',
                    value: _settings.massPerChar,
                    min: 0.0,
                    max: 0.5,
                    divisions: 50,
                    onChanged: (v) =>
                        setState(() => _settings.massPerChar = v),
                    description: 'Short "lol" = ping-pong  •  essay = lead',
                  ),
                  const Divider(),
                  _SliderTile(
                    label: 'Mass per MB (attachment)',
                    emoji: '📎',
                    value: _settings.massPerMB,
                    min: 0.0,
                    max: 20.0,
                    divisions: 40,
                    onChanged: (v) => setState(() => _settings.massPerMB = v),
                    description: '4K meme = lead brick',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Reactions ───────────────────────────────────────────────────
          _SectionHeader(title: '💥 Reaction Physics', theme: theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _SliderTile(
                    label: 'Explosion impulse',
                    emoji: '💥',
                    value: _settings.reactionImpulseMagnitude,
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    onChanged: (v) => setState(
                      () => _settings.reactionImpulseMagnitude = v,
                    ),
                    description:
                        'Force of 💥/🔥 reactions blasting nearby messages',
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Text('⚓', style: TextStyle(fontSize: 24)),
                    title: const Text('Anchor threshold'),
                    subtitle: Text(
                      '${_settings.anchorReactionCount} reactions → message becomes immovable anchor',
                    ),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue:
                            _settings.anchorReactionCount.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null && n > 0) {
                            setState(
                              () => _settings.anchorReactionCount = n,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Word Shatter ────────────────────────────────────────────────
          _SectionHeader(title: '💣 Word Shatter', theme: theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SquareSwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Word Shatter'),
                    subtitle: const Text(
                      'Messages break into individual words on high-velocity wall impact',
                    ),
                    value: _settings.wordShatterEnabled,
                    onChanged: (v) =>
                        setState(() => _settings.wordShatterEnabled = v),
                  ),
                  if (_settings.wordShatterEnabled) ...[
                    const Divider(),
                    _SliderTile(
                      label: 'Shatter velocity threshold',
                      emoji: '💨',
                      value: _settings.wordShatterThreshold,
                      min: 5.0,
                      max: 40.0,
                      divisions: 35,
                      onChanged: (v) => setState(
                        () => _settings.wordShatterThreshold = v,
                      ),
                      description:
                          'Speed (m/s) at which a message explodes into words',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Reset button
          OutlinedButton.icon(
            onPressed: _resetDefaults,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _resetDefaults() {
    setState(() {
      _settings.gravityPreset = GravityPreset.earth;
      _settings.restitution = 0.4;
      _settings.friction = 0.5;
      _settings.baseMass = 1.0;
      _settings.massPerChar = 0.1;
      _settings.massPerMB = 5.0;
      _settings.reactionImpulseMagnitude = 12.0;
      _settings.anchorReactionCount = 20;
      _settings.wordShatterThreshold = 18.0;
      _settings.wordShatterEnabled = true;
    });
  }

  String _gravityDescription(GravityPreset preset) {
    switch (preset) {
      case GravityPreset.zero:
        return 'Messages drift like astronauts on the ISS.';
      case GravityPreset.moon:
        return 'Everything floats slowly. Very chill.';
      case GravityPreset.earth:
        return 'Normal gravity. Familiar chaos.';
      case GravityPreset.jupiter:
        return 'Messages slam to the bottom. Barely movable.';
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.emoji,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.description,
  });

  final String label;
  final String emoji;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelLarge),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
