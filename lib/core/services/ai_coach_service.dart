import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CoachPersonality {
  savageRoast,
  toughLove,
  zenMaster,
}

class AiCoachService {
  static const String _kPersonalityKey = 'habit_nova_coach_personality';
  static const String _kNotificationsEnabledKey = 'habit_nova_savage_notifs_enabled';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Gets the currently selected personality
  static Future<CoachPersonality> getPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_kPersonalityKey);
    if (val == 'toughLove') return CoachPersonality.toughLove;
    if (val == 'zenMaster') return CoachPersonality.zenMaster;
    return CoachPersonality.savageRoast; // default is Savage Roast!
  }

  /// Sets the coach personality
  static Future<void> setPersonality(CoachPersonality personality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPersonalityKey, personality.name);
  }

  /// Whether savage notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabledKey, enabled);
    if (enabled) {
      await scheduleDailyRoasts();
    } else {
      await cancelDailyRoasts();
    }
  }

  /// Generates a live, context-aware witty roast or praise based on user metrics
  static String generateRoast({
    required CoachPersonality personality,
    required int streakDays,
    required int studyMinutes,
    required int screenTimeMinutes,
    required int habitsDone,
    required int habitsTotal,
  }) {
    final random = Random();

    // 1. High screen time & Low study time
    if (screenTimeMinutes > 90 && studyMinutes < 30) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '📱 इंस्टाग्रामवर रिल्स बघून कलेक्टर होणार का? $screenTimeMinutes मिनिटे फोनवर वाया गेले आणि अभ्यास फक्त $studyMinutes मिनिटे! चल लगेच फोन खाली ठेव!',
          '🤡 रील बघून मस्त हसायला येतंय ना? पण परीक्षेच्या दिवशी रडायला नको असेल तर आताच अभ्यासाचा टाइमर सुरू कर!',
          '💀 फोनची बॅटरी १०% आणि तुझा आजचा अभ्यास ०%? आळसाचा वर्ल्ड रेकॉर्ड करायचा विचार आहे का?!',
          '🚨 $screenTimeMinutes मिनिटे स्क्रीन स्क्रोलिंग?! फोनचे गुलाम बनू नकोस, स्वतःचे भविष्य घडवायला घे!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'वेळ ही सर्वात अमूल्य संपत्ती आहे. $screenTimeMinutes मिनिटे वाया गेली आहेत. आताच अभ्यासाला बसा, कारण कारणे देणाऱ्यांना यश मिळत नाही!';
      } else {
        return 'मन चंचल आहे, ते मोहात पडते. एक दीर्घ श्वास घ्या आणि आपल्या ध्येयाकडे पुन्हा वळा. आत्ताचा क्षण हीच नवी सुरुवात आहे.';
      }
    }

    // 2. Evening and habits not done yet (Streak in danger!)
    if (habitsDone < habitsTotal && streakDays >= 3) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '🔥 तुझा $streakDays दिवसांचा स्ट्रिक आज रात्री १२ वाजता जळून खाक होणार आहे! उद्या मित्रांना तोंड काय दाखवणार?! उठा आणि हॅबिट टिक करा!',
          '👀 $streakDays दिवस कष्ट केले आणि आज एका आळसामुळे सर्व गमावणार? स्वतःवर दया करू नकोस, उठ!',
          '⚡ अजून ${habitsTotal - habitsDone} सवयी बाकी आहेत! झोपायच्या आधी त्या पूर्ण झाल्या पाहिजेत, नाहीतर स्ट्रिक ० वर येईल!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return '$streakDays दिवसांचे सातत्य तोडू नकोस. उर्वरित ${habitsTotal - habitsDone} सवयी पूर्ण केल्याशिवाय आज झोपायचे नाही!';
      } else {
        return 'नियमितता हीच यशाची किल्ली आहे. $streakDays दिवसांचा तुमचा प्रवास सुंदर आहे, आजचा टप्पा पूर्ण करून तो पुढे न्या.';
      }
    }

    // 3. User crushed all habits!
    if (habitsDone >= habitsTotal && habitsTotal > 0) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '👑 अरे वा! सर्व हॅबिट्स पूर्ण?! आज तू खरा वाघ/वाघीण आहेस! पण उद्या पुन्हा आळस केला तर गाठ माझ्याशी आहे!',
          '🔥 १००% गोल्स पूर्ण! आज तुला सुट्टी, पण उद्याचा स्ट्रिक तुटता कामा नये!',
          '🚀 आजचा दिवस जिंकलास बॉस! आता असाच फोकस टिकवला तर तुला कोणीही रोखू शकत नाही!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'उत्कृष्ट कामगिरी! शिस्त आणि सातत्याचा हाच मार्ग यशाकडे नेतो. उद्याही असाच पराक्रम हवा आहे.';
      } else {
        return 'शाबास! आज तुम्ही स्वतःवर विजय मिळवला आहे. मन शांत ठेवा आणि या समाधानाचा आनंद घ्या.';
      }
    }

    // 4. General / Mid-day
    if (personality == CoachPersonality.savageRoast) {
      final quotes = [
        '💡 "उद्यापासून सुरू करतो" ही जगातील सर्वात मोठी फसवणूक आहे. जे करायचं ते आत्ताच कर!',
        '🎯 तू स्वप्ने मोठी बघतोस, मग कष्ट लहान का? आजचा किमान १ तास डीप फोकस पूर्ण कर!',
        '💧 पाण्याची बाटली रिकामी झाली की अजून भरलेलीच आहे? आधी पाणी पी, मग मोठे प्लॅन्स बनव!',
      ];
      return quotes[random.nextInt(quotes.length)];
    } else if (personality == CoachPersonality.toughLove) {
      return 'कष्ट शांतपणे करा, तुमचे यश आपोआप आवाज करेल. आजचा वेळ सत्कारणी लावा!';
    } else {
      return 'लहान लहान सकारात्मक बदलच मोठा फरक घडवून आणतात. शांत चित्ताने पुढे चालत राहा.';
    }
  }

  /// Schedules daily savage reminder notifications
  static Future<void> scheduleDailyRoasts() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'savage_roast_channel',
        'AI Savage Habit Roasts',
        channelDescription: 'Humorous, savage, and tough love habit reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);

      // Schedule at 2:30 PM (Midday wake-up call)
      await _notificationsPlugin.show(
        881,
        '🚨 Habit-Nova Alert: Instagram जिंकलं, तू हरलास?!',
        'दुपारचे २:३० झालेत आणि अभ्यास अजून शून्य?! रिल्स बंद कर आणि फोकस मोड चालू कर!',
        details,
      );

      // Schedule at 8:30 PM (Evening streak savior)
      await _notificationsPlugin.show(
        882,
        '🔥 Streak Alert: आज रात्री १२ वाजता गेम ओव्हर?!',
        'तुझा हॅबिट स्ट्रिक धोक्यात आहे! झोपण्यापूर्वी बाकी राहिलेले हॅबिट्स पूर्ण कर!',
        details,
      );
    } catch (e) {
      debugPrint('scheduleDailyRoasts error: $e');
    }
  }

  static Future<void> cancelDailyRoasts() async {
    try {
      await _notificationsPlugin.cancel(881);
      await _notificationsPlugin.cancel(882);
    } catch (e) {
      debugPrint('cancelDailyRoasts error: $e');
    }
  }
}

