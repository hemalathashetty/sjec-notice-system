import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark  = Color(0xFF0A0E3F);
  static const Color accent       = Color(0xFF00E5FF);
  static const Color accentPink   = Color(0xFFE040FB);
  static const Color accentGold   = Color(0xFFFFD740);
  static const Color background   = Color(0xFFEEF1F8);
  static const Color surfaceDark  = Color(0xFF0D1B5E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color glassWhite   = Color(0x26FFFFFF);
  static const Color glassBorder  = Color(0x40FFFFFF);
  static const Color textPrimary  = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight    = Color(0xFFFFFFFF);
  static const Color textMuted    = Color(0x99FFFFFF);
  static const Color success      = Color(0xFF00E676);
  static const Color warning      = Color(0xFFFFD740);
  static const Color error        = Color(0xFFFF1744);
  static const Color info         = Color(0xFF40C4FF);
  static const Color superAdminColor = Color(0xFFAA00FF);
  static const Color adminColor   = Color(0xFF2979FF);
  static const Color studentColor = Color(0xFF00E676);
  static const Color hodColor     = Color(0xFFFF6D00);
  static const Color placementColor = Color(0xFFFFD740);
  static const Color clubColor    = Color(0xFFD500F9);
  static const Color sportsColor  = Color(0xFF00E5FF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF080F3A), Color(0xFF1A237E), Color(0xFF0288D1)],
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E3F), Color(0xFF1A237E), Color(0xFF00BCD4)],
    stops: [0.0, 0.6, 1.0],
  );
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF5C6BC0), Color(0xFF00E5FF)],
  );
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF080F3A), Color(0xFF0D1B5E), Color(0xFF1A237E)],
    stops: [0.0, 0.5, 1.0],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3949AB), Color(0xFF00BCD4)],
  );
}