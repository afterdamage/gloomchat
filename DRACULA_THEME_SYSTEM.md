# Dracula Accent Theme System

## Overview

GloomChat ships a complete Dracula-based theme system with **7 distinct accent themes**, all sharing the same dark base while using different accent colors for interactive elements.

## Architecture

```
lib/theme/
├── dracula_base.dart        # Shared surfaces, typography, spacing
├── dracula_colors.dart      # Raw color palette constants
├── dracula_text.dart        # Typography system
├── dracula_theme.dart       # Backward compatibility wrapper
├── dracula_accents.dart     # Enum + resolver
└── accents/
    ├── dracula_cyan.dart
    ├── dracula_green.dart
    ├── dracula_orange.dart
    ├── dracula_pink.dart
    ├── dracula_purple.dart
    ├── dracula_red.dart
    └── dracula_yellow.dart
```

## Shared Base (All Themes)

These colors are **consistent across all accent themes**:

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#282A36` | Main dark background |
| Current Line | `#44475A` | Elevated surfaces, cards, inputs |
| Foreground | `#F8F8F2` | Primary text color |
| Muted | `#6272A4` | Inactive states, timestamps, metadata |

## Accent Themes

Each accent color defines its own theme variation:

### 🔵 Cyan (`#8BE9FD`)
**Vibe:** Cool, fresh, tech-forward
```dart
DraculaAccent.cyan
```

### 🟢 Green (`#50FA7B`)
**Vibe:** Natural, positive, success-oriented
```dart
DraculaAccent.green
```

### 🟠 Orange (`#FFB86C`)
**Vibe:** Warm, energetic, creative
```dart
DraculaAccent.orange
```

### 🩷 Pink (`#FF79C6`)
**Vibe:** Playful, bold, expressive
```dart
DraculaAccent.pink
```

### 🟣 Purple (`#BD93F9`)
**Vibe:** Classic Dracula, elegant, premium (default)
```dart
DraculaAccent.purple
```

### 🔴 Red (`#FF5555`)
**Vibe:** Bold, urgent, attention-grabbing
```dart
DraculaAccent.red
```
*Note: Uses darker red variant (`#CC4444`) for error states*

### 🟡 Yellow (`#F1FA8C`)
**Vibe:** Bright, optimistic, cheerful
```dart
DraculaAccent.yellow
```

## Usage

### Quick Start

```dart
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/config/themes.dart';

// Build theme for a specific accent
ThemeData theme = AppThemes.buildAccentTheme(
  context,
  DraculaAccent.purple, // or cyan, green, etc.
);

// Or use the resolver directly
ThemeData theme = DraculaThemeResolver.getTheme(
  DraculaAccent.cyan,
  context,
  isColumnMode: false,
);
```

### Get Color Scheme Only

```dart
ColorScheme colors = DraculaThemeResolver.getColorScheme(DraculaAccent.pink);
```

### Theme Preview Info

```dart
// Get accent metadata
String name = DraculaAccent.purple.displayName; // "Purple"
String desc = DraculaAccent.purple.description;  // "Classic Dracula..."
Color preview = DraculaAccent.purple.previewColor; // #BD93F9
```

### Example: Theme Selector

```dart
import 'package:afterdamage/theme/dracula_accents.dart';

class ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: DraculaAccent.values.map((accent) {
        return GestureDetector(
          onTap: () => _setAccent(accent),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: accent.previewColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                accent.displayName,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

## Where Accent Colors Are Applied

The accent color is used for **UI signals, hierarchy, and focus**:

### Primary Usage
- ✅ AppBar icons and highlights
- ✅ Floating action buttons
- ✅ Active room indicator in chat list
- ✅ Selected settings items
- ✅ Progress indicators & loading spinners
- ✅ Toggles, switches, radio buttons
- ✅ Checkboxes when selected
- ✅ Tab bar indicators
- ✅ Slider active track
- ✅ Text links
- ✅ Mentions and replies in messages
- ✅ Reaction bubble borders (when reacted)
- ✅ Primary/filled button backgrounds
- ✅ Focused input field borders

### What Stays Base Colors
- ❌ Background (`#282A36`)
- ❌ Message bubble surfaces
- ❌ Input field backgrounds
- ❌ Card backgrounds
- ❌ Primary text color
- ❌ Inactive/muted states (`#6272A4`)

## Design Tokens

All themes share these design tokens:

### Border Radius
```dart
DraculaBase.radiusSmall     // 8px
DraculaBase.radiusMedium    // 12px
DraculaBase.radiusLarge     // 16px
```

### Spacing
```dart
DraculaBase.spacingXs  // 4px
DraculaBase.spacingSm  // 8px
DraculaBase.spacingMd  // 12px
DraculaBase.spacingLg  // 16px
DraculaBase.spacingXl  // 24px
```

### Helper Methods
```dart
DraculaBase.mutedForeground()  // #6272A4 at 90% opacity
```

## Integration with GloomChat

### Current Implementation
The theme system is infrastructure-complete but not yet wired to user settings. The app currently uses the purple theme via backward compatibility.

### To Add User Selection
1. Add accent preference to `lib/config/setting_keys.dart`
2. Create theme picker UI (optional, see example above)
3. Update `lib/widgets/gloom_chat_app.dart` to read preference
4. Pass selected accent to `GloomThemes.buildAccentTheme()`

Example settings integration:
```dart
// In setting_keys.dart
static final accentTheme = ValueNotifier<DraculaAccent>(
  DraculaAccent.purple,
);

// In gloom_chat_app.dart
darkTheme: GloomThemes.buildAccentTheme(
  context,
  AppSettings.accentTheme.value,
),
```

## Design Philosophy

### Consistency Over Creativity
- Base surfaces are **never** accent-colored
- Accent is for **signal**, not decoration
- All themes feel like Dracula first, colored second

### Subtlety Over Saturation
- Accent containers use 10-20% opacity
- Gradients and heavy saturation avoided
- Focus on clarity and readability

### Snazzy but Restrained
- Premium, intentional feel
- Clear visual hierarchy
- Hacker-clean aesthetic

## Backward Compatibility

The original `DraculaTheme` class is preserved:

```dart
// Old usage still works
ColorScheme scheme = DraculaTheme.darkColorScheme();
DraculaTheme.spacingMd // Still available
```

All spacing and radius constants are delegated to `DraculaBase` for consistency.

## Technical Notes

- All themes extend from `DraculaBase.buildTheme()`
- ColorScheme uses Material 3 color roles
- Typography via `DraculaText` with bundled FreeSans and limited fallbacks
- Zero logic changes outside UI layer
- No new dependencies added

## Future Enhancements

Potential additions (not yet implemented):
- User-facing theme picker UI
- Persistence of accent preference
- Custom accent color support
- Light mode Dracula variants
- Per-room accent overrides

---

**Status:** ✅ Infrastructure Complete  
**User Selection:** ⏳ Pending (infrastructure ready)  
**Default:** Purple accent (classic Dracula)
