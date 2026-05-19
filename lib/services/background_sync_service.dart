import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:itm_connect/firebase_options.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/models/routine.dart';

/// Unique task name for WorkManager periodic sync
const String backgroundSyncTaskName = 'com.itm_connect.routine_sync';
const String _cachedRoutinesKey = 'cached_routines_json';

/// Top-level callback for WorkManager — runs in a separate Dart isolate.
/// Must be a top-level or static function, NOT inside a class.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('🔄 [BackgroundSync] Task started: $taskName');

    try {
      // 1. Initialize Firebase (required in background isolate)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize timezone
      tz.initializeTimeZones();
      try {
        final timeZone = await FlutterTimezone.getLocalTimezone();
        final String timeZoneName = timeZone is String ? timeZone : (timeZone as dynamic).name;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      }

      // 3. Check if user has set up their status
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final identifier = prefs.getString('user_identifier');

      if (role == null || identifier == null || identifier.isEmpty) {
        debugPrint('🔄 [BackgroundSync] No user status set — skipping.');
        return Future.value(true);
      }

      // 4. Fetch latest routines from Firebase
      List<Routine> allRoutines = [];
      try {
        final routineService = RoutineService();
        allRoutines = await routineService.streamAllRoutines().first;

        // Cache the fresh data
        final List<Map<String, dynamic>> jsonList =
            allRoutines.map((r) => {'id': r.id, 'data': r.toMap()}).toList();
        await prefs.setString(_cachedRoutinesKey, jsonEncode(jsonList));
        debugPrint(
            '🔄 [BackgroundSync] Fetched & cached ${allRoutines.length} routines.');
      } catch (e) {
        debugPrint('🔄 [BackgroundSync] Firebase fetch failed: $e');
        // Fallback to cached data
        final jsonString = prefs.getString(_cachedRoutinesKey);
        if (jsonString != null && jsonString.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          allRoutines = jsonList
              .map((json) => Routine.fromMap(
                    json['id'] as String,
                    Map<String, dynamic>.from(json['data'] as Map),
                  ))
              .toList();
          debugPrint(
              '🔄 [BackgroundSync] Loaded ${allRoutines.length} from cache.');
        }
      }

      if (allRoutines.isEmpty) {
        debugPrint('🔄 [BackgroundSync] No routines — done.');
        return Future.value(true);
      }

      // 5. Initialize local notifications plugin (new isolate = new instance)
      final localPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidInit);
      await localPlugin.initialize(initSettings);

      // 6. Create the notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'class_reminder_channel',
        'Class Reminders',
        description: 'Reminders for upcoming scheduled classes (10 min before)',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 7. Cancel all existing and re-schedule
      await localPlugin.cancelAll();

      // Filter relevant routines
      List<Routine> relevantRoutines = [];
      if (role == 'Student') {
        relevantRoutines = allRoutines
            .where((r) => r.batch.toUpperCase() == identifier.toUpperCase())
            .toList();
      } else if (role == 'Teacher') {
        relevantRoutines = allRoutines;
      }

      int notificationId = 1000;
      int scheduledCount = 0;

      for (var routine in relevantRoutines) {
        for (var routineClass in routine.classes) {
          bool shouldSchedule = false;

          if (role == 'Student') {
            shouldSchedule = true;
          } else if (role == 'Teacher') {
            shouldSchedule = routineClass.teacherInitial.toUpperCase() ==
                identifier.toUpperCase();
          }

          if (shouldSchedule) {
            final parts = routineClass.time.split('-');
            if (parts.isNotEmpty) {
              final startTimeStr = parts[0].trim();
              final DateTime? parsedTime = _parseTime(startTimeStr);
              if (parsedTime != null) {
                final int dayOfWeek = _getDayOfWeek(routine.day);
                if (dayOfWeek != -1) {
                  final String title = '📚 Class in 10 minutes!';
                  final StringBuffer bodyBuf = StringBuffer();
                  bodyBuf.writeln(
                      '${routineClass.courseName} (${routineClass.courseCode})');
                  bodyBuf.write(
                      '🕐 ${DateFormat('h:mm a').format(parsedTime)}');
                  if (routineClass.room.isNotEmpty) {
                    bodyBuf.write('  📍 ${routineClass.room}');
                  }
                  if (role == 'Teacher' && routine.batch.isNotEmpty) {
                    bodyBuf.write('\n👥 Batch ${routine.batch}');
                  }
                  if (role == 'Student' &&
                      routineClass.teacherInitial.isNotEmpty) {
                    bodyBuf.write('\n👨‍🏫 ${routineClass.teacherInitial}');
                  }
                  final String body = bodyBuf.toString();

                  // Compute scheduled time
                  tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(
                      dayOfWeek, parsedTime.hour, parsedTime.minute);
                  scheduledDate =
                      scheduledDate.subtract(const Duration(minutes: 10));
                  final now = tz.TZDateTime.now(tz.local);
                  if (scheduledDate.isBefore(now)) {
                    scheduledDate =
                        scheduledDate.add(const Duration(days: 7));
                  }

                  final androidDetails = AndroidNotificationDetails(
                    'class_reminder_channel',
                    'Class Reminders',
                    channelDescription:
                        'Reminders for upcoming scheduled classes (10 min before)',
                    importance: Importance.max,
                    priority: Priority.high,
                    icon: '@mipmap/launcher_icon',
                    enableVibration: true,
                    playSound: true,
                    showWhen: true,
                    autoCancel: true,
                    category: AndroidNotificationCategory.reminder,
                    visibility: NotificationVisibility.public,
                    styleInformation: BigTextStyleInformation(
                      body,
                      contentTitle: title,
                      summaryText: 'Class Reminder',
                    ),
                  );

                  await localPlugin.zonedSchedule(
                    notificationId++,
                    title,
                    body,
                    scheduledDate,
                    NotificationDetails(
                      android: androidDetails,
                      iOS: const DarwinNotificationDetails(
                        presentAlert: true,
                        presentBadge: true,
                        presentSound: true,
                      ),
                    ),
                    androidScheduleMode:
                        AndroidScheduleMode.exactAllowWhileIdle,
                    matchDateTimeComponents:
                        DateTimeComponents.dayOfWeekAndTime,
                  );
                  scheduledCount++;
                }
              }
            }
          }
        }
      }

      debugPrint(
          '🔄 [BackgroundSync] Done! Scheduled $scheduledCount notifications for $role: $identifier');
      return Future.value(true);
    } catch (e) {
      debugPrint('🔄 [BackgroundSync] Error: $e');
      return Future.value(false); // Will be retried by WorkManager
    }
  });
}

// ── Helper functions (must be top-level for isolate) ──

DateTime? _parseTime(String timeStr) {
  timeStr = timeStr.trim();
  if (timeStr.isEmpty) return null;
  try {
    return DateFormat('hh:mm a').parse(timeStr);
  } catch (_) {}
  try {
    return DateFormat('h:mm a').parse(timeStr);
  } catch (_) {}
  final serial = double.tryParse(timeStr);
  if (serial != null && serial >= 0 && serial <= 1) {
    int totalMinutes = (serial * 24 * 60).round();
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    return DateTime(2000, 1, 1, hour, minute);
  }
  try {
    final parts = timeStr.split(':');
    if (parts.isNotEmpty) {
      int hour = int.parse(parts[0].trim());
      int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return DateTime(2000, 1, 1, hour, minute);
      }
    }
  } catch (_) {}
  return null;
}

int _getDayOfWeek(String dayStr) {
  dayStr = dayStr.toLowerCase();
  if (dayStr.startsWith('mo')) return DateTime.monday;
  if (dayStr.startsWith('tu')) return DateTime.tuesday;
  if (dayStr.startsWith('we')) return DateTime.wednesday;
  if (dayStr.startsWith('th')) return DateTime.thursday;
  if (dayStr.startsWith('fr')) return DateTime.friday;
  if (dayStr.startsWith('sa')) return DateTime.saturday;
  if (dayStr.startsWith('su')) return DateTime.sunday;
  return -1;
}

tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  while (scheduledDate.weekday != dayOfWeek) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

/// Utility class to register / cancel background sync from the main isolate
class BackgroundSyncService {
  /// Register periodic background sync — runs approximately every 6 hours.
  /// Android minimum is 15 minutes, but we use 6 hours to be battery-friendly.
  static Future<void> register() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    await Workmanager().registerPeriodicTask(
      backgroundSyncTaskName,
      backgroundSyncTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected, // Only sync when internet available
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 10),
    );

    debugPrint('✅ Background sync registered (every ~6 hours)');
  }

  /// Cancel background sync (e.g. when user clears their status)
  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(backgroundSyncTaskName);
    debugPrint('🗑️ Background sync cancelled');
  }
}
