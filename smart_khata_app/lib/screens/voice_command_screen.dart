import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({Key? key}) : super(key: key);

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final _promptController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _responseResult;

  Future<void> _sendTextCommand() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _responseResult = null;
    });

    try {
      final client = ApiClient();
      final res = await client.post('/ai/intent', {'text': text});
      setState(() {
        _responseResult = res;
        _isProcessing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppConstants.errorRed),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: const Text('Smart Khata AI Voice Assistant'),
        backgroundColor: AppConstants.cardDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Voice Wave Visualizer Placeholder Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.mic_rounded, size: 64, color: AppConstants.accentGold),
                  SizedBox(height: 12),
                  Text(
                    'Speak or type commands in English, Urdu, or Punjabi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Example: "chawal ka stock check karo" or "Ali ka balance kitna hai"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prompt Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type command here...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: AppConstants.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppConstants.primaryGreen),
                  onPressed: _isProcessing ? null : _sendTextCommand,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI Response Display Card
            if (_isProcessing)
              const CircularProgressIndicator(color: AppConstants.primaryGreen),

            if (_responseResult != null)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          backgroundColor: AppConstants.primaryGreen,
                          label: Text(
                            'INTENT: ${_responseResult!['intent'].toString().toUpperCase()}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const Icon(Icons.smart_toy_rounded, color: AppConstants.accentGold),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _responseResult!['reply'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
