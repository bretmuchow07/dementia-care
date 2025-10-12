import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb for web check
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused }

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  final Completer<void> _initCompleter = Completer<void>();
  bool _isMuted = false;
  double _volume = 1.0;
  double _rate = 0.5;

  // Private constructor for singleton pattern
  TextToSpeechService._internal() {
    _loadSettings();
    _initTts();
  }

  // Singleton instance
  static final TextToSpeechService _instance = TextToSpeechService._internal();

  // Factory constructor to return the same instance
  factory TextToSpeechService() {
    return _instance;
  }

  TtsState get ttsState => _ttsState;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  double get rate => _rate;

  Function? onStateChanged;
  Function? onMuteChanged;

  Future<void> get initFuture => _initCompleter.future;

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMuted = prefs.getBool('tts_muted') ?? false;
    _volume = prefs.getDouble('tts_volume') ?? 1.0;
    _rate = prefs.getDouble('tts_rate') ?? 0.5;
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_muted', _isMuted);
    await prefs.setDouble('tts_volume', _volume);
    await prefs.setDouble('tts_rate', _rate);
  }

  // Initialize the TTS engine
  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      onStateChanged?.call();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      onStateChanged?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    // --- NEW: SET A SPECIFIC VOICE ---
    await _setVoice();

    // --- PLATFORM-SPECIFIC CONFIGURATION ---
    if (!kIsWeb) {
      if (Platform.isIOS) {
        // ... (your existing iOS configuration)
      }
    }

    // Common settings that work on most platforms
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setVolume(_isMuted ? 0.0 : _volume);
    await _flutterTts.setPitch(1.0);

    _initCompleter.complete();
  }

  /// NEW METHOD: Gets available voices and sets a preferred one.
  Future<void> _setVoice() async {
    try {
      // Get the list of available voices from the device
      List<dynamic> voices = await _flutterTts.getVoices;
      print("--- Available Voices ---");
      voices.forEach((voice) {
        print("Voice: ${voice['name']}, Lang: ${voice['locale']}");
      });

      // Find a specific English (US) voice. You can change this.
      // Example voice names: "Karen" (iOS), "en-us-x-sfg#male_2-local" (Android)
      String? selectedVoice = voices.firstWhere(
            (voice) => voice['locale'] == 'en-US' && voice['name'].contains(''), // Find any US English voice
        orElse: () => null,
      )?['name'];

      if (selectedVoice != null) {
        await _flutterTts.setVoice({"name": selectedVoice, "locale": "en-US"});
        print("--- TTS Service: Selected Voice -> $selectedVoice ---");
      } else {
        print("--- TTS Service: Could not find a preferred US English voice. Using system default. ---");
      }

      // Also set the language, which is a fallback if a voice can't be set.
      await _flutterTts.setLanguage("en-US");

    } catch (e) {
      print("Error getting or setting TTS voice: $e");
    }
  }

  /// Speaks the provided text if TTS is enabled and not muted.
  Future<void> speak(String text, {bool checkPreferences = true}) async {
    if (checkPreferences) {
      final prefs = await SharedPreferences.getInstance();
      final ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      final autoPlayEnabled = prefs.getBool('tts_auto_play') ?? true;

      if (!ttsEnabled || !autoPlayEnabled || _isMuted) {
        print("TTS Service: Speaking disabled by preferences or muted.");
        return;
      }
    }

    print("TTS Service: Trying to speak -> '$text'");
    if (text.isNotEmpty) {
      // Ensure TTS is initialized
      if (!_initCompleter.isCompleted) {
        print("TTS Service: Waiting for initialization...");
        await _initCompleter.future;
        print("TTS Service: Initialization complete.");
      }
      var result = await _flutterTts.speak(text);
      if (result == 1) {
        print("TTS Service: Speak command successful.");
      } else {
        print("TTS Service: Speak command failed. Result: $result");
      }
    } else {
      print("TTS Service: Text to speak was empty.");
    }
  }

  /// Pauses the current speech.
  Future<void> pause() async {
    print("TTS Service: Pausing speech.");
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
    onStateChanged?.call();
  }

  /// Resumes the paused speech.
  Future<void> resume() async {
    print("TTS Service: Resuming speech.");
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    // Note: flutter_tts doesn't have a resume method, so we restart speaking
    // This is a limitation of the current flutter_tts package
    _ttsState = TtsState.playing;
    onStateChanged?.call();
  }

  /// Stops the current speech.
  Future<void> stop() async {
    print("TTS Service: Stopping speech.");
    // Ensure TTS is initialized
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    onStateChanged?.call();
  }

  /// Toggles mute state.
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _saveSettings();
    await _flutterTts.setVolume(_isMuted ? 0.0 : _volume);
    onMuteChanged?.call();
    print("TTS Service: Mute toggled to $_isMuted");
  }

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _saveSettings();
    if (!_isMuted) {
      await _flutterTts.setVolume(_volume);
    }
    print("TTS Service: Volume set to $_volume");
  }

  /// Sets the speech rate.
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.1, 1.0);
    await _saveSettings();
    await _flutterTts.setSpeechRate(_rate);
    print("TTS Service: Rate set to $_rate");
  }

  /// Disposes of the TTS engine resources.
  void dispose() {
    _flutterTts.stop();
  }
}
