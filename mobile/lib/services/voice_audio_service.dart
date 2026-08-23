import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Voice & Audio Synthesis Service (Kausap AI Hands-Free Conversational Voice)
///
/// Powers:
///  1. Speech-to-Text: Hold/tap-to-record voice messages with live transcription.
///  2. Text-to-Speech: Comforting voice playback of Kausap AI messages with gentle cadence.
class VoiceAudioService {
  static final VoiceAudioService _instance = VoiceAudioService._internal();
  factory VoiceAudioService() => _instance;
  VoiceAudioService._internal();

  bool _isSpeaking = false;
  bool _isListening = false;
  String _currentSpeakingText = '';
  Timer? _speechPollerTimer;
  Timer? _speechFallbackTimer;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String get currentSpeakingText => _currentSpeakingText;

  /// Speaks the given text using warm, gentle, and natural speech synthesis.
  void speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) {
    stopSpeaking();

    _isSpeaking = true;
    _currentSpeakingText = text;
    onStart?.call();

    if (kIsWeb) {
      try {
        final safeText = jsonEncode(text);
        final jsCode = '''
        (function() {
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
            var u = new SpeechSynthesisUtterance($safeText);
            u.rate = 0.95;
            u.pitch = 1.05;
            u.lang = 'en-PH';
            
            // Try to find a warm, natural voice
            var voices = window.speechSynthesis.getVoices();
            for (var i = 0; i < voices.length; i++) {
              if (voices[i].lang.indexOf('en') !== -1 || voices[i].lang.indexOf('fil') !== -1) {
                u.voice = voices[i];
                break;
              }
            }

            window.speechSynthesis.speak(u);
          }
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (e) {
        debugPrint('VoiceAudioService speak web error: $e');
      }
    }

    // Safety fallback timer to automatically reset speaking state
    final wordCount = text.split(' ').length;
    final durationMs = (wordCount * 300).clamp(2000, 15000);
    _speechFallbackTimer?.cancel();
    _speechFallbackTimer = Timer(Duration(milliseconds: durationMs), () {
      if (_isSpeaking && _currentSpeakingText == text) {
        _isSpeaking = false;
        _currentSpeakingText = '';
        onDone?.call();
      }
    });
  }

  /// Cancels active speech playback immediately.
  void stopSpeaking() {
    _speechFallbackTimer?.cancel();
    _isSpeaking = false;
    _currentSpeakingText = '';

    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          "if ('speechSynthesis' in window) { window.speechSynthesis.cancel(); }"
        ]);
      } catch (_) {}
    }
  }

  /// Starts listening to the microphone for student voice input.
  void startListening({
    required Function(String transcript) onResult,
    VoidCallback? onStop,
  }) {
    stopListening();
    stopSpeaking();

    _isListening = true;

    if (kIsWeb) {
      try {
        const jsCode = '''
        (function() {
          var SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (!SpeechRec) {
            window._kausapSpeechSupported = false;
            return;
          }
          window._kausapSpeechSupported = true;
          if (window._kausapLiveSpeechRec) {
            try { window._kausapLiveSpeechRec.stop(); } catch(e) {}
          }
          var rec = new SpeechRec();
          rec.continuous = true;
          rec.interimResults = true;
          rec.lang = 'en-PH';
          window._kausapLiveSpeechRec = rec;
          window._kausapLiveTranscript = "";

          rec.onresult = function(event) {
            var full = '';
            for (var i = 0; i < event.results.length; ++i) {
              full += event.results[i][0].transcript + ' ';
            }
            window._kausapLiveTranscript = full.trim();
          };

          rec.onerror = function(e) {
            console.log("Speech recognition error:", e);
          };

          rec.start();
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);

        // Start polling transcript from JS bridge
        _speechPollerTimer?.cancel();
        String lastTranscript = '';
        _speechPollerTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
          if (!_isListening) {
            t.cancel();
            return;
          }
          try {
            final transcript = js.context['window']['_kausapLiveTranscript'] as String?;
            if (transcript != null && transcript.isNotEmpty && transcript != lastTranscript) {
              lastTranscript = transcript;
              onResult(transcript);
            }
          } catch (_) {}
        });
      } catch (e) {
        debugPrint('VoiceAudioService listening web error: $e');
      }
    }
  }

  /// Stops microphone listening.
  void stopListening({VoidCallback? onDone}) {
    _isListening = false;
    _speechPollerTimer?.cancel();

    if (kIsWeb) {
      try {
        const jsCode = '''
        (function() {
          if (window._kausapLiveSpeechRec) {
            try { window._kausapLiveSpeechRec.stop(); } catch(e) {}
            window._kausapLiveSpeechRec = null;
          }
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (_) {}
    }

    onDone?.call();
  }
}
