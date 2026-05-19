import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/notification_service.dart';
import 'package:itm_connect/services/background_sync_service.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static const String _cachedRoutinesKey = 'cached_routines_json';

  /// Use the shared plugin instance from NotificationService — NOT a new one.
  /// Creating a separate instance was causing channel/init conflicts.
  FlutterLocalNotificationsPlugin get _localNotificationsPlugin =>
      NotificationService.localNotificationsPlugin;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName =
          timeZone is String ? timeZone : (timeZone as dynamic).name;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Local timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ Could not get local timezone, using UTC: $e');
      // Fallback: use Asia/Dhaka since this is a Bangladesh university app
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
        debugPrint('✅ Fallback timezone set to: Asia/Dhaka');
      } catch (_) {
        debugPrint('⚠️ Fallback timezone also failed');
      }
    }
  }

  Future<void> scheduleClassNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final identifier = prefs.getString('user_identifier');

    if (role == null || identifier == null || identifier.isEmpty) {
      debugPrint('⏭️ No user role/identifier set — skipping notification scheduling.');
      return; // Not setup yet
    }

    // 1. Cancel all existing scheduled notifications (class reminders only, IDs >= 1000)
    await _localNotificationsPlugin.cancelAll();
    debugPrint('🗑️ Cancelled all existing scheduled notifications.');

    // 2. Fetch routines — try Firebase first, fallback to cache
    List<Routine> allRoutines = [];

    try {
      final routineService = RoutineService();
      allRoutines = await routineService.streamAllRoutines().first;
      // Cache on success
      await _cacheRoutines(allRoutines);
      debugPrint(
          '✅ Fetched ${allRoutines.length} routines from Firebase and cached.');
    } catch (e) {
      debugPrint('⚠️ Error fetching routines from Firebase: $e');
      // Fallback to cache
      allRoutines = await _getCachedRoutines();
      debugPrint('📦 Loaded ${allRoutines.length} routines from cache.');
    }

    if (allRoutines.isEmpty) {
      debugPrint('❌ No routines available to schedule notifications.');
      return;
    }

    // Filter routines
    List<Routine> relevantRoutines = [];
    if (role == 'Student') {
      relevantRoutines = allRoutines
          .where((r) => r.batch.toUpperCase() == identifier.toUpperCase())
          .toList();
    } else if (role == 'Teacher') {
      relevantRoutines = allRoutines; // We filter individual classes later
    }

    int notificationId = 1000; // Base ID for offline class notifications
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
                // Build a rich notification body with full class details
                final String title = '📚 Class in 10 minutes!';
                final StringBuffer bodyBuffer = StringBuffer();

                bodyBuffer.writeln(
                    '${routineClass.courseName} (${routineClass.courseCode})');
                bodyBuffer.write('🕐 ${_formatTime(parsedTime)}');
                if (routineClass.room.isNotEmpty) {
                  bodyBuffer.write('  📍 ${routineClass.room}');
                }

                if (role == 'Teacher' && routine.batch.isNotEmpty) {
                  bodyBuffer.write('\n👥 Batch ${routine.batch}');
                }
                if (role == 'Student' &&
                    routineClass.teacherInitial.isNotEmpty) {
                  bodyBuffer
                      .write('\n👨‍🏫 ${routineClass.teacherInitial}');
                }

                final String body = bodyBuffer.toString();

                await _scheduleWeeklyNotification(
                  id: notificationId++,
                  title: title,
                  body: body,
                  dayOfWeek: dayOfWeek,
                  hour: parsedTime.hour,
                  minute: parsedTime.minute,
                );
                scheduledCount++;
              }
            } else {
              debugPrint(
                  '⚠️ Could not parse time: "$startTimeStr" for ${routineClass.courseName}');
            }
          }
        }
      }
    }

    debugPrint(
        '✅ Scheduled $scheduledCount class reminder notifications for $role: $identifier');
  }

  /// Format a DateTime to a readable time string
  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  // ──────────────────────────────────────────────
  // Time Parsing — handles all formats
  // ──────────────────────────────────────────────

  DateTime? _parseTime(String timeStr) {
    timeStr = timeStr.trim();
    if (timeStr.isEmpty) return null;

    // 1. Try standard "hh:mm a" / "h:mm a" format (e.g. "10:45 PM")
    try {
      return DateFormat('hh:mm a').parse(timeStr);
    } catch (_) {}

    // Also try single-digit hour variant
    try {
      return DateFormat('h:mm a').parse(timeStr);
    } catch (_) {}

    // 2. Try Google Sheets serial number (0.0 – 1.0 represents 00:00 – 23:59)
    final serial = double.tryParse(timeStr);
    if (serial != null && serial >= 0 && serial <= 1) {
      int totalMinutes = (serial * 24 * 60).round();
      int hour = (totalMinutes ~/ 60) % 24;
      int minute = totalMinutes % 60;
      return DateTime(2000, 1, 1, hour, minute);
    }

    // 3. Try 24-hour "HH:mm" or "H:mm" format (e.g. "22:45")
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

  // ──────────────────────────────────────────────
  // Routine Caching (SharedPreferences + JSON)
  // ──────────────────────────────────────────────

  /// Serialize and save routines to SharedPreferences
  Future<void> _cacheRoutines(List<Routine> routines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          routines.map((r) => _routineToJson(r)).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_cachedRoutinesKey, jsonString);
      debugPrint('📦 Cached ${routines.length} routines to SharedPreferences.');
    } catch (e) {
      debugPrint('Error caching routines: $e');
    }
  }

  /// Load routines from SharedPreferences cache
  Future<List<Routine>> _getCachedRoutines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedRoutinesKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Routine.fromMap(
                json['id'] as String,
                Map<String, dynamic>.from(json['data'] as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('Error loading cached routines: $e');
      return [];
    }
  }

  /// Convert a Routine to a JSON-serializable map (including its ID)
  Map<String, dynamic> _routineToJson(Routine routine) {
    return {
      'id': routine.id,
      'data': routine.toMap(),
    };
  }

  /// Public method to cache routines after successful validation
  /// Called from RoleSetupScreen after saving user preferences
  Future<void> cacheRoutinesForUser(String role, String identifier) async {
    try {
      final routineService = RoutineService();
      final allRoutines = await routineService.streamAllRoutines().first;
      await _cacheRoutines(allRoutines);
      debugPrint('✅ Cached routines for $role: $identifier');
    } catch (e) {
      debugPrint('Error caching routines for user: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Notification Scheduling
  // ──────────────────────────────────────────────

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    // Build the scheduled time using TZDateTime
    tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, hour, minute);

    // Subtract 10 minutes for the "10 min before" reminder
    scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));

    // If the computed time is in the past, push to next week
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    // Rich notification with BigTextStyle so full details show in notification panel
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      NotificationService.classReminderChannelId,
      NotificationService.classReminderChannelName,
      channelDescription: NotificationService.classReminderChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      enableVibration: true,
      playSound: true,
      showWhen: true,
      autoCancel: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      // BigTextStyle shows the full multi-line body in the notification tray
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Class Reminder',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    final dayName = _dayOfWeekName(dayOfWeek);
    debugPrint(
        '  🔔 Notification #$id → $dayName ${DateFormat('h:mm a').format(scheduledDate)}');
  }

  /// Compute the next instance of a given day-of-week and time
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
    // Advance to the correct weekday
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Human-readable day name for debug logging
  String _dayOfWeekName(int dayOfWeek) {
    const names = {
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return names[dayOfWeek] ?? 'Unknown';
  }

  /// Clears all scheduled notifications, cancels background sync,
  /// and removes user role/identifier from prefs
  Future<void> clearNotifications() async {
    await _localNotificationsPlugin.cancelAll();
    // Also cancel the periodic background sync
    try {
      await BackgroundSyncService.cancel();
    } catch (e) {
      debugPrint('Error cancelling background sync: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_identifier');
    await prefs.remove(_cachedRoutinesKey);
    debugPrint('🗑️ All notifications cleared and user status reset.');
  }
}
