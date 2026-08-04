import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Smart Khata';
  
  // Dynamic API Base URL for Web (Chrome/Edge) vs Android Emulator
  // Dynamic API Base URL for Web, Desktop, and Physical Mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    // Physical mobile device IP fallback or ADB reverse localhost
    return 'http://192.168.100.12:8000/api';
  }

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Pakistani Kiryana / Dukaan Design System 1.0 Colors
  static const Color deepEmerald = Color(0xFF0F5132);    // Primary Emerald Green
  static const Color primaryGreen = Color(0xFF0F5132);   // Backward compatibility alias
  static const Color warmSage = Color(0xFF7DA37D);      // Secondary Soft Accent
  static const Color creamBg = Color(0xFFF7F3EB);        // Warm Cream Scaffold Background
  static const Color surfaceWhite = Color(0xFFFFFFFF);   // Card & Input Background
  static const Color charcoal = Color(0xFF1C1C1C);       // Primary Typography & Dark Accent
  static const Color textDark = Color(0xFF1C1C1C);       // Backward compatibility alias
  static const Color textMuted = Color(0xFF6B7280);      // Secondary Muted Typography
  static const Color mutedTerracotta = Color(0xFFC46A4A);// Credit / Khata Highlight
  static const Color accentGold = Color(0xFFC46A4A);      // Alias for Khata highlight
  static const Color alertRed = Color(0xFFC0392B);       // Low stock / alert red
  static const Color errorRed = Color(0xFFC0392B);       // Alias for alert red
  static const Color softGreenChip = Color(0xFFE6F2ED);  // Paid status / active chip bg
  static const Color softRedChip = Color(0xFFFDF2F2);    // Low stock / alert chip bg
  static const Color softBorder = Color(0xFFE5E7EB);     // Subtle card border
  static const Color darkBg = Color(0xFF111827);       // Deep Charcoal Dark Mode
  static const Color cardDark = Color(0xFF1F2937);     // Glassmorphic Surface
  static const Color textLight = Color(0xFFF9FAFB);    // Crisp Light Text

  // UI Radiuses & Shadows
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
}
