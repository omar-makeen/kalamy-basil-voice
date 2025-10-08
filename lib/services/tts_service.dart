import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Initialize TTS with Arabic settings
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Discover available languages and pick best Arabic (Egypt) match, with fallbacks
      final available = await getLanguages();
      String selectedLang = 'ar-EG'; // Prefer Egyptian Arabic
      if (!available.contains(selectedLang)) {
        if (available.contains('ar-SA')) {
          selectedLang = 'ar-SA';
        } else {
          final anyArabic = available.firstWhere(
            (l) => l.toLowerCase().startsWith('ar'),
            orElse: () => available.isNotEmpty ? available.first : 'en-US',
          );
          selectedLang = anyArabic;
        }
      }
      await _flutterTts.setLanguage(selectedLang);

      // Set slower speech rate for clarity (web/android ranges are 0-1)
      await _flutterTts.setSpeechRate(0.6);

      // Set neutral pitch
      await _flutterTts.setPitch(1.0);

      // Set volume (1.0 = maximum)
      await _flutterTts.setVolume(1.0);

      // Ensure speak awaits completion on platforms that support it (incl. web)
      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (_) {}

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
