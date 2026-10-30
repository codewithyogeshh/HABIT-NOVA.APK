import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing user selected app language in HabitNova.
/// Supports English, Marathi (मराठी), and Hindi (हिंदी).
/// Enforces a single clean language display without mixed parentheses labels.
class LanguageService {
  static const String _prefKeyLanguage = 'habitnova_selected_language_code_v1';

  static const String english = 'en';
  static const String marathi = 'mr';
  static const String hindi = 'hi';

  static final ValueNotifier<String> currentLanguageNotifier = ValueNotifier<String>(english);

  static String get currentLanguageCode => currentLanguageNotifier.value;

  static String get currentLanguageName {
    switch (currentLanguageNotifier.value) {
      case marathi:
        return 'मराठी';
      case hindi:
        return 'हिंदी';
      default:
        return 'English';
    }
  }

  static const Map<String, String> languageDisplayNames = {
    english: 'English',
    marathi: 'मराठी',
    hindi: 'हिंदी',
  };

  /// Initialize stored language preference
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyLanguage);
      if (saved != null && (saved == english || saved == marathi || saved == hindi)) {
        currentLanguageNotifier.value = saved;
      }
    } catch (e) {
      debugPrint('LanguageService.init error: $e');
    }
  }

  /// Change language and persist preference
  static Future<void> setLanguage(String code) async {
    if (code != english && code != marathi && code != hindi) return;
    try {
      currentLanguageNotifier.value = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, code);
    } catch (e) {
      debugPrint('LanguageService.setLanguage error: $e');
    }
  }

  /// Translation strings dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'gender': 'Gender',
      'gender_subtitle': 'Select your avatar gender preference',
      'select_gender': 'Select Your Gender',
      'select_gender_subtitle': 'Choose male or female 3D avatar collection',
      'male': 'Male',
      'female': 'Female',
      'male_avatars': '3D Male Avatars',
      'female_avatars': '3D Female Avatars',
      'gender_set_male': 'Gender set to Male 👨! Choose your 3D avatar.',
      'gender_set_female': 'Gender set to Female 👩! Choose your 3D avatar.',
      'app_language': 'App Language',
      'app_language_subtitle': 'Choose your preferred language for HabitNova',
      'choose_language': 'Choose App Language',
      'log_out': 'Log Out',
      'log_out_confirm_title': 'Log Out',
      'log_out_confirm_msg': 'Are you sure you want to log out of HabitNova?',
      'cancel': 'Cancel',
      'settings': 'Settings',
      'profile_settings': 'Profile & Settings',
      'exit_dialog_title': 'Exit HabitNova?',
      'exit_dialog_msg': 'Are you sure you want to exit? Keep your daily habits and focus streak going!',
      'exit_btn_stay': 'Stay',
      'exit_btn_exit': 'Yes, Exit',
      'quick_settings': 'Quick Settings',
      'appearance': 'Appearance',
      'notification_settings': 'Notification Settings',
      'home_widget': 'Home Screen Widget',
      'selected': 'Selected',
    },
    'mr': {
      'gender': 'लिंग',
      'gender_subtitle': 'तुमच्या आवडीनुसार अवतार लिंग निवडा',
      'select_gender': 'लिंग निवडा',
      'select_gender_subtitle': 'पुरुष किंवा स्त्री ३डी अवतार निवडा',
      'male': 'पुरुष',
      'female': 'स्त्री',
      'male_avatars': '३डी पुरुष अवतार',
      'female_avatars': '३डी स्त्री अवतार',
      'gender_set_male': 'लिंग पुरुष 👨 सेट केले! तुमचा ३डी अवतार निवडा.',
      'gender_set_female': 'लिंग स्त्री 👩 सेट केले! तुमचा ३डी अवतार निवडा.',
      'app_language': 'ॲपची भाषा',
      'app_language_subtitle': 'HabitNova साठी तुमची पसंतीची भाषा निवडा',
      'choose_language': 'ॲपची भाषा निवडा',
      'log_out': 'लॉग आउट',
      'log_out_confirm_title': 'लॉग आउट करा',
      'log_out_confirm_msg': 'तुम्हाला खात्री आहे का HabitNova मधून लॉग आउट करायचे आहे?',
      'cancel': 'रद्द करा',
      'settings': 'सेटिंग्ज',
      'profile_settings': 'प्रोफाईल आणि सेटिंग्ज',
      'exit_dialog_title': 'HabitNova मधून बाहेर पडायचे आहे का?',
      'exit_dialog_msg': 'तुम्हाला खरोखर ॲप बंद करायचे आहे का? तुमची डेली स्ट्रिक जिवंत ठेवण्यासाठी सुरू ठेवा!',
      'exit_btn_stay': 'नाही (ॲपमध्ये राहा)',
      'exit_btn_exit': 'होय, बाहेर पडा',
      'quick_settings': 'क्विक सेटिंग्ज',
      'appearance': 'थीम व डिस्प्ले',
      'notification_settings': 'नोटिफिकेशन सेटिंग्ज',
      'home_widget': 'होम स्क्रीन विजेट',
      'selected': 'निवडले',
    },
    'hi': {
      'gender': 'लिंग',
      'gender_subtitle': 'अपनी पसंद के अनुसार अवतार लिंग चुनें',
      'select_gender': 'लिंग चुनें',
      'select_gender_subtitle': 'पुरुष या महिला 3D अवतार चुनें',
      'male': 'पुरुष',
      'female': 'महिला',
      'male_avatars': '3D पुरुष अवतार',
      'female_avatars': '3D महिला अवतार',
      'gender_set_male': 'लिंग पुरुष 👨 सेट किया गया! अपना 3D अवतार चुनें।',
      'gender_set_female': 'लिंग महिला 👩 सेट किया गया! अपना 3D अवतार चुनें।',
      'app_language': 'ऐप की भाषा',
      'app_language_subtitle': 'HabitNova के लिए अपनी पसंदीदा भाषा चुनें',
      'choose_language': 'ऐप की भाषा चुनें',
      'log_out': 'लॉग आउट',
      'log_out_confirm_title': 'लॉग आउट करें',
      'log_out_confirm_msg': 'क्या आप वाकई HabitNova से लॉग आउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'settings': 'सेटिंग्स',
      'profile_settings': 'प्रोफाइल और सेटिंग्स',
      'exit_dialog_title': 'HabitNova से बाहर निकलना चाहते हैं?',
      'exit_dialog_msg': 'क्या आप वाकई ऐप बंद करना चाहते हैं? अपनी स्ट्रीक बनाए रखने के लिए अभ्यास जारी रखें!',
      'exit_btn_stay': 'नहीं (बने रहें)',
      'exit_btn_exit': 'हाँ, बाहर निकलें',
      'quick_settings': 'त्वरित सेटिंग्स',
      'appearance': 'थीम और दिखावट',
      'notification_settings': 'सूचना सेटिंग्स',
      'home_widget': 'होम स्क्रीन विजेट',
      'selected': 'चुना गया',
    },
  };

  /// Translate a key into the currently active language
  static String tr(String key) {
    final lang = currentLanguageNotifier.value;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

