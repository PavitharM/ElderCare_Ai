import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Teal Gradients
  static const Color primary = Color(0xFF00838F);
  static const Color primaryDark = Color(0xFF006872);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color secondary = Color(0xFF009688);
  static const Color cyanAccent = Color(0xFF01A798);

  // Gradient stops
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00838F), Color(0xFF009688)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF007F8F), Color(0xFF008F91), Color(0xFF01A798)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
  );

  // High Stakes & Status
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color emergencyRedDark = Color(0xFFBA161C);
  static const Color emergencySoftBg = Color(0xFFFEE2E2);
  static const Color emergencyHalo = Color(0x33E53935);

  static const Color successGreen = Color(0xFF10B981);
  static const Color successSoftBg = Color(0xFFE8F5E9);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningSoftBg = Color(0xFFFEF3C7);

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color canvasLight = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Typography Neutrals
  static const Color textNavy = Color(0xFF0B3962);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtitle = Color(0xFF01869F);

  // Outlines & Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderCard = Color(0xCCE2E8F0);
  static const Color divider = Color(0xFFE5E7EB);
}
