import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/ai_coach_service.dart';

/// Service managing user selected app language in HabitNova.
/// Supports English (default), Marathi (मराठी), and Hindi (हिंदी).
/// Enforces complete, consistent localization without mixed-language strings.
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

  /// Initialize stored language preference (Defaults to English)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyLanguage);
      if (saved != null && (saved == english || saved == marathi || saved == hindi)) {
        currentLanguageNotifier.value = saved;
      } else {
        currentLanguageNotifier.value = english;
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
      if (await AiCoachService.areNotificationsEnabled()) {
        await AiCoachService.scheduleDailyRoasts();
      }
    } catch (e) {
      debugPrint('LanguageService.setLanguage error: $e');
    }
  }

  /// Translation strings dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'nav_home': 'Home',
      'nav_habits': 'Habits',
      'nav_timer': 'Timer',
      'nav_tasks': 'Tasks',
      'nav_profile': 'Profile',

      // Dashboard
      'daily_motivation': 'DAILY MOTIVATION ✨',
      'today_progress': "Today's Progress",
      'habits_completed': 'Habits Completed',
      'study_time': 'Study Time',
      'active_tasks': 'Active Tasks',
      'day_streak': 'Day Streak',
      'quick_actions': 'Quick Actions',
      'squads': 'Squads ⚔️',
      'story_card': 'Story Card 📸',
      'ai_coach': 'AI Coach 🤖',
      'home_widget': 'Widget 📱',
      'today_habits': "Today's Habits",
      'lifestyle_wellness': 'Lifestyle & Wellness',
      'nutrition_plan': 'Nutrition Plan',
      'fitness_plan': 'Fitness Plan',
      'view_all': 'View All',
      'keep_going': "Keep going! You're doing great!",
      'mins': 'mins',

      // Feature Promo Cards
      'squad_card_title': 'Habit Squads & Battles',
      'squad_card_subtitle': 'Challenge friends, track live screen time & streaks!',
      'story_card_promo_title': 'Aesthetic Story Card',
      'story_card_promo_subtitle': '1-Tap Instagram/WhatsApp milestone story card',
      'ai_coach_promo_title': 'AI Savage Habit Coach',
      'ai_coach_promo_subtitle': 'Duolingo-style roasts & tough-love reminders',
      'widget_promo_title': 'Home Screen Widget',
      'widget_promo_subtitle': 'Interactive widget to tick habits right from your home screen',

      // Squads Screen
      'squads_title': 'Habit Squads',
      'squads_subtitle': 'Compete with real friends in live habit & study battles!',
      'create_squad_btn': 'Create Squad',
      'join_squad_btn': 'Join with Code',
      'enter_squad_code': 'Enter 6-digit squad code',
      'squad_name': 'Squad Name',
      'squad_category': 'Category',
      'squad_motto': 'Squad Motto',
      'category_study': 'Study & Exams',
      'category_coding': 'Coding Ninjas',
      'category_fitness': 'Fitness Gang',
      'category_general': 'General Focus',
      'invite_whatsapp': 'Invite on WhatsApp',
      'code_copied': 'Squad code copied to clipboard!',
      'battle_standings': 'Live Battle Standings',
      'mvp_tag': 'MVP 👑',
      'slacker_tag': 'SLACKER 🤡',
      'study_label': 'Study',
      'screen_label': 'Screen',
      'habits_label': 'Habits',
      'streak_label': 'Streak',
      'no_squads_title': 'No Squads Yet',
      'no_squads_desc': 'Create a squad or enter a friend\'s invite code to start competing in real time!',
      'squad_created_success': 'Squad created successfully! Share the code with friends.',
      'squad_join_success': 'Successfully joined squad! 🚀',
      'squad_not_found': 'Squad code not found. Please check the code and try again.',
      'already_joined': 'You are already a member of this squad.',
      'leave_squad': 'Leave Squad',
      'create_squad_sheet_title': '⚔️ Create New Squad',
      'create_squad_sheet_subtitle': 'Form a squad, invite friends, and hold each other accountable.',
      'join_squad_sheet_title': '🚀 Join a Squad',
      'join_squad_sheet_subtitle': 'Enter the 6-character squad code shared by your friend.',

      // Story Card
      'story_card_title': 'Share Story Card',
      'story_card_subtitle': 'Share your progress on Instagram or WhatsApp Status',
      'share_story': 'Share Card',
      'save_card': 'Save Card',
      'card_copied': 'Story card copied to clipboard!',
      'theme_cyber': 'Cyber Cyan',
      'theme_gold': 'Champion Gold',
      'theme_zen': 'Emerald Zen',
      'streak_milestone': 'DAY STREAK',
      'screen_time_cut': 'Screen Time Saved',
      'focus_time': 'Focus Time',
      'habits_done': 'Habits Crushed',
      'download_tag': 'Download Habit-Nova on Google Play',

      // AI Coach
      'ai_coach_title': 'AI Habit Coach',
      'ai_coach_subtitle': 'Contextual roasts and tough-love motivation',
      'coach_savage': 'Savage Roast 🔥',
      'coach_tough': 'Tough Love ⚡',
      'coach_zen': 'Zen Master 🧘',
      'savage_desc': 'Duolingo-style brutally funny roasts to kill procrastination',
      'tough_desc': 'Direct, disciplined, no-excuse motivation',
      'zen_desc': 'Mindful, calm, and inspiring daily reflections',
      'daily_notifications_title': 'Daily Habit Roasts',
      'daily_notifications_desc': 'Receive surprise notifications when you slack off',
      'generate_fresh_roast': 'Give Me Another Roast 🔄',
      'share_roast_whatsapp': 'Share Roast on WhatsApp',
      'coach_personality': 'Coach Personality',

      // Home Screen Widget
      'widget_sheet_title': 'Home Screen Widget 📱',
      'widget_sheet_subtitle': 'Check off habits and tasks without opening the app',
      'pin_widget_btn': 'Add Widget to Home Screen',
      'widget_pinned_success': 'Widget added to home screen!',
      'widget_feature_1': '✓ 1-Tap interactive checkboxes directly on home screen',
      'widget_feature_2': '✓ Live habit progress bar & daily task counters',
      'widget_feature_3': '✓ Streak counter & inspirational daily quote',

      // Profile & Settings
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
      'selected': 'Selected',
      'tasks': 'Tasks',
      'pending_tasks': 'Active Tasks',
      'completed_tasks': 'Completed Tasks',
      'family_nag_title': 'Family Coach Nag 📢',
      'family_praise_title': 'Family Pride & Love ❤️',
      'all_tasks_completed': 'All tasks cleared today!',
      'scold_btn': 'Scold me more! 😤',
      'work_btn': 'On it right now! 🚀',
    },
    'mr': {
      // Navigation
      'nav_home': 'मुख्यपृष्ठ',
      'nav_habits': 'सवयी',
      'nav_timer': 'टायमर',
      'nav_tasks': 'कार्ये',
      'nav_profile': 'प्रोफाईल',

      // Dashboard
      'daily_motivation': 'दैनिक प्रेरणा ✨',
      'today_progress': 'आजची प्रगती',
      'habits_completed': 'पूर्ण झालेल्या सवयी',
      'study_time': 'अभ्यास वेळ',
      'active_tasks': 'सक्रिय कामे',
      'day_streak': 'दिवसांची स्ट्रिक',
      'quick_actions': 'त्वरित कृती',
      'squads': 'स्क्वॉड ⚔️',
      'story_card': 'स्टोरी कार्ड 📸',
      'ai_coach': 'एआय कोच 🤖',
      'home_widget': 'विजेट 📱',
      'today_habits': 'आजच्या सवयी',
      'lifestyle_wellness': 'आरोग्य व दिनचर्या',
      'nutrition_plan': 'आहार योजना',
      'fitness_plan': 'व्यायाम योजना',
      'view_all': 'सर्व पहा',
      'keep_going': 'सुरू ठेवा! तुम्ही उत्तम करत आहात!',
      'mins': 'मिनिटे',

      // Feature Promo Cards
      'squad_card_title': 'हॅबिट स्क्वॉड व स्पर्धा',
      'squad_card_subtitle': 'मित्रांना आव्हान द्या, लाईव्ह स्क्रीन टाईम व स्ट्रिक ट्रॅक करा!',
      'story_card_promo_title': 'आकर्षक स्टोरी कार्ड',
      'story_card_promo_subtitle': '१-क्लिक इन्स्टाग्राम व व्हॉट्सॲप स्टेटस कार्ड',
      'ai_coach_promo_title': 'एआय सॅव्हेज हॅबिट कोच',
      'ai_coach_promo_subtitle': 'ड्युओलिंगो स्टाईल मजेदार टोमणे व शिस्तीचे रिमाइंडर्स',
      'widget_promo_title': 'होम स्क्रीन विजेट',
      'widget_promo_subtitle': 'ॲप न उघडता होम स्क्रीनवरून थेट सवयी टिक करा',

      // Squads Screen
      'squads_title': 'हॅबिट स्क्वॉड',
      'squads_subtitle': 'मित्रांसोबत लाईव्ह स्पर्धा करा आणि रोज सवयी पूर्ण करा!',
      'create_squad_btn': 'स्क्वॉड तयार करा',
      'join_squad_btn': 'कोडने जॉईन व्हा',
      'enter_squad_code': '६ अंकी स्क्वॉड कोड टाका',
      'squad_name': 'स्क्वॉडचे नाव',
      'squad_category': 'वर्गवारी',
      'squad_motto': 'स्क्वॉडचे ब्रीदवाक्य',
      'category_study': 'अभ्यास व परीक्षा',
      'category_coding': 'कोडिंग निन्जा',
      'category_fitness': 'फिटनेस गँग',
      'category_general': 'सर्वसाधारण ध्येय',
      'invite_whatsapp': 'व्हॉट्सॲपवर इनव्हाईट करा',
      'code_copied': 'स्क्वॉड कोड कॉपी केला!',
      'battle_standings': 'लाईव्ह बॅटल क्रमवारी',
      'mvp_tag': 'विजेता (MVP) 👑',
      'slacker_tag': 'आळशी (SLACKER) 🤡',
      'study_label': 'अभ्यास',
      'screen_label': 'स्क्रीन वेळ',
      'habits_label': 'सवयी',
      'streak_label': 'स्ट्रिक',
      'no_squads_title': 'अजून कोणताही स्क्वॉड नाही',
      'no_squads_desc': 'मित्रांसोबत स्पर्धा करण्यासाठी नवीन स्क्वॉड बनवा किंवा मित्राचा कोड टाकून जॉईन व्हा!',
      'squad_created_success': 'स्क्वॉड यशस्वीरीत्या तयार झाला! मित्रांना कोड पाठवा.',
      'squad_join_success': 'स्क्वॉडमध्ये यशस्वीरित्या सामील झालात! 🚀',
      'squad_not_found': 'हा स्क्वॉड कोड सापडला नाही. कृपया कोड तपासून पुन्हा प्रयत्न करा.',
      'already_joined': 'तुम्ही आधीच या स्क्वॉडचे सदस्य आहात.',
      'leave_squad': 'स्क्वॉडमधून बाहेर पडा',
      'create_squad_sheet_title': '⚔️ नवीन स्क्वॉड बनवा',
      'create_squad_sheet_subtitle': 'स्क्वॉड बनवा, मित्रांना जोडा आणि एकमेकांना शिस्तीत ठेवा.',
      'join_squad_sheet_title': '🚀 स्क्वॉड जॉईन करा',
      'join_squad_sheet_subtitle': 'मित्राने पाठवलेला ६ अक्षरी स्क्वॉड कोड येथे टाका.',

      // Story Card
      'story_card_title': 'स्टोरी कार्ड शेअर करा',
      'story_card_subtitle': 'तुमची प्रगती इन्स्टाग्राम किंवा व्हॉट्सॲप स्टेटसवर शेअर करा',
      'share_story': 'कार्ड शेअर करा',
      'save_card': 'कार्ड सेव्ह करा',
      'card_copied': 'स्टोरी कार्ड कॉपी केले!',
      'theme_cyber': 'सायबर सायन',
      'theme_gold': 'चॅम्पियन गोल्ड',
      'theme_zen': 'एमराल्ड झेन',
      'streak_milestone': 'दिवसांची स्ट्रिक',
      'screen_time_cut': 'वाचवलेला स्क्रीन वेळ',
      'focus_time': 'फोकस वेळ',
      'habits_done': 'सवयी पूर्ण',
      'download_tag': 'Google Play वर Habit-Nova डाउनलोड करा',

      // AI Coach
      'ai_coach_title': 'एआय हॅबिट कोच',
      'ai_coach_subtitle': 'मिश्किल टोमणे आणि शिस्तबद्ध प्रेरणा',
      'coach_savage': 'सॅव्हेज रोस्ट 🔥',
      'coach_tough': 'कडक शिस्त ⚡',
      'coach_zen': 'शांत मन 🧘',
      'savage_desc': 'आळस घालवण्यासाठी ड्युओलिंगो स्टाईल मजेदार टोमणे',
      'tough_desc': 'कोणतेही कारण न ऐकणारी थेट आणि कडक शिस्त',
      'zen_desc': 'शांत आणि प्रेरणादायी विचार',
      'daily_notifications_title': 'दैनिक हॅबिट नोटिफिकेशन्स',
      'daily_notifications_desc': 'फोन जास्त वापरल्यास मिश्किल रिमाइंडर्स मिळवा',
      'generate_fresh_roast': 'दुसरा टोमणा द्या 🔄',
      'share_roast_whatsapp': 'व्हॉट्सॲपवर शेअर करा',
      'coach_personality': 'कोचचा स्वभाव',

      // Home Screen Widget
      'widget_sheet_title': 'होम स्क्रीन विजेट 📱',
      'widget_sheet_subtitle': 'ॲप न उघडता होम स्क्रीनवरून थेट सवयी टिक करा',
      'pin_widget_btn': 'होम स्क्रीनवर विजेट जोडा',
      'widget_pinned_success': 'होम स्क्रीनवर विजेट जोडले!',
      'widget_feature_1': '✓ होम स्क्रीनवरून थेट १-टॅपमध्ये सवयी टिक करा',
      'widget_feature_2': '✓ लाईव्ह प्रोग्रेस बार आणि दैनिक कामांचे काउंटर्स',
      'widget_feature_3': '✓ स्ट्रिक काउंटर आणि रोजचे प्रेरणादायी सुविचार',

      // Profile & Settings
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
      'selected': 'निवडले',
      'tasks': 'कार्ये',
      'pending_tasks': 'बाकी असलेली कामे',
      'completed_tasks': 'पूर्ण झालेली कामे',
      'family_nag_title': 'घरातील प्रेमाचा दरारा 📢',
      'family_praise_title': 'घरातील कौतुक व प्रेम ❤️',
      'all_tasks_completed': 'सर्व कामे वेळेवर पूर्ण!',
      'scold_btn': 'मला अजून ओरडा! 😤',
      'work_btn': 'कामावर लागलो! 🚀',
    },
    'hi': {
      // Navigation
      'nav_home': 'होम',
      'nav_habits': 'आदतें',
      'nav_timer': 'टाइमर',
      'nav_tasks': 'कार्य',
      'nav_profile': 'प्रोफाइल',

      // Dashboard
      'daily_motivation': 'दैनिक प्रेरणा ✨',
      'today_progress': 'आज की प्रगति',
      'habits_completed': 'पूरी हुई आदतें',
      'study_time': 'अध्ययन समय',
      'active_tasks': 'सक्रिय कार्य',
      'day_streak': 'दिनों की स्ट्रीक',
      'quick_actions': 'त्वरित क्रियाएँ',
      'squads': 'स्क्वाड ⚔️',
      'story_card': 'स्टोरी कार्ड 📸',
      'ai_coach': 'एआई कोच 🤖',
      'home_widget': 'विजेट 📱',
      'today_habits': 'आज की आदतें',
      'lifestyle_wellness': 'जीवनशैली और स्वास्थ्य',
      'nutrition_plan': 'आहार योजना',
      'fitness_plan': 'व्यायाम योजना',
      'view_all': 'सभी देखें',
      'keep_going': 'जारी रखें! आप बहुत बढ़िया कर रहे हैं!',
      'mins': 'मिनट',

      // Feature Promo Cards
      'squad_card_title': 'हैबिट स्क्वाड और प्रतियोगिता',
      'squad_card_subtitle': 'दोस्तों को चुनौती दें, लाइव स्क्रीन टाइम और स्ट्रीक ट्रैक करें!',
      'story_card_promo_title': 'आकर्षक स्टोरी कार्ड',
      'story_card_promo_subtitle': '1-क्लिक इंस्टाग्राम और व्हाट्सएप स्टेटस कार्ड',
      'ai_coach_promo_title': 'एआई सैवेज हैबिट कोच',
      'ai_coach_promo_subtitle': 'डुओलिंगो स्टाइल मजेदार व्यंग्य और अनुशासन रिमाइंडर',
      'widget_promo_title': 'होम स्क्रीन विजेट',
      'widget_promo_subtitle': 'ऐप खोले बिना होम स्क्रीन से सीधे आदतें टिक करें',

      // Squads Screen
      'squads_title': 'हैबिट स्क्वाड',
      'squads_subtitle': 'दोस्तों के साथ लाइव प्रतिस्पर्धा करें और आदतें पूरी करें!',
      'create_squad_btn': 'स्क्वाड बनाएं',
      'join_squad_btn': 'कोड से जुड़ें',
      'enter_squad_code': '6 अंकों का स्क्वाड कोड दर्ज करें',
      'squad_name': 'स्क्वाड का नाम',
      'squad_category': 'श्रेणी',
      'squad_motto': 'स्क्वाड का ध्येय वाक्य',
      'category_study': 'अध्ययन और परीक्षा',
      'category_coding': 'कोडिंग निन्जा',
      'category_fitness': 'फिटनेस गैंग',
      'category_general': 'सामान्य लक्ष्य',
      'invite_whatsapp': 'व्हाट्सएप पर आमंत्रित करें',
      'code_copied': 'स्क्वाड कोड कॉपी किया गया!',
      'battle_standings': 'लाइव बैटल रैंकिंग',
      'mvp_tag': 'विजेता (MVP) 👑',
      'slacker_tag': 'आलसी (SLACKER) 🤡',
      'study_label': 'अध्ययन',
      'screen_label': 'स्क्रीन समय',
      'habits_label': 'आदतें',
      'streak_label': 'स्ट्रीक',
      'no_squads_title': 'अभी कोई स्क्वाड नहीं है',
      'no_squads_desc': 'दोस्तों के साथ मुकाबला करने के लिए नया स्क्वाड बनाएं या कोड दर्ज करें!',
      'squad_created_success': 'स्क्वाड सफलतापूर्वक बनाया गया! दोस्तों के साथ कोड साझा करें।',
      'squad_join_success': 'स्क्वाड में सफलतापूर्वक शामिल हुए! 🚀',
      'squad_not_found': 'यह स्क्वाड कोड नहीं मिला। कृपया कोड जांचें और पुनः प्रयास करें।',
      'already_joined': 'आप पहले से ही इस स्क्वाड के सदस्य हैं।',
      'leave_squad': 'स्क्वाड छोड़ें',
      'create_squad_sheet_title': '⚔️ नया स्क्वाड बनाएं',
      'create_squad_sheet_subtitle': 'स्क्वाड बनाएं, दोस्तों को जोड़ें और एक-दूसरे को अनुशासित रखें।',
      'join_squad_sheet_title': '🚀 स्क्वाड में शामिल हों',
      'join_squad_sheet_subtitle': 'दोस्त द्वारा भेजा गया 6 अक्षरों का कोड यहाँ दर्ज करें।',

      // Story Card
      'story_card_title': 'स्टोरी कार्ड साझा करें',
      'story_card_subtitle': 'अपनी प्रगति इंस्टाग्राम या व्हाट्सएप स्टेटस पर साझा करें',
      'share_story': 'कार्ड साझा करें',
      'save_card': 'कार्ड सहेजें',
      'card_copied': 'स्टोरी कार्ड कॉपी किया गया!',
      'theme_cyber': 'साइबर सियान',
      'theme_gold': 'चैंपियन गोल्ड',
      'theme_zen': 'एमराल्ड ज़ेन',
      'streak_milestone': 'दिनों की स्ट्रीक',
      'screen_time_cut': 'बचाया गया स्क्रीन समय',
      'focus_time': 'फोकस समय',
      'habits_done': 'आदतें पूरी',
      'download_tag': 'Google Play पर Habit-Nova डाउनलोड करें',

      // AI Coach
      'ai_coach_title': 'एआई हैबिट कोच',
      'ai_coach_subtitle': 'व्यंग्यात्मक और अनुशासित दैनिक प्रेरणा',
      'coach_savage': 'सैवेज रोस्ट 🔥',
      'coach_tough': 'कड़ा अनुशासन ⚡',
      'coach_zen': 'शांत मन 🧘',
      'savage_desc': 'आलस भगाने के लिए डुओलिंगो स्टाइल मजेदार व्यंग्य',
      'tough_desc': 'बिना किसी बहाने के सीधा और कठोर अनुशासन',
      'zen_desc': 'शांत और प्रेरणादायक विचार',
      'daily_notifications_title': 'दैनिक हैबिट सूचनाएं',
      'daily_notifications_desc': 'फोन ज्यादा चलाने पर मजेदार रिमाइंडर प्राप्त करें',
      'generate_fresh_roast': 'नया व्यंग्य दिखाएं 🔄',
      'share_roast_whatsapp': 'व्हाट्सएप पर साझा करें',
      'coach_personality': 'कोच का स्वभाव',

      // Home Screen Widget
      'widget_sheet_title': 'होम स्क्रीन विजेट 📱',
      'widget_sheet_subtitle': 'ऐप खोले बिना होम स्क्रीन से सीधे आदतें टिक करें',
      'pin_widget_btn': 'होम स्क्रीन पर विजेट जोड़ें',
      'widget_pinned_success': 'होम स्क्रीन पर विजेट जोड़ा गया!',
      'widget_feature_1': '✓ होम स्क्रीन से सीधे 1-टैप में आदतें टिक करें',
      'widget_feature_2': '✓ लाइव प्रोग्रेस बार और दैनिक कार्यों के काउंटर',
      'widget_feature_3': '✓ स्ट्रीक काउंटर और प्रेरक दैनिक विचार',

      // Profile & Settings
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
      'selected': 'चुना गया',
      'tasks': 'कार्य',
      'pending_tasks': 'अधूरे कार्य',
      'completed_tasks': 'पूरे किए गए कार्य',
      'family_nag_title': 'घरवालों का प्यार भरा गुस्सा 📢',
      'family_praise_title': 'घरवालों का प्यार और तारीफ ❤️',
      'all_tasks_completed': 'सभी कार्य पूरे किए गए!',
      'scold_btn': 'और डांटो मुझे! 😤',
      'work_btn': 'काम पर लगा! 🚀',
    },
  };

  /// Translate a key into the currently active language
  static String tr(String key) {
    final lang = currentLanguageNotifier.value;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}
