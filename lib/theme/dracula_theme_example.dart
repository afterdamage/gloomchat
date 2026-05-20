import 'package:flutter/material.dart';
import 'package:afterdamage/widgets/square_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/config/themes.dart';

/// Example demonstrating the Dracula accent theme system.
/// 
/// This file shows how to:
/// 1. Use the accent theme enum
/// 2. Build themes for different accents
/// 3. Create a theme selector UI
class DraculaThemeExample extends StatefulWidget {
  const DraculaThemeExample({super.key});

  @override
  State<DraculaThemeExample> createState() => _DraculaThemeExampleState();
}

class _DraculaThemeExampleState extends State<DraculaThemeExample> {
  DraculaAccent _selectedAccent = DraculaAccent.purple;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dracula Accent Demo',
      // Use the new accent theme system
      theme: GloomThemes.buildAccentTheme(context, _selectedAccent),
      home: Scaffold(
        appBar: AppBar(
          title: Text('${_selectedAccent.displayName} Theme'),
        ),
        body: Column(
          children: [
            // Theme selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: DraculaAccent.values.map((accent) {
                  final isSelected = accent == _selectedAccent;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAccent = accent),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: accent.previewColor,
                        borderRadius: BorderRadius.zero,
                        border: isSelected
                            ? Border.all(
                                color: Colors.white,
                                width: 3,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.previewColor.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            accent.displayName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isSelected)
                            const Icon(
                              FontAwesomeIcons.solidCircleCheck,
                              color: Colors.black,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Theme description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _selectedAccent.description,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            
            // Component showcase
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Buttons
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Filled Button'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Elevated Button'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Switch
                  SquareSwitchListTile(
                    title: const Text('Toggle Switch'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  
                  // Checkbox
                  CheckboxListTile(
                    title: const Text('Checkbox Example'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  
                  // Radio
                  RadioListTile(
                    title: const Text('Radio Example'),
                    value: 1,
                    groupValue: 1,
                    onChanged: (_) {},
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Chip
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text('Chip 1')),
                      Chip(label: Text('Selected'), backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress indicator
                  LinearProgressIndicator(),
                  
                  const SizedBox(height: 16),
                  
                  // Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Example',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This demonstrates how the ${_selectedAccent.displayName} accent theme affects various components.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const FaIcon(FontAwesomeIcons.plus),
        ),
      ),
    );
  }
}
