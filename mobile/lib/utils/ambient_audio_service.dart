import 'dart:async';
import 'package:flutter/foundation.dart';

// Web Audio interop for browsers
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

enum AmbientSoundType {
  rain,
  ocean,
  forest,
  singingBowl,
  silence,
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

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['if (window._kausapGain) { window._kausapGain.gain.setValueAtTime($_volume, window._kausapAudioCtx.currentTime); }']);
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

    if (kIsWeb) {
      _startWebAudioSynthesizer(sound);
    }
  }

  void pause() {
    _isPlaying = false;
    _synthTimer?.cancel();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['if (window._kausapAudioCtx) { window._kausapAudioCtx.suspend(); }']);
      } catch (_) {}
    }
  }

  void resume() {
    if (_currentSound != AmbientSoundType.silence) {
      _isPlaying = true;
      if (kIsWeb) {
        try {
          js.context.callMethod('eval', ['if (window._kausapAudioCtx) { window._kausapAudioCtx.resume(); } else { window._startKausapAmbient("${_soundName(_currentSound)}", $_volume); }']);
        } catch (_) {
          _startWebAudioSynthesizer(_currentSound);
        }
      }
    }
  }

  void stop() {
    _isPlaying = false;
    _synthTimer?.cancel();
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['if (window._kausapGain) { window._kausapGain.gain.setValueAtTime(0, window._kausapAudioCtx.currentTime); } if (window._kausapAudioCtx) { window._kausapAudioCtx.close(); window._kausapAudioCtx = null; }']);
      } catch (_) {}
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

  String _soundName(AmbientSoundType type) {
    switch (type) {
      case AmbientSoundType.rain:
        return 'rain';
      case AmbientSoundType.ocean:
        return 'ocean';
      case AmbientSoundType.forest:
        return 'forest';
      case AmbientSoundType.singingBowl:
        return 'bowl';
      case AmbientSoundType.silence:
        return 'silence';
    }
  }

  void _startWebAudioSynthesizer(AmbientSoundType sound) {
    final type = _soundName(sound);
    final jsCode = '''
    (function() {
      try {
        if (window._kausapAudioCtx) {
          try { window._kausapAudioCtx.close(); } catch(e){}
        }
        var AudioCtx = window.AudioContext || window.webkitAudioContext;
        var ctx = new AudioCtx();
        window._kausapAudioCtx = ctx;
        var masterGain = ctx.createGain();
        masterGain.gain.setValueAtTime($_volume * 0.3, ctx.currentTime);
        masterGain.connect(ctx.destination);
        window._kausapGain = masterGain;

        if ("$type" === "rain") {
          // Pink/White noise rain generator
          var bufferSize = ctx.sampleRate * 2;
          var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          var output = noiseBuffer.getChannelData(0);
          var b0 = 0, b1 = 0, b2 = 0;
          for (var i = 0; i < bufferSize; i++) {
            var white = Math.random() * 2 - 1;
            b0 = 0.99886 * b0 + white * 0.0555179;
            b1 = 0.99332 * b1 + white * 0.0750759;
            b2 = 0.96900 * b2 + white * 0.1538520;
            output[i] = (b0 + b1 + b2 + white * 0.5362) * 0.1;
          }
          var whiteNoise = ctx.createBufferSource();
          whiteNoise.buffer = noiseBuffer;
          whiteNoise.loop = true;

          var filter = ctx.createBiquadFilter();
          filter.type = 'lowpass';
          filter.frequency.setValueAtTime(850, ctx.currentTime);

          whiteNoise.connect(filter);
          filter.connect(masterGain);
          whiteNoise.start();
        } else if ("$type" === "ocean") {
          // Modulated ocean swell filter
          var bufferSize = ctx.sampleRate * 3;
          var noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          var output = noiseBuffer.getChannelData(0);
          for (var i = 0; i < bufferSize; i++) {
            output[i] = (Math.random() * 2 - 1) * 0.15;
          }
          var oceanNoise = ctx.createBufferSource();
          oceanNoise.buffer = noiseBuffer;
          oceanNoise.loop = true;

          var filter = ctx.createBiquadFilter();
          filter.type = 'bandpass';
          filter.frequency.setValueAtTime(320, ctx.currentTime);
          filter.Q.setValueAtTime(2.0, ctx.currentTime);

          // LFO for wave swells
          var lfo = ctx.createOscillator();
          lfo.frequency.setValueAtTime(0.12, ctx.currentTime);
          var lfoGain = ctx.createGain();
          lfoGain.gain.setValueAtTime(180, ctx.currentTime);
          lfo.connect(lfoGain);
          lfoGain.connect(filter.frequency);
          lfo.start();

          oceanNoise.connect(filter);
          filter.connect(masterGain);
          oceanNoise.start();
        } else if ("$type" === "bowl") {
          // Resonant harmonic singing bowl
          var freqs = [432, 864, 1296];
          freqs.forEach(function(f, idx) {
            var osc = ctx.createOscillator();
            var g = ctx.createGain();
            osc.type = 'sine';
            osc.frequency.setValueAtTime(f, ctx.currentTime);
            g.gain.setValueAtTime(0.15 / (idx + 1), ctx.currentTime);
            osc.connect(g);
            g.connect(masterGain);
            osc.start();
          });
        } else if ("$type" === "forest") {
          // Forest wind with gentle soft tone
          var osc = ctx.createOscillator();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(528, ctx.currentTime);
          var g = ctx.createGain();
          g.gain.setValueAtTime(0.04, ctx.currentTime);
          osc.connect(g);
          g.connect(masterGain);
          osc.start();
        }
      } catch(e) {}
    })();
    ''';
    try {
      js.context.callMethod('eval', [jsCode]);
    } catch (_) {}
  }
}
