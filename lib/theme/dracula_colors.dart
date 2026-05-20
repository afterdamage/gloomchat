import 'package:flutter/material.dart';

/// Dracula design tokens for core colors.
///
/// Source palette:
/// - Background:    #282A36 (main dark background)
/// - Current Line:  #44475A (elevated / secondary surface)
/// - Foreground:    #F8F8F2 (primary text)
/// - Muted:         #6272A4 (comments / inactive states)
///
/// Accent colors (each defines its own theme):
/// - Cyan:          #8BE9FD
/// - Green:         #50FA7B
/// - Orange:        #FFB86C
/// - Pink:          #FF79C6
/// - Purple:        #BD93F9
/// - Red:           #FF5555
/// - Yellow:        #F1FA8C
class DraculaColors {
  DraculaColors._();

  // === Base surfaces (shared across all themes) ===
  static const Color background = Color(0xFF282A36);
  static const Color currentLine = Color(0xFF44475A);
  static const Color foreground = Color(0xFFF8F8F2);
  static const Color muted = Color(0xFF6272A4);

  // === Accent colors ===
  static const Color cyan = Color(0xFF8BE9FD);
  static const Color green = Color(0xFF50FA7B);
  static const Color orange = Color(0xFFFFB86C);
  static const Color pink = Color(0xFFFF79C6);
  static const Color purple = Color(0xFFBD93F9);
  static const Color red = Color(0xFFFF5555);
  static const Color yellow = Color(0xFFF1FA8C);
}

