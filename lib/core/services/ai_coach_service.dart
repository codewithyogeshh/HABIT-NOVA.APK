import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/language_service.dart';

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

  /// Generates a live, context-aware roast or praise in the user's active language
  static String generateRoast({
    required CoachPersonality personality,
    required int streakDays,
    required int studyMinutes,
    required int screenTimeMinutes,
    required int habitsDone,
    required int habitsTotal,
  }) {
    final random = Random();
    final lang = LanguageService.currentLanguageCode;

    if (lang == LanguageService.marathi) {
      return _generateMarathiRoast(
        personality: personality,
        streakDays: streakDays,
        studyMinutes: studyMinutes,
        screenTimeMinutes: screenTimeMinutes,
        habitsDone: habitsDone,
        habitsTotal: habitsTotal,
        random: random,
      );
    } else if (lang == LanguageService.hindi) {
      return _generateHindiRoast(
        personality: personality,
        streakDays: streakDays,
        studyMinutes: studyMinutes,
        screenTimeMinutes: screenTimeMinutes,
        habitsDone: habitsDone,
        habitsTotal: habitsTotal,
        random: random,
      );
    } else {
      return _generateEnglishRoast(
        personality: personality,
        streakDays: streakDays,
        studyMinutes: studyMinutes,
        screenTimeMinutes: screenTimeMinutes,
        habitsDone: habitsDone,
        habitsTotal: habitsTotal,
        random: random,
      );
    }
  }

  static String _generateEnglishRoast({
    required CoachPersonality personality,
    required int streakDays,
    required int studyMinutes,
    required int screenTimeMinutes,
    required int habitsDone,
    required int habitsTotal,
    required Random random,
  }) {
    // 1. High screen time & Low study time
    if (screenTimeMinutes > 90 && studyMinutes < 30) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '📱 Scrolling Reels for $screenTimeMinutes mins won\'t pay your bills! Only $studyMinutes mins studied today?! Put the phone down right now!',
          '🤡 Laughing at memes all day? If you don\'t want to cry on exam day, turn on your study timer immediately!',
          '💀 Phone battery at 10% and your study progress at 0%? Are you aiming for a world record in slacking?!',
          '🚨 $screenTimeMinutes minutes glued to your screen?! Don\'t be a slave to your phone, build your future!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'Time is your most valuable asset. $screenTimeMinutes minutes have been wasted. Sit down and get to work right now!';
      } else {
        return 'The mind is easily distracted. Take a slow, deep breath and gently return your attention to your goals.';
      }
    }

    // 2. Habits remaining & streak in danger
    if (habitsDone < habitsTotal && streakDays >= 3) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '🔥 Your $streakDays-day streak is going to burn to ashes at midnight! What will your squad think?! Get up and finish your habits!',
          '👀 You worked hard for $streakDays days and now you\'ll ruin it with one lazy evening? Show some grit!',
          '⚡ You still have ${habitsTotal - habitsDone} habits left! Don\'t sleep until they are checked off, or your streak goes back to 0!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'Do not break your $streakDays-day momentum. Finish your remaining ${habitsTotal - habitsDone} habits before calling it a day!';
      } else {
        return 'Consistency is the true bridge between goals and accomplishment. Honor your $streakDays-day journey today.';
      }
    }

    // 3. User crushed all habits
    if (habitsDone >= habitsTotal && habitsTotal > 0) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '👑 All habits cleared?! Look at you being a champion today! But don\'t you dare get complacent tomorrow!',
          '🔥 100% goals conquered! You get a pass tonight, but tomorrow the battle starts all over again!',
          '🚀 You owned today, boss! Maintain this laser focus and nothing can stop you!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'Outstanding execution today! Discipline and daily consistency are the keys to mastery. Repeat tomorrow!';
      } else {
        return 'Well done. Today you conquered yourself. Rest in deep peace knowing you gave your absolute best.';
      }
    }

    // 4. General / Midday
    if (personality == CoachPersonality.savageRoast) {
      final quotes = [
        '💡 "I\'ll start tomorrow" is the biggest lie you tell yourself. The only day that matters is today!',
        '🎯 Big dreams require big effort. Go crush at least 45 minutes of deep focus right now!',
        '💧 Have you drank enough water today? Hydrate yourself first, then get back to conquering your goals!',
      ];
      return quotes[random.nextInt(quotes.length)];
    } else if (personality == CoachPersonality.toughLove) {
      return 'Work quietly in silence; let your undeniable success make all the noise. Make every hour count!';
    } else {
      return 'Small, conscious steps taken with purpose compound into remarkable achievements. Stay present.';
    }
  }

  static String _generateMarathiRoast({
    required CoachPersonality personality,
    required int streakDays,
    required int studyMinutes,
    required int screenTimeMinutes,
    required int habitsDone,
    required int habitsTotal,
    required Random random,
  }) {
    if (screenTimeMinutes > 90 && studyMinutes < 30) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '📱 इंस्टाग्रामवर रिल्स बघून कलेक्टर होणार का? $screenTimeMinutes मिनिटे फोनवर वाया गेले आणि अभ्यास फक्त $studyMinutes मिनिटे! चल लगेच फोन खाली ठेव!',
          '🤡 रील बघून मस्त हसायला येतंय ना? पण निकालाच्या दिवशी रडायला नको असेल तर आताच अभ्यासाचा टाइमर सुरू कर!',
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

    if (habitsDone < habitsTotal && streakDays >= 3) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '🔥 तुझा $streakDays दिवसांचा स्ट्रिक आज रात्री १२ वाजता जळून खाक होणार आहे! मित्रांना तोंड काय दाखवणार?! उठा आणि हॅबिट टिक करा!',
          '👀 $streakDays दिवस कष्ट केले आणि आज एका आळसामुळे सर्व गमावणार? स्वतःवर दया करू नकोस, उठ!',
          '⚡ अजून ${habitsTotal - habitsDone} सवयी बाकी आहेत! झोपायच्या आधी त्या पूर्ण झाल्या पाहिजेत, नाहीतर स्ट्रिक ० वर येईल!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return '$streakDays दिवसांचे सातत्य तोडू नकोस. उर्वरित ${habitsTotal - habitsDone} सवयी पूर्ण केल्याशिवाय आज झोपायचे नाही!';
      } else {
        return 'नियमितता हीच यशाची किल्ली आहे. $streakDays दिवसांचा प्रवास सुंदर आहे, आजचा टप्पा पूर्ण करून तो पुढे न्या.';
      }
    }

    if (habitsDone >= habitsTotal && habitsTotal > 0) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '👑 अरे वा! सर्व हॅबिट्स पूर्ण?! आज तू खरा वाघ आहेस! पण उद्या पुन्हा आळस केला तर गाठ माझ्याशी आहे!',
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

  static String _generateHindiRoast({
    required CoachPersonality personality,
    required int streakDays,
    required int studyMinutes,
    required int screenTimeMinutes,
    required int habitsDone,
    required int habitsTotal,
    required Random random,
  }) {
    if (screenTimeMinutes > 90 && studyMinutes < 30) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '📱 इंस्टाग्राम पर रील्स देखकर कलेक्टर बनोगे क्या? $screenTimeMinutes मिनट फोन पर बर्बाद और पढ़ाई सिर्फ $studyMinutes मिनट?! अभी फोन नीचे रखो!',
          '🤡 रील्स देखकर मजा आ रहा है ना? पर रिजल्ट के दिन रोना न पड़े, इसलिए अभी टाइमर चालू करो!',
          '💀 फोन की बैटरी 10% और पढ़ाई 0%? क्या आलस का वर्ल्ड रिकॉर्ड बनाने का इरादा है?!',
          '🚨 $screenTimeMinutes मिनट स्क्रीन स्क्रोलिंग?! फोन के गुलाम मत बनो, अपना भविष्य बनाओ!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'समय सबसे मूल्यवान संपत्ति है। $screenTimeMinutes मिनट बर्बाद हो चुके हैं। अभी पढ़ाई करने बैठिए!';
      } else {
        return 'मन चंचल है, वह भटकता है। एक गहरी सांस लें और पुनः अपने लक्ष्य की ओर ध्यान लगाएं।';
      }
    }

    if (habitsDone < habitsTotal && streakDays >= 3) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '🔥 आपकी $streakDays दिनों की स्ट्रीक आज रात 12 बजे खत्म होने वाली है! दोस्तों को क्या मुंह दिखाओगे?! उठो और आदतें टिक करो!',
          '👀 $streakDays दिन मेहनत की और आज एक आलस के कारण सब खो दोगे? खुद पर तरस मत खाओ, उठो!',
          '⚡ अभी भी ${habitsTotal - habitsDone} आदतें बाकी हैं! सोने से पहले वे पूरी होनी चाहिए, वरना स्ट्रीक 0 हो जाएगी!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return '$streakDays दिनों का सातत्य मत तोड़ो। बची हुई ${habitsTotal - habitsDone} आदतें पूरी किए बिना आज सोना नहीं है!';
      } else {
        return 'नियमितता ही सफलता की कुंजी है। $streakDays दिनों की यात्रा सुंदर है, आज का पड़ाव पूरा करें।';
      }
    }

    if (habitsDone >= habitsTotal && habitsTotal > 0) {
      if (personality == CoachPersonality.savageRoast) {
        final quotes = [
          '👑 अरे वाह! सभी आदतें पूरी?! आज आप असली चैंपियन हो! लेकिन कल आलस किया तो खैर नहीं!',
          '🔥 100% लक्ष्य हासिल! आज आपको छूट है, लेकिन कल की स्ट्रीक टूटने न पाए!',
          '🚀 आज का दिन जीत लिया बॉस! ऐसा ही फोकस बनाए रखोगे तो कोई नहीं रोक सकता!',
        ];
        return quotes[random.nextInt(quotes.length)];
      } else if (personality == CoachPersonality.toughLove) {
        return 'शानदार प्रदर्शन! अनुशासन और निरंतरता का यह मार्ग सफलता की ओर ले जाता है।';
      } else {
        return 'शाबाश! आज आपने स्वयं पर विजय प्राप्त की है। मन शांत रखें और इस संतुष्टि का आनंद लें।';
      }
    }

    if (personality == CoachPersonality.savageRoast) {
      final quotes = [
        '💡 "कल से शुरू करूंगा" दुनिया का सबसे बड़ा झूठ है। जो करना है, अभी करो!',
        '🎯 सपने बड़े देखते हो, तो मेहनत छोटी क्यों? आज कम से कम 45 मिनट डीप फोकस करो!',
        '💧 पानी की बोतल खाली हुई या अभी भी भरी है? पहले पानी पियो, फिर बड़े प्लान बनाओ!',
      ];
      return quotes[random.nextInt(quotes.length)];
    } else if (personality == CoachPersonality.toughLove) {
      return 'मेहनत इतनी खामोशी से करो कि तुम्हारी सफलता शोर मचा दे। समय का सदुपयोग करो!';
    } else {
      return 'छोटे-छोटे सकारात्मक बदलाव ही बड़ा अंतर पैदा करते हैं। शांत मन से आगे बढ़ते रहें।';
    }
  }

  /// Schedules daily savage reminder notifications in the user's active language
  static Future<void> scheduleDailyRoasts() async {
    try {
      final lang = LanguageService.currentLanguageCode;

      String middayTitle;
      String middayBody;
      String eveningTitle;
      String eveningBody;

      if (lang == LanguageService.marathi) {
        middayTitle = '🚨 Habit-Nova Alert: Instagram जिंकलं, तू हरलास?!';
        middayBody = 'दुपारचे २:३० झालेत आणि अभ्यास अजून शून्य?! रिल्स बंद कर आणि फोकस मोड चालू कर!';
        eveningTitle = '🔥 Streak Alert: आज रात्री १२ वाजता गेम ओव्हर?!';
        eveningBody = 'तुझा हॅबिट स्ट्रिक धोक्यात आहे! झोपण्यापूर्वी बाकी राहिलेले हॅबिट्स पूर्ण कर!';
      } else if (lang == LanguageService.hindi) {
        middayTitle = '🚨 Habit-Nova Alert: Instagram जीता, आप हारे?!';
        middayBody = 'दोपहर के २:३० बज गए और पढ़ाई अभी भी शून्य?! रील्स बंद करें और फोकस मोड चालू करें!';
        eveningTitle = '🔥 Streak Alert: आज रात १२ बजे खेल खत्म?!';
        eveningBody = 'आपकी हैबिट स्ट्रीक खतरे में है! सोने से पहले बची हुई आदतें पूरी करें!';
      } else {
        middayTitle = '🚨 Habit-Nova Alert: Instagram won, you lost?!';
        middayBody = 'It\'s 2:30 PM and study time is still ZERO?! Close Reels and turn on Focus mode right now!';
        eveningTitle = '🔥 Streak Alert: Game over at midnight?!';
        eveningBody = 'Your streak is on the line! Finish your remaining habits before going to bed!';
      }

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
        middayTitle,
        middayBody,
        details,
      );

      // Schedule at 8:30 PM (Evening streak savior)
      await _notificationsPlugin.show(
        882,
        eveningTitle,
        eveningBody,
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
