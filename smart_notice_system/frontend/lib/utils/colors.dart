import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Professional deep blue
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryDark = Color(0xFF0D1642);
  
  // Accent color
  static const Color accent = Color(0xFF00BCD4);
  
  // Background colors
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Role colors
  static const Color superAdminColor = Color(0xFF7C3AED);
  static const Color adminColor = Color(0xFF1A237E);
  static const Color studentColor = Color(0xFF059669);
  static const Color hodColor = Color(0xFFDC2626);
  static const Color placementColor = Color(0xFFD97706);
  static const Color clubColor = Color(0xFF7C3AED);
  static const Color sportsColor = Color(0xFF0369A1);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3949AB), Color(0xFF00BCD4)],
  );
}