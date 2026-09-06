import 'dart:async';
import 'package:flutter/foundation.dart';

// Web Audio interop for browsers
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

enum AmbientSoundType {
  singingBowl,
  rain,
  ocean,
  forest,
  campfire,
  silence,
}

class AmbientSoundOption {
  final AmbientSoundType type;
  final String label;
  final String emoji;
  final String fileName;
  final String cdnPath;
  final String subtitle;

  const AmbientSoundOption({
    required this.type,
    required this.label,
    required this.emoji,
    required this.fileName,
    required this.cdnPath,
    required this.subtitle,
  });
}

class AmbientAudioService {
  static final AmbientAudioService _instance = AmbientAudioService._internal();
  factory AmbientAudioService() => _instance;
  AmbientAudioService._internal();

  AmbientSoundType _currentSound = AmbientSoundType.silence;
  AmbientSoundType get currentSound => _currentSound;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _volume = 0.7;
  double get volume => _volume;

  Timer? _synthTimer;

  static const List<AmbientSoundOption> soundOptions = [
    AmbientSoundOption(
      type: AmbientSoundType.singingBowl,
      label: 'Singing Bowl',
      emoji: '🔔',
      fileName: 'singing_bowl.mp3',
      cdnPath: 'things/singing-bowl.mp3',
      subtitle: 'Tibetan Brass Resonance',
    ),
    AmbientSoundOption(
      type: AmbientSoundType.rain,
      label: 'Gentle Rain',
      emoji: '🌧️',
      fileName: 'rain.mp3',
      cdnPath: 'rain/rain-on-leaves.mp3',
      subtitle: 'Raindrops on Lush Leaves',
    ),
    AmbientSoundOption(
      type: AmbientSoundType.ocean,
      label: 'Ocean Waves',
      emoji: '🌊',
      fileName: 'waves.mp3',
      cdnPath: 'nature/waves.mp3',
      subtitle: 'Rhythmic Coastal Swells',
    ),
    AmbientSoundOption(
      type: AmbientSoundType.forest,
      label: 'Forest Birds',
      emoji: '🌲',
      fileName: 'forest.mp3',
      cdnPath: 'animals/birds.mp3',
      subtitle: 'Morning Songbirds & Leaves',
    ),
    AmbientSoundOption(
      type: AmbientSoundType.campfire,
      label: 'Campfire',
      emoji: '🔥',
      fileName: 'campfire.mp3',
      cdnPath: 'nature/campfire.mp3',
      subtitle: 'Warm Crackling Embers',
    ),
    AmbientSoundOption(
      type: AmbientSoundType.silence,
      label: 'Mute',
      emoji: '🔇',
      fileName: '',
      cdnPath: '',
      subtitle: 'Pure Silence',
    ),
  ];

  static AmbientSoundOption getOption(AmbientSoundType type) {
    return soundOptions.firstWhere(
      (opt) => opt.type == type,
      orElse: () => soundOptions.last,
    );
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          if (window._kausapAmbientAudio) {
            window._kausapAmbientAudio.volume = $_volume;
          }
          if (window._kausapGain && window._kausapAudioCtx) {
            window._kausapGain.gain.setValueAtTime($_volume, window._kausapAudioCtx.currentTime);
          }
        ''']);
      } catch (_) {}
    }
  }

  /// Play an ambient soundscape continuously
  void play(AmbientSoundType sound) {
    _currentSound = sound;
    if (sound == AmbientSoundType.silence) {
      stop();
      return;
    }
    _isPlaying = true;

    final opt = getOption(sound);
    if (kIsWeb) {
      _startWebAudioElement(opt);
    }
  }

  void pause() {
    _isPlaying = false;
    _synthTimer?.cancel();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          if (window._kausapAmbientAudio) {
            window._kausapAmbientAudio.pause();
          }
          if (window._kausapAudioCtx) {
            window._kausapAudioCtx.suspend();
          }
        ''']);
      } catch (_) {}
    }
  }

  void resume() {
    if (_currentSound != AmbientSoundType.silence) {
      _isPlaying = true;
      if (kIsWeb) {
        try {
          js.context.callMethod('eval', ['''
            if (window._kausapAmbientAudio) {
              window._kausapAmbientAudio.play().catch(function(){});
            } else if (window._kausapAudioCtx) {
              window._kausapAudioCtx.resume();
            }
          ''']);
        } catch (_) {
          play(_currentSound);
        }
      }
    }
  }

  void stop() {
    _isPlaying = false;
    _synthTimer?.cancel();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['''
          if (window._kausapAmbientAudio) {
            try {
              window._kausapAmbientAudio.pause();
              window._kausapAmbientAudio.currentTime = 0;
            } catch(e) {}
            window._kausapAmbientAudio = null;
          }
          if (window._kausapAudioCtx) {
            try {
              if (window._kausapGain) {
                window._kausapGain.gain.setValueAtTime(0, window._kausapAudioCtx.currentTime);
              }
              window._kausapAudioCtx.close();
            } catch(e) {}
            window._kausapAudioCtx = null;
          }
        ''']);
      } catch (_) {}
    }
  }

  /// Plays high-quality recorded ASMR soundscape with multi-tier fallback:
  /// 1. Local web server asset (web/assets/audio/)
  /// 2. Flutter asset bundle (assets/assets/audio/)
  /// 3. Direct root path (/assets/audio/)
  /// 4. GitHub Raw CDN fallback
  void _startWebAudioElement(AmbientSoundOption option) {
    if (option.fileName.isEmpty) {
      stop();
      return;
    }

    final fileName = option.fileName;
    final cdnPath = option.cdnPath;

    final jsCode = '''
    (function() {
      try {
        // Stop any currently playing ambient audio
        if (window._kausapAmbientAudio) {
          try {
            window._kaapAmbientAudio = null;
            window._kausapAmbientAudio.pause();
            window._kausapAmbientAudio.currentTime = 0;
          } catch(e) {}
          window._kausapAmbientAudio = null;
        }

        // Close fallback synth if running
        if (window._kausapAudioCtx) {
          try { window._kausapAudioCtx.close(); } catch(e) {}
          window._kausapAudioCtx = null;
        }

        var candidateUrls = [
          "assets/audio/" + "$fileName",
          "assets/assets/audio/" + "$fileName",
          "/assets/audio/" + "$fileName",
          "https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/" + "$cdnPath"
        ];

        var audio = new Audio();
        audio.loop = true;
        audio.volume = $_volume;
        audio.preload = "auto";
        window._kausapAmbientAudio = audio;

        var candidateIndex = 0;
        function tryNextCandidate() {
          if (candidateIndex >= candidateUrls.length) {
            console.warn('[Kausap Ambient] All audio candidates failed for: $fileName');
            return;
          }
          var nextUrl = candidateUrls[candidateIndex++];
          audio.src = nextUrl;
          var playPromise = audio.play();
          if (playPromise && playPromise.catch) {
            playPromise.catch(function(err) {
              console.log('[Kausap Ambient] Attempt ' + (candidateIndex) + ' deferred or failed:', nextUrl, err);
            });
          }
        }

        audio.addEventListener('error', function(e) {
          console.warn('[Kausap Ambient] Audio source error on:', audio.src, 'trying next source...');
          tryNextCandidate();
        });

        tryNextCandidate();
      } catch(err) {
        console.warn('[Kausap Ambient] Web audio element error:', err);
      }
    })();
    ''';

    try {
      js.context.callMethod('eval', [jsCode]);
    } catch (e) {
      debugPrint('[AmbientAudioService] Failed to run web audio: $e');
    }
  }

  /// Play a gentle chime tone for transitions / breathing / timer finish
  void playChime({double frequency = 432.0, double durationSeconds = 1.8}) {
    if (kIsWeb) {
      try {
        final jsCode = '''
        (function() {
          try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            var ctx = new AudioCtx();
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime($frequency, ctx.currentTime);
            osc.frequency.exponentialRampToValueAtTime($frequency * 0.5, ctx.currentTime + $durationSeconds);
            gain.gain.setValueAtTime(${_volume * 0.4}, ctx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + $durationSeconds);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + $durationSeconds);
          } catch(e) {}
        })();
        ''';
        js.context.callMethod('eval', [jsCode]);
      } catch (_) {}
    }
  }

  /// Play voice prompt cue for breathing
  void playBreathingCue(String phaseName) {
    if (phaseName.toLowerCase().contains('inhale')) {
      playChime(frequency: 528.0, durationSeconds: 1.2);
    } else if (phaseName.toLowerCase().contains('hold')) {
      playChime(frequency: 432.0, durationSeconds: 0.8);
    } else if (phaseName.toLowerCase().contains('exhale')) {
      playChime(frequency: 396.0, durationSeconds: 1.5);
    }
  }
}
