import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Focus sound item model
class FocusSoundOption {
  final String id;
  final String name;
  final String iconEmoji;
  final String subtitle;

  const FocusSoundOption({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.subtitle,
  });
}

/// Service managing authentic real-world ambient focus sounds for the Study Timer.
class FocusSoundService {
  static const MethodChannel _channel = MethodChannel('com.example.synvero/focus_sounds');

  static final ValueNotifier<String?> currentSoundIdNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<double> volumeNotifier = ValueNotifier<double>(0.8);

  static const List<FocusSoundOption> options = [
    FocusSoundOption(
      id: 'rain',
      name: 'Real Rain',
      iconEmoji: '🌧️',
      subtitle: 'खरा पाऊस • Rain on window glass',
    ),
    FocusSoundOption(
      id: 'ocean',
      name: 'Ocean Waves',
      iconEmoji: '🌊',
      subtitle: 'समुद्राच्या लाटा • Deep ocean surf',
    ),
    FocusSoundOption(
      id: 'forest',
      name: 'Forest Birds',
      iconEmoji: '🌲',
      subtitle: 'निसर्गातील पक्षी • Birds in green trees',
    ),
    FocusSoundOption(
      id: 'cafe',
      name: 'Cozy Cafe',
      iconEmoji: '☕',
      subtitle: 'कॅफे व्हायब्स • Coffee shop atmosphere',
    ),
    FocusSoundOption(
      id: 'campfire',
      name: 'Campfire',
      iconEmoji: '🔥',
      subtitle: 'शेकोटीचा आवाज • Warm crackling fire',
    ),
  ];

  /// Plays the selected ambient sound
  static Future<void> playSound(String soundId) async {
    currentSoundIdNotifier.value = soundId;
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('playFocusSound', {
        'type': soundId,
        'volume': volumeNotifier.value,
      });
    } catch (e) {
      debugPrint('FocusSoundService.playSound error: $e');
    }
  }

  /// Stops any currently playing ambient sound
  static Future<void> stopSound() async {
    currentSoundIdNotifier.value = null;
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopFocusSound');
    } catch (e) {
      debugPrint('FocusSoundService.stopSound error: $e');
    }
  }

  /// Updates volume level (0.0 to 1.0)
  static Future<void> setVolume(double vol) async {
    volumeNotifier.value = vol.clamp(0.0, 1.0);
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setFocusVolume', {
        'volume': volumeNotifier.value,
      });
    } catch (e) {
      debugPrint('FocusSoundService.setVolume error: $e');
    }
  }
}
