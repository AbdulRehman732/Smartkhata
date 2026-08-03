import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Smart Khata';
  
  // Dynamic API Base URL for Web (Chrome/Edge) vs Android Emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api'; // Works for Windows Desktop, Chrome, and local dev
  }

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Pakistani Kiryana Theme Colors
  static const Color primaryGreen = Color(0xFF0F5132); // Vibrant Emerald Green
  static const Color accentGold = Color(0xFFD97706);   // Warm Golden Khata Accent
  static const Color darkBg = Color(0xFF111827);       // Deep Charcoal Dark Mode
  static const Color cardDark = Color(0xFF1F2937);     // Glassmorphic Surface
  static const Color errorRed = Color(0xFFDC2626);     // Alert Red
  static const Color textLight = Color(0xFFF9FAFB);    // Crisp Text
}
