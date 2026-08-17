import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(AppConstants.tokenKey);

  runApp(SmartKhataApp(isLoggedIn: token != null && token.isNotEmpty));
}

class SmartKhataApp extends StatelessWidget {
  final bool isLoggedIn;

  const SmartKhataApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppConstants.creamBg,
        primaryColor: AppConstants.deepEmerald,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.deepEmerald,
          primary: AppConstants.deepEmerald,
          secondary: AppConstants.warmSage,
          surface: AppConstants.surfaceWhite,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontWeight: FontWeight.bold),
          headlineLarge: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.instrumentSerif(color: AppConstants.charcoal, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.creamBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.charcoal),
          titleTextStyle: GoogleFonts.instrumentSerif(
            color: AppConstants.charcoal,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.surfaceWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            side: const BorderSide(color: AppConstants.softBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.surfaceWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            borderSide: const BorderSide(color: AppConstants.softBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            borderSide: const BorderSide(color: AppConstants.softBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            borderSide: const BorderSide(color: AppConstants.deepEmerald, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
