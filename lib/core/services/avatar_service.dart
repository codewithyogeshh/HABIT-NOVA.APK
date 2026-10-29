import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Service to manage, persist, and isolate user profile avatars and gender
/// strictly per user account across HabbitNova.
class AvatarService {
  static const String defaultMaleAvatar = 'assets/images/avatar_m1.png';
  static const String defaultFemaleAvatar = 'assets/images/avatar_f1.png';

  static String? _activeUserId;

  /// ValueNotifier holding the current avatar path (asset, file, or network URL).
  static final ValueNotifier<String> currentAvatarNotifier =
      ValueNotifier<String>(defaultMaleAvatar);

  /// ValueNotifier holding the current user's gender ('male' or 'female').
  static final ValueNotifier<String> currentGenderNotifier =
      ValueNotifier<String>('male');

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

  static String _avatarKeyFor(String userId) => 'user_${userId}_avatar_path';
  static String _genderKeyFor(String userId) => 'user_${userId}_gender';

  /// Resolves the current user ID defensively
  static String get resolvedUserId {
    if (_activeUserId != null && _activeUserId!.isNotEmpty) {
      return _activeUserId!;
    }
    final sbUser = SupabaseService.user;
    if (sbUser != null && sbUser.id.isNotEmpty) {
      _activeUserId = sbUser.id;
      return sbUser.id;
    }
    return 'guest';
  }

  /// Initialize and load saved avatar from SharedPreferences for current user
  static Future<void> init() async {
    final sbUser = SupabaseService.user;
    if (sbUser != null) {
      await loadForUser(sbUser.id);
    } else {
      resetForLogout();
    }
  }

  /// Loads profile avatar & gender strictly scoped to a specific user.
  /// Prevents any data bleeding between different accounts.
  static Future<void> loadForUser(String userId) async {
    _activeUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load user gender
      final savedGender = prefs.getString(_genderKeyFor(userId)) ?? 'male';
      currentGenderNotifier.value = savedGender;

      // 2. Load user avatar
      final savedAvatar = prefs.getString(_avatarKeyFor(userId));

      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        // Validate local file if applicable
        if (!savedAvatar.startsWith('assets/') && !savedAvatar.startsWith('http')) {
          if (!File(savedAvatar).existsSync()) {
            currentAvatarNotifier.value =
                savedGender == 'female' ? defaultFemaleAvatar : defaultMaleAvatar;
            return;
          }
        }
        currentAvatarNotifier.value = savedAvatar;
      } else {
        // Default avatar matching the user's gender
        currentAvatarNotifier.value =
            savedGender == 'female' ? defaultFemaleAvatar : defaultMaleAvatar;
      }

      // 3. Background Cloud sync if Supabase is connected
      _syncFromCloud(userId);
    } catch (e) {
      debugPrint('AvatarService.loadForUser error: $e');
    }
  }

  /// Resets state when a user logs out so the next user never sees previous user's avatar
  static void resetForLogout() {
    _activeUserId = null;
    currentAvatarNotifier.value = defaultMaleAvatar;
    currentGenderNotifier.value = 'male';
  }

  /// Current avatar path getter
  static String get currentAvatar => currentAvatarNotifier.value;

  /// Current gender getter
  static String get currentGender => currentGenderNotifier.value;

  /// Check whether the current avatar is a preset asset
  static bool get isAssetAvatar => currentAvatar.startsWith('assets/');

  /// Sets user gender ('male' or 'female') and optionally updates default avatar
  static Future<void> setGender(String gender, {String? userId}) async {
    final targetId = userId ?? resolvedUserId;
    currentGenderNotifier.value = gender;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_genderKeyFor(targetId), gender);

      // If current avatar is still one of the defaults, automatically update to gender match
      final cur = currentAvatarNotifier.value;
      if (cur == defaultMaleAvatar || cur == defaultFemaleAvatar) {
        final newDefault = gender == 'female' ? defaultFemaleAvatar : defaultMaleAvatar;
        await setAvatar(newDefault, userId: targetId);
      }

      // Sync to cloud in background
      _syncGenderToCloud(targetId, gender);
    } catch (e) {
      debugPrint('AvatarService.setGender error: $e');
    }
  }

  /// Set and persist avatar strictly scoped to this user
  static Future<void> setAvatar(String path, {String? userId}) async {
    final targetId = userId ?? resolvedUserId;
    currentAvatarNotifier.value = path;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKeyFor(targetId), path);

      // Background cloud sync
      _syncAvatarToCloud(targetId, path);
    } catch (e) {
      debugPrint('AvatarService.setAvatar error: $e');
    }
  }

  /// Pick custom image from gallery and persist
  static Future<bool> pickFromGallery({String? userId}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (pickedFile != null) {
        await setAvatar(pickedFile.path, userId: userId);
        return true;
      }
    } catch (e) {
      debugPrint('AvatarService.pickFromGallery error: $e');
    }
    return false;
  }

  /// Take custom photo using camera and persist
  static Future<bool> pickFromCamera({String? userId}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (pickedFile != null) {
        await setAvatar(pickedFile.path, userId: userId);
        return true;
      }
    } catch (e) {
      debugPrint('AvatarService.pickFromCamera error: $e');
    }
    return false;
  }

  // --- Background Cloud Helpers ---
  static Future<void> _syncFromCloud(String userId) async {
    try {
      final profile = await SupabaseService.getProfile(userId: userId);
      final cloudAvatar = profile['avatar_url'] as String?;
      final cloudGender = profile['gender'] as String?;

      if (cloudGender != null && cloudGender.isNotEmpty) {
        currentGenderNotifier.value = cloudGender;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_genderKeyFor(userId), cloudGender);
      }

      if (cloudAvatar != null && cloudAvatar.isNotEmpty) {
        currentAvatarNotifier.value = cloudAvatar;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_avatarKeyFor(userId), cloudAvatar);
      }
    } catch (_) {
      // Offline or column not yet added, safe to ignore
    }
  }

  static Future<void> _syncAvatarToCloud(String userId, String path) async {
    try {
      await SupabaseService.updateProfile(
        userId: userId,
        updates: {'avatar_url': path},
      );
    } catch (_) {}
  }

  static Future<void> _syncGenderToCloud(String userId, String gender) async {
    try {
      await SupabaseService.updateProfile(
        userId: userId,
        updates: {'gender': gender},
      );
    } catch (_) {}
  }
}
