import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({Key? key}) : super(key: key);

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final _promptController = TextEditingController(text: 'چاول کا اسٹاک چیک کرو');
  bool _isProcessing = false;
  String _selectedLanguage = 'Urdu';
  Map<String, dynamic>? _responseResult;

  @override
  void initState() {
    super.initState();
    // Default demo intent result matching design 3
    _responseResult = {
      'intent': 'CHECK_STOCK',
      'reply': 'Basmati Rice (48 kg) - In stock',
      'product_name': 'Basmati Rice (48 kg)',
      'status': 'In stock',
      'time': 'Last updated today 8:30 AM',
    };
  }

  Future<void> _sendTextCommand([String? overrideText]) async {
    final text = (overrideText ?? _promptController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final client = ApiClient();
      final res = await client.post('/ai/intent', {'text': text});
      setState(() {
        _responseResult = res;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.alertRed),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamBg,
      appBar: AppBar(
        backgroundColor: AppConstants.creamBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voice Command',
          style: GoogleFonts.instrumentSerif(
            color: AppConstants.charcoal,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppConstants.charcoal),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // 1. Language selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLangChip('Urdu', _selectedLanguage == 'Urdu'),
                const SizedBox(width: 10),
                _buildLangChip('English', _selectedLanguage == 'English'),
                const SizedBox(width: 10),
                _buildLangChip('Punjabi', _selectedLanguage == 'Punjabi'),
              ],
            ),
            const SizedBox(height: 36),

            // 2. Central Mic Recording Animation Container
            GestureDetector(
              onTap: () => _sendTextCommand('چاول کا اسٹاک چیک کرو'),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.deepEmerald.withValues(alpha: 0.06),
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppConstants.deepEmerald.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.surfaceWhite,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.08),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          size: 38,
                          color: AppConstants.deepEmerald,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap mic to start / stop',
              style: GoogleFonts.inter(
                color: AppConstants.deepEmerald,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // 3. Speech Transcription Card ("You said")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppConstants.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You said',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _promptController.text,
                    style: GoogleFonts.notoNastaliqUrdu(
                      color: AppConstants.charcoal,
                      fontSize: 26,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check rice stock',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Action Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppConstants.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Result',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator(color: AppConstants.deepEmerald))
                  else
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppConstants.creamBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppConstants.deepEmerald,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _responseResult?['product_name'] ?? 'Basmati Rice (48 kg)',
                                style: GoogleFonts.inter(
                                  color: AppConstants.charcoal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppConstants.softGreenChip,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: AppConstants.deepEmerald, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'In stock',
                                          style: GoogleFonts.inter(
                                            color: AppConstants.deepEmerald,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _responseResult?['time'] ?? 'Last updated today 8:30 AM',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.deepEmerald : AppConstants.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppConstants.deepEmerald : AppConstants.softBorder,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppConstants.charcoal,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
