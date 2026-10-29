import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

/// Service to manage, persist, and notify profile avatar changes across HabbitNova.
class AvatarService {
  static const String _avatarKey = 'habbit_nova_user_avatar';
  static const String defaultMaleAvatar = 'assets/images/avatar_m1.png';
  static const String defaultFemaleAvatar = 'assets/images/avatar_f1.png';

  /// ValueNotifier holding the current avatar path (asset, file, or network URL).
  static final ValueNotifier<String> currentAvatarNotifier =
      ValueNotifier<String>(defaultMaleAvatar);

  static final ImagePicker _imagePicker = ImagePicker();

  /// Preset Male 3D avatars
  static const List<Map<String, String>> maleAvatars = [
    {
      'id': 'male_1',
      'name': 'Tech Creative',
      'path': 'assets/images/avatar_m1.png',
      'tag': 'Popular ⚡',
    },
    {
      'id': 'male_2',
      'name': 'Athletic Sport',
      'path': 'assets/images/avatar_m2.png',
      'tag': 'Active 🏃',
    },
    {
      'id': 'male_3',
      'name': 'Modern Stylish',
      'path': 'assets/images/avatar_m3.png',
      'tag': 'Sharp ✨',
    },
  ];

  /// Preset Female 3D avatars
  static const List<Map<String, String>> femaleAvatars = [
    {
      'id': 'female_1',
      'name': 'Creative Smart',
      'path': 'assets/images/avatar_f1.png',
      'tag': 'Popular 🌸',
    },
    {
      'id': 'female_2',
      'name': 'Active Sporty',
      'path': 'assets/images/avatar_f2.png',
      'tag': 'Energetic 🏃‍♀️',
    },
    {
      'id': 'female_3',
      'name': 'Gentle Mindful',
      'path': 'assets/images/avatar_f3.png',
      'tag': 'Calm 🧘‍♀️',
    },
  ];

  /// Initialize and load saved avatar from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAvatar = prefs.getString(_avatarKey);
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        // If it was a local file, verify it still exists
        if (!savedAvatar.startsWith('assets/') &&
            !savedAvatar.startsWith('http')) {
          if (!File(savedAvatar).existsSync()) {
            currentAvatarNotifier.value = defaultMaleAvatar;
            return;
          }
        }
        currentAvatarNotifier.value = savedAvatar;
      }
    } catch (e) {
      debugPrint('AvatarService.init error: $e');
    }
  }

  /// Current avatar path getter
  static String get currentAvatar => currentAvatarNotifier.value;

  /// Check whether the current avatar is a preset asset
  static bool get isAssetAvatar => currentAvatar.startsWith('assets/');

  /// Set and persist avatar
  static Future<void> setAvatar(String path) async {
    currentAvatarNotifier.value = path;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKey, path);
    } catch (e) {
      debugPrint('AvatarService.setAvatar error: $e');
    }
  }

  /// Pick custom image from gallery and persist
  static Future<bool> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (pickedFile != null) {
        await setAvatar(pickedFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('AvatarService.pickFromGallery error: $e');
    }
    return false;
  }

  /// Take custom photo using camera and persist
  static Future<bool> pickFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (pickedFile != null) {
        await setAvatar(pickedFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('AvatarService.pickFromCamera error: $e');
    }
    return false;
  }
}

