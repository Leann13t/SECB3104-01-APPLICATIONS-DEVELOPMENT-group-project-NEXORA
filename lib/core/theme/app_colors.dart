import 'package:flutter/material.dart';

class AppColors {
  // Cultural Adventure Palette
  static const Color background = Color(0xFFFFF9F0); // Warm Cream
  static const Color primaryTeal = Color(0xFF4A9188); // Primary Teal
  static const Color lightMint = Color(0xFFDFF7F2); // Light Mint
  static const Color coral = Color(0xFFFFAB99); // Coral Accent
  static const Color gold = Color(0xFFF2C66D); // Gold / Yellow Accent
  static const Color lavender = Color(0xFFE8E0F8); // Lavender Accent
  static const Color darkBrown = Color(
    0xFF493C35,
  ); // Dark Brown (Text & Outlines)
  static const Color secondaryText = Color(0xFF7B7471); // Muted Text
  static const Color white = Color(0xFFFFFFFF);

  // Functional Aliases for backward compatibility
  static const Color primary = primaryTeal;
  static const Color primaryDark = Color(0xFF38726A);
  static const Color secondary = gold;
  static const Color surface = white;
  static const Color textPrimary = darkBrown;
  static const Color border = Color(0xFFEADBC8);
  static const Color cardOutline = Color(0xFF5A4D47);
  static const Color cardShadow = Color(0xFFD6CBC3);

  // Status Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color approvedGreen = Color(0xFF2E8578);
  static const Color approvedBadgeBg = Color(0xFFD4F6E6);
}
