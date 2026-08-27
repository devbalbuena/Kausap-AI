import 'package:flutter/foundation.dart';
import 'notification_prefs_service.dart';

// Conditional import for web audio
import 'ambient_audio_web.dart' if (dart.library.io) 'ambient_audio_stub.dart' as platform_audio;

enum SoundscapeType {
  rain,
  ocean,
  forest,
  zen,
}

class SoundscapeInfo {
  final SoundscapeType type;
  final String title;
  final String emoji;
  final String description;

  const SoundscapeInfo({
    required this.type,
    required this.title,
    required this.emoji,
    required this.description,
  });
}

/// Singleton service managing soothing ambient soundscapes for relaxation & focus.
class AmbientAudioService {
  AmbientAudioService._();
  static final AmbientAudioService instance = AmbientAudioService._();

  static const List<SoundscapeInfo> availableSoundscapes = [
    SoundscapeInfo(
      type: SoundscapeType.rain,
      title: 'Gentle Rain',
      emoji: '🌧️',
      description: 'Soft, steady rainfall soothing racing thoughts',
    ),
    SoundscapeInfo(
      type: SoundscapeType.ocean,
      title: 'Ocean Waves',
      emoji: '🌊',
      description: 'Rhythmic, gentle waves rolling onto the shore',
    ),
    SoundscapeInfo(
      type: SoundscapeType.forest,
      title: 'Forest Breeze',
      emoji: '🍃',
      description: 'Calm leaves rustling in a peaceful wooded sanctuary',
    ),
    SoundscapeInfo(
      type: SoundscapeType.zen,
      title: 'Zen Meditation',
      emoji: '🧘',
      description: 'Warm harmonic frequency designed for deep calm',
    ),
  ];

  bool _isPlaying = false;
  SoundscapeType _currentType = SoundscapeType.rain;
  double _volume = 0.5;

  final List<VoidCallback> _listeners = [];

  bool get isPlaying => _isPlaying;
  SoundscapeType get currentType => _currentType;
  double get volume => _volume;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      stop();
    } else {
      play(_currentType);
    }
  }

  void play(SoundscapeType type) {
    _currentType = type;
    _isPlaying = true;
    platform_audio.playAmbientSound(type.name, _volume);
    _notify();
  }

  void stop() {
    _isPlaying = false;
    platform_audio.stopAmbientSound();
    _notify();
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (_isPlaying) {
      platform_audio.setAmbientVolume(_volume);
    }
    _notify();
  }

  void playChime(int phaseIndex) {
    platform_audio.playBreathingChime(phaseIndex);
  }

  void playNotificationChime() {
    platform_audio.playNotificationChime();
  }

  static Future<void> playNotificationChimeIfAllowed() async {
    try {
      final pushEnabled = await NotificationPrefsService.getPushEnabled();
      if (!pushEnabled) return;

      final quietHours = await NotificationPrefsService.getQuietHoursEnabled();
      if (quietHours) {
        final now = DateTime.now();
        final startStr = await NotificationPrefsService.getQuietHoursStart();
        final endStr = await NotificationPrefsService.getQuietHoursEnd();

        final startParts = startStr.split(':');
        final endParts = endStr.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startMin = (int.tryParse(startParts[0]) ?? 22) * 60 + (int.tryParse(startParts[1]) ?? 0);
          final endMin = (int.tryParse(endParts[0]) ?? 7) * 60 + (int.tryParse(endParts[1]) ?? 0);
          final currentMin = now.hour * 60 + now.minute;

          bool inQuiet = false;
          if (startMin > endMin) {
            inQuiet = currentMin >= startMin || currentMin < endMin;
          } else {
            inQuiet = currentMin >= startMin && currentMin < endMin;
          }
          if (inQuiet) return; // Muted during quiet hours!
        }
      }

      platform_audio.playNotificationChime();
    } catch (_) {}
  }
}

