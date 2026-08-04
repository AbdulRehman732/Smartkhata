import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({Key? key}) : super(key: key);

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final _promptController = TextEditingController(text: 'چاول کا اسٹاک چیک کرو');
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'Urdu'; // 'Urdu', 'English', 'Punjabi'
  Map<String, dynamic>? _responseResult;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _initSpeech();
    _responseResult = {
      'intent': 'CHECK_STOCK',
      'reply': 'Basmati Rice (48 kg) - In stock',
      'product_name': 'Basmati Rice (48 kg)',
      'status': 'In stock',
      'time': 'Last updated today 8:30 AM',
    };
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;
    try {
      if (_selectedLanguage == 'Urdu' || _selectedLanguage == 'Punjabi') {
        await _flutterTts.setLanguage('ur-PK');
      } else {
        await _flutterTts.setLanguage('en-US');
      }
      final cleanText = text.replaceAll(RegExp(r'[^\w\s\.\,\:\-]'), '').trim();
      if (cleanText.isNotEmpty) {
        await _flutterTts.speak(cleanText);
      }
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              setState(() => _isListening = false);
              if (_promptController.text.trim().isNotEmpty) {
                _sendTextCommand(_promptController.text);
              }
            }
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
        },
      );
      setState(() {
        _speechAvailable = available;
      });
    } catch (_) {
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_promptController.text.trim().isNotEmpty) {
        _sendTextCommand(_promptController.text);
      }
    } else {
      if (!_speechAvailable) {
        bool reinit = await _speech.initialize();
        if (!reinit) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission not granted or speech recognition unavailable.'),
              backgroundColor: AppConstants.alertRed,
            ),
          );
          return;
        }
      }

      String locale = 'ur_PK';
      if (_selectedLanguage == 'English') {
        locale = 'en_US';
      } else if (_selectedLanguage == 'Punjabi') {
        locale = 'ur_PK'; // Urdu/Punjabi ASR engine locale
      }

      setState(() {
        _isListening = true;
      });

      _speech.listen(
        localeId: locale,
        onResult: (result) {
          setState(() {
            _promptController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> _sendTextCommand([String? overrideText]) async {
    final text = (overrideText ?? _promptController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _promptController.text = text;
    });

    try {
      final client = ApiClient();
      final res = await client.post('/ai/intent', {'text': text});
      setState(() {
        _responseResult = res;
        _isProcessing = false;
      });

      final replyText = res['reply'] as String?;
      if (replyText != null && replyText.isNotEmpty) {
        _speakResponse(replyText);
      }
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
          'Voice Command System',
          style: GoogleFonts.instrumentSerif(
            color: AppConstants.charcoal,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            const SizedBox(height: 28),

            // 2. Central Mic Recording Button & Pulse Visualizer
            GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isListening ? 180 : 150,
                height: _isListening ? 180 : 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? AppConstants.alertRed.withOpacity(0.15)
                      : AppConstants.deepEmerald.withOpacity(0.08),
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? AppConstants.alertRed.withOpacity(0.3)
                          : AppConstants.deepEmerald.withOpacity(0.18),
                    ),
                    child: Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? AppConstants.alertRed : AppConstants.deepEmerald,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? AppConstants.alertRed.withOpacity(0.4)
                                  : AppConstants.deepEmerald.withOpacity(0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isListening ? 'Listening... Speak now' : 'Tap microphone to speak command',
              style: GoogleFonts.inter(
                color: _isListening ? AppConstants.alertRed : AppConstants.deepEmerald,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),

            // 3. Quick Sample Voice Commands
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sample Commands (Tap to test):',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickCommand('چاول کا اسٹاک چیک کرو'),
                  const SizedBox(width: 8),
                  _buildQuickCommand('Muhammad Ali ne 500 rupay jamah karwaye'),
                  const SizedBox(width: 8),
                  _buildQuickCommand('Ali ko 2 kilo chawal credit per becho'),
                  const SizedBox(width: 8),
                  _buildQuickCommand('Ali Cashier ki aaj ki hazari lagao'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Speech Transcription Card ("You said")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transcribed Command',
                        style: GoogleFonts.inter(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppConstants.deepEmerald, size: 20),
                        onPressed: () => _sendTextCommand(),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _promptController,
                    maxLines: 2,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Speak or type your command here...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. Action Result Card
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
                    'AI Execution Result',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppConstants.deepEmerald),
                      ),
                    )
                  else if (_responseResult != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.softGreenChip,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _responseResult!['intent'] ?? 'EXECUTED',
                                style: GoogleFonts.inter(
                                  color: AppConstants.deepEmerald,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _responseResult!['reply'] ?? 'Action completed successfully.',
                          style: GoogleFonts.inter(
                            color: AppConstants.charcoal,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppConstants.charcoal,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCommand(String text) {
    return ActionChip(
      label: Text(text, style: GoogleFonts.inter(fontSize: 12)),
      backgroundColor: AppConstants.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppConstants.softBorder),
      ),
      onPressed: () => _sendTextCommand(text),
    );
  }
}

