import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import '../config/api_config.dart';
import 'token_storage.dart';

/// Voice & Audio Synthesis Service (Kausap AI Hands-Free Conversational Voice)
///
/// Powers:
///  1. Speech-to-Text: Hold/tap-to-record voice messages with live transcription.
///  2. Text-to-Speech: Comforting Mistral Voxtral neural voice playback with gentle browser fallback.
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

  /// Speaks the given text using high-fidelity Mistral Voxtral neural voice with browser fallback.
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onDone,
  }) async {
    stopSpeaking();

    _isSpeaking = true;
    _currentSpeakingText = text;
    onStart?.call();

    if (kIsWeb) {
      try {
        final token = await TokenStorage().getToken();
        final apiUrl = '${ApiConfig.baseUrl}${ApiConfig.chatTts}';
        final safeText = jsonEncode(text);
        final safeToken = jsonEncode(token ?? '');
        final safeUrl = jsonEncode(apiUrl);

        final jsCode = '''
        (function() {
          var text = $safeText;
          var token = $safeToken;
          var url = $safeUrl;

          if (window._kausapCurrentAudio) {
            try { window._kausapCurrentAudio.pause(); window._kausapCurrentAudio.currentTime = 0; } catch(e) {}
          }
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
          }

          // 1. Stream neural voice from Mistral Voxtral TTS via backend
          if (token && token.length > 5) {
            fetch(url, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
              },
              body: JSON.stringify({ text: text })
            })
            .then(function(res) {
              if (!res.ok) throw new Error('Voxtral TTS status: ' + res.status);
              return res.blob();
            })
            .then(function(blob) {
              var blobUrl = URL.createObjectURL(blob);
              var audio = new Audio(blobUrl);
              window._kausapCurrentAudio = audio;
              audio.play().catch(function() {
                fallbackSpeech(text);
              });
            })
            .catch(function(err) {
              console.log('Neural TTS fallback to browser TTS:', err);
              fallbackSpeech(text);
            });
          } else {
            fallbackSpeech(text);
          }

          function fallbackSpeech(t) {
            if ('speechSynthesis' in window) {
              var u = new SpeechSynthesisUtterance(t);
              u.rate = 0.95;
              u.pitch = 1.05;
              u.lang = 'en-PH';
              
              var voices = window.speechSynthesis.getVoices();
              for (var i = 0; i < voices.length; i++) {
                if (voices[i].lang.indexOf('en') !== -1 || voices[i].lang.indexOf('fil') !== -1) {
                  u.voice = voices[i];
                  break;
                }
              }
              window.speechSynthesis.speak(u);
            }
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
    final durationMs = (wordCount * 350).clamp(2500, 20000);
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
          """
          if (window._kausapCurrentAudio) {
            try { window._kausapCurrentAudio.pause(); window._kausapCurrentAudio.currentTime = 0; } catch(e) {}
          }
          if ('speechSynthesis' in window) { window.speechSynthesis.cancel(); }
          """
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
