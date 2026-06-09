import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFF8B85FF);

  // Background
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF242440);
  static const Color card = Color(0xFF1E1E35);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textHint = Color(0xFF6B6B8A);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Games
  static const Color pubgColor = Color(0xFFFFD700);
  static const Color freeFireColor = Color(0xFFFF4500);
  static const Color efootballColor = Color(0xFF0066CC);
  static const Color eafcColor = Color(0xFF00A651);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF3D3A9E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pubgGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient freeFireGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFF8B1A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient efootballGradient = LinearGradient(
    colors: [Color(0xFF0066CC), Color(0xFF003366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient eafcGradient = LinearGradient(
    colors: [Color(0xFF00A651), Color(0xFF004D24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer
  static const Color shimmerBase = Color(0xFF1E1E35);
  static const Color shimmerHighlight = Color(0xFF2D2D50);

  // Divider
  static const Color divider = Color(0xFF2A2A45);

  // Input
  static const Color inputFill = Color(0xFF1E1E35);
  static const Color inputBorder = Color(0xFF3A3A5C);
  static const Color inputFocused = Color(0xFF6C63FF);
}
