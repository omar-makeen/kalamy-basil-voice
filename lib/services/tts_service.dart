import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Initialize TTS with Arabic settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set language to Arabic (Saudi Arabia)
      await _flutterTts.setLanguage('ar-SA');

      // Set speech rate (0.8 = slower, clearer for children)
      await _flutterTts.setSpeechRate(0.8);

      // Set pitch (1.1 = slightly higher, friendly tone)
      await _flutterTts.setPitch(1.1);

      // Set volume (1.0 = maximum)
      await _flutterTts.setVolume(1.0);

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  // Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Stop any ongoing speech
      await _flutterTts.stop();

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  // Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('TTS pause error: $e');
    }
  }

  // Check if speaking
  Future<bool> isSpeaking() async {
    try {
      // Note: This might not work on all platforms
      return false; // Placeholder
    } catch (e) {
      print('TTS isSpeaking error: $e');
      return false;
    }
  }

  // Get available languages
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print('TTS getLanguages error: $e');
      return [];
    }
  }

  // Dispose
  void dispose() {
    _flutterTts.stop();
  }
}
