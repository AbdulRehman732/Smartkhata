import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ApiClient();
      final response = await client.post('/auth/login', {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      });

      final token = response['access_token'];
      final role = response['role'];
      final name = response['name'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      await prefs.setString(AppConstants.userRoleKey, role);
      await prefs.setString(AppConstants.userNameKey, name);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('HttpException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Logo Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppConstants.deepEmerald,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'smart khata',
                      style: GoogleFonts.inter(
                        color: AppConstants.charcoal,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Welcome back header (Instrument Serif)
                Text(
                  'Welcome back',
                  style: GoogleFonts.instrumentSerif(
                    color: AppConstants.charcoal,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your Smart Khata account',
                  style: GoogleFonts.inter(
                    color: AppConstants.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppConstants.softRedChip,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.alertRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(color: AppConstants.alertRed, fontSize: 14),
                    ),
                  ),

                // Username / Phone Label & Input
                Text(
                  'Username or Phone number',
                  style: GoogleFonts.inter(
                    color: AppConstants.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(color: AppConstants.charcoal, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. admin or 3012345678',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppConstants.softBorder)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇵🇰', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            '+92',
                            style: GoogleFonts.inter(
                              color: AppConstants.charcoal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppConstants.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password / PIN Label & Input
                Text(
                  'Enter Password / PIN',
                  style: GoogleFonts.inter(
                    color: AppConstants.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.inter(color: AppConstants.charcoal, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, color: AppConstants.textMuted),
                  ),
                ),
                const SizedBox(height: 12),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        color: AppConstants.charcoal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Action Button (Continue ->)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.deepEmerald,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Biometric Login Prompt Icon
                Center(
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.fingerprint_rounded,
                          size: 40,
                          color: AppConstants.deepEmerald,
                        ),
                      ),
                      Text(
                        'Touch ID / Face ID',
                        style: GoogleFonts.inter(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
