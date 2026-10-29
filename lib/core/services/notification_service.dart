
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Represents an alarm that is currently ringing.
class ActiveAlarm {
  final int id;
  final String title;
  final String body;
  final DateTime time;

  ActiveAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
  });
}


/// Service for managing local push notifications, exact alarm clocks, and reminders.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // High-priority alarm channel (Loud ringing audio stream)
  static const String _alarmChannelId = 'synvero_alarm_clock_channel_v6';
  static const String _alarmChannelName = 'Synvero Task Alarms (Loud)';
  static const String _alarmChannelDescription =
      'High priority ringing alarm alerts for scheduled tasks and habits';

  // 5-minute advance reminder channel
  static const String _reminderChannelId = 'synvero_task_reminders_channel_v6';
  static const String _reminderChannelName = 'Synvero Task Reminders (5 Min Prior)';
  static const String _reminderChannelDescription =
      'Advance reminder notifications 5 minutes before scheduled task time';

  static bool _isInitialized = false;
  /// Active alarm notifier. The app listens to this to show the in-app Stop Alarm dialog.
  static final ValueNotifier<ActiveAlarm?> activeAlarmNotifier =
      ValueNotifier<ActiveAlarm?>(null);

  // Native alarm channel for continuous MediaPlayer audio & Vibrator
  static const MethodChannel _alarmMethodChannel = MethodChannel('com.example.synvero/alarm');

  /// Starts the continuous native alarm audio and vibration loop
  static Future<void> startNativeAlarm() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _alarmMethodChannel.invokeMethod('startAlarmRing');
    } catch (e) {
      debugPrint('startNativeAlarm error: ');
    }
  }

  /// Stops the continuous native alarm audio and vibration loop
  static Future<void> stopNativeAlarm() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _alarmMethodChannel.invokeMethod('stopAlarmRing');
    } catch (e) {
      debugPrint('stopNativeAlarm error: ');
    }
  }


  // Active in-app timer fallback map to guarantee 0-delay triggers
  static final Map<int, Timer> _activeTimers = {};

  // Preference keys
  static const String _prefHabits = 'synvero_notif_habits';
  static const String _prefTimer = 'synvero_notif_timer';
  static const String _prefNutrition = 'synvero_notif_nutrition';
  static const String _prefTasks = 'synvero_notif_tasks';

  // Alarm ringtone URI on Android
  static const UriAndroidNotificationSound _alarmSound =
      UriAndroidNotificationSound('content://settings/system/alarm_alert');

  // Alarm vibration rhythm (repeating pulse)
  static final Int64List _alarmVibration =
      Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]);

  /// Initializes timezone data, matches device timezone offset, and sets up notification channels.
  static Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      // Configure local timezone to match the device's exact current offset
      _setupLocalTimezone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          debugPrint('Notification clicked/action: ${response.actionId}, payload: ${response.payload}');
          // DO NOT cancel the alarm here! Touching notification keeps alarm playing!
          if (response.id != null && response.id! < 9000) {
            await startNativeAlarm();
            activeAlarmNotifier.value = ActiveAlarm(
              id: response.id!,
              title: response.payload?.isNotEmpty == true ? response.payload! : 'Scheduled Task Alarm',
              body: 'Time for your scheduled task!',
              time: DateTime.now(),
            );
          }
        },
      );

      // Create Android Notification Channels
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // 1. Loud Alarm Channel (Uses Alarm Audio Stream)
          final alarmChannel = AndroidNotificationChannel(
            _alarmChannelId,
            _alarmChannelName,
            description: _alarmChannelDescription,
            importance: Importance.max,
            playSound: true,
            sound: _alarmSound,
            enableVibration: true,
            vibrationPattern: _alarmVibration,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidImplementation.createNotificationChannel(alarmChannel);

          // 2. 5-Min Advance Reminder Channel
          const reminderChannel = AndroidNotificationChannel(
            _reminderChannelId,
            _reminderChannelName,
            description: _reminderChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          );
          await androidImplementation.createNotificationChannel(reminderChannel);

          // Request permissions for Android 13+ (API 33/34)
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized with Timezone & Dual Channels.');

      // Check if app was opened from an active alarm notification
      try {
        final launchDetails =
            await _notificationsPlugin.getNotificationAppLaunchDetails();
        if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
          final res = launchDetails.notificationResponse;
          if (res != null && res.id != null) {
            await startNativeAlarm();
            activeAlarmNotifier.value = ActiveAlarm(
              id: res.id!,
              title: res.payload?.isNotEmpty == true
                  ? res.payload!
                  : 'Scheduled Task Alarm',
              body: 'Time for your scheduled task!',
              time: DateTime.now(),
            );
          }
        }
      } catch (e) {
        debugPrint('Error checking launch details: $e');
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Sets tz.local to the location that matches the device's current UTC offset.
  static void _setupLocalTimezone() {
    try {
      final now = DateTime.now();
      final currentOffsetMs = now.timeZoneOffset.inMilliseconds;

      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.currentTimeZone.offset == currentOffsetMs) {
          tz.setLocalLocation(location);
          debugPrint('Set timezone location to ${location.name} (offset: ${now.timeZoneOffset})');
          return;
        }
      }
    } catch (e) {
      debugPrint('Timezone location lookup failed: $e');
    }
  }

  /// Explicitly requests notification & exact alarm permissions on Android 13+.
  static Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return true;
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted =
              await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Alias for requestPermissions used by ProfileScreen
  static Future<bool> requestPermission() => requestPermissions();

  /// Checks the current permission status string ('granted', 'denied', or 'default').
  static Future<String> getPermissionStatus() async {
    try {
      if (kIsWeb) return 'granted';
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted =
              await androidImplementation.areNotificationsEnabled();
          return (granted ?? false) ? 'granted' : 'denied';
        }
      }
      return 'granted';
    } catch (_) {
      return 'default';
    }
  }

  /// Sends a one-off notification, returning success status.
  static Future<bool> sendNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Displays an instant heads-up alarm with loud ringtone and strong vibration.
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: _alarmSound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: _alarmVibration,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: false,
        additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: repeat audio until user intervenes

      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await startNativeAlarm();
      activeAlarmNotifier.value = ActiveAlarm(
        id: id,
        title: title,
        body: body,
        time: DateTime.now(),
      );
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing instant alarm: $e');
    }
  }

  /// Displays a heads-up 5-minute advance reminder notification.
  static Future<void> showInstantReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing instant reminder: $e');
    }
  }

  /// Schedules a loud, ringing alarm clock at the exact task time.
  /// Uses a dual-layer approach: in-app Dart Timer + OS AlarmManager.
  static Future<void> scheduleTaskAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint('Cannot schedule in the past: $scheduledDate');
        return;
      }

      // 1. In-app Timer Layer (guarantees instantaneous trigger if app is running/paused)
      _activeTimers[id]?.cancel();
      final diff = scheduledDate.difference(DateTime.now());
      if (!diff.isNegative) {
        _activeTimers[id] = Timer(diff, () async {
          debugPrint('In-app Timer fired Alarm for ID $id');
          await showInstantNotification(
            id: id,
            title: title,
            body: body,
          );
        });
        debugPrint('In-app Alarm timer set for ${diff.inSeconds}s (id: $id)');
      }

      // 2. OS Level AlarmClock Layer (guarantees trigger even if screen off / app closed)
      if (kIsWeb) return;
      _setupLocalTimezone();
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: _alarmSound,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: _alarmVibration,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: false,
        additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: repeat audio until stopped

      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('OS AlarmClock scheduled for id: $id at: $tzDateTime');
    } catch (e) {
      debugPrint('Error scheduling task alarm: $e');
      try {
        final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _alarmChannelId,
              _alarmChannelName,
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              sound: _alarmSound,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              vibrationPattern: _alarmVibration,
              category: AndroidNotificationCategory.alarm,
              additionalFlags: Int32List.fromList([4]),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('Fallback exact schedule error: $e2');
      }
    }
  }

  /// Schedules an advance reminder 5 minutes before the task time.
  static Future<void> scheduleAdvanceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) return;

      // 1. In-app Timer Layer
      _activeTimers[id]?.cancel();
      final diff = scheduledDate.difference(DateTime.now());
      if (!diff.isNegative) {
        _activeTimers[id] = Timer(diff, () async {
          debugPrint('In-app Timer fired 5-min Reminder for ID $id');
          await showInstantReminder(
            id: id,
            title: title,
            body: body,
          );
        });
      }

      // 2. OS Level Layer
      if (kIsWeb) return;
      _setupLocalTimezone();
      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('5-Min Advance Reminder scheduled for id: $id at: $tzDateTime');
    } catch (e) {
      debugPrint('Error scheduling 5-min advance reminder: $e');
    }
  }

  /// Schedules recurring daily reminders 3 times a day (11:30 AM, 5:30 PM, 9:15 PM)
  /// to encourage user engagement, habit tracking, and streak maintenance.
  static Future<void> scheduleDailyHabitReminders() async {
    if (kIsWeb) return;
    try {
      _setupLocalTimezone();

      final reminders = [
        {
          'id': 9001,
          'hour': 11,
          'minute': 30,
          'title': '☀️ Midday Habit Check-in!',
          'body': 'Did you complete your morning habits? Open HabbitNova to check off your progress! 🔥',
        },
        {
          'id': 9002,
          'hour': 17,
          'minute': 30,
          'title': '🎯 Afternoon Task Momentum',
          'body': "How are today's tasks going? Check off what you completed and finish strong today! 💪",
        },
        {
          'id': 9003,
          'hour': 21,
          'minute': 15,
          'title': '🌙 Evening Streak Saver!',
          'body': "Don't break your streak! 1 tap to complete today's remaining habits before bed. 🌟",
        },
      ];

      for (final r in reminders) {
        final id = r['id'] as int;
        final hour = r['hour'] as int;
        final minute = r['minute'] as int;
        final title = r['title'] as String;
        final body = r['body'] as String;

        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        const androidDetails = AndroidNotificationDetails(
          _reminderChannelId,
          _reminderChannelName,
          channelDescription: _reminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
      debugPrint('Daily 3x habit reminders successfully scheduled!');
    } catch (e) {
      debugPrint('Error scheduling daily habit reminders: $e');
    }
  }

  /// Cancels all alarms and reminders associated with a task ID.

  /// Stops an actively ringing alarm: cancels notification, clears in-app dialog and audio/vibration.
  static Future<void> stopActiveAlarm(int id) async {
    await stopNativeAlarm();
    await cancelTaskAlarms(id);
    if (activeAlarmNotifier.value?.id == id) {
      activeAlarmNotifier.value = null;
    }
  }

  /// Checks OS active notifications and triggers in-app alarm dialog if an alarm is ringing.
  static Future<void> checkForActiveAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final activeNotifs = await android?.getActiveNotifications();
      if (activeNotifs != null && activeNotifs.isNotEmpty) {
        for (final notif in activeNotifs) {
          if (notif.channelId == _alarmChannelId && notif.id != null) {
            activeAlarmNotifier.value = ActiveAlarm(
              id: notif.id!,
              title: notif.title ?? 'Task Alarm',
              body: notif.body ?? 'Time for your scheduled task!',
              time: DateTime.now(),
            );
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('checkForActiveAlarms error: $e');
    }
  }

  static Future<void> cancelTaskAlarms(int id) async {
    try {
      _activeTimers[id]?.cancel();
      _activeTimers.remove(id);

      final reminderId = (id + 1000000) & 0x7fffffff;
      _activeTimers[reminderId]?.cancel();
      _activeTimers.remove(reminderId);

      if (!kIsWeb) {
        await _notificationsPlugin.cancel(id);
        await _notificationsPlugin.cancel(reminderId);
      }
    } catch (e) {
      debugPrint('Error cancelling task alarms: $e');
    }
  }

  /// Cancels a scheduled notification by ID.
  static Future<void> cancel(int id) => cancelTaskAlarms(id);

  /// Cancels all scheduled notifications and timers.
  static Future<void> cancelAll() async {
    try {
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();
      if (!kIsWeb) {
        await _notificationsPlugin.cancelAll();
      }
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Preference accessors for Profile Screen
  static Future<bool> getHabitRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefHabits) ?? true;
  }

  static Future<void> setHabitRemindersEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefHabits, val);
  }

  static Future<bool> getTimerAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefTimer) ?? true;
  }

  static Future<void> setTimerAlertsEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTimer, val);
  }

  static Future<bool> getNutritionRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNutrition) ?? true;
  }

  static Future<void> setNutritionRemindersEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNutrition, val);
  }

  static Future<bool> getTaskRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefTasks) ?? true;
  }

  static Future<void> setTaskRemindersEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTasks, val);
  }
}
