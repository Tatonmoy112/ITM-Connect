import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` in this handler if needed.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Shared plugin instance — used by both NotificationService and ScheduleService
  static final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Channel ID for FCM push notifications
  static const String fcmChannelId = 'high_importance_channel';
  static const String fcmChannelName = 'High Importance Notifications';
  static const String fcmChannelDesc =
      'This channel is used for important notifications.';

  /// Channel ID for scheduled class reminder notifications
  static const String classReminderChannelId = 'class_reminder_channel';
  static const String classReminderChannelName = 'Class Reminders';
  static const String classReminderChannelDesc =
      'Reminders for upcoming scheduled classes (10 min before)';

  Future<void> init() async {
    // 1. Request permissions (especially for iOS and Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Get the FCM Token
    try {
      final String? token = await _firebaseMessaging.getToken();
      debugPrint('========= FCM TOKEN =========');
      debugPrint(token);
      debugPrint('=============================');
      // Note: In a production app, you might want to send this token to your server
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // 3. Handle background and terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Initialize local notifications for foreground messaging
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        debugPrint(
            'Notification tapped: ${notificationResponse.payload}');
        // Handle navigation or other actions when notification is tapped
      },
    );

    // 5. Request Android 13+ notification permission
    try {
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Could not request notification permission: $e');
    }

    // 6. Request exact alarm permission (Android 12+)
    try {
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Could not request exact alarm permission: $e');
    }

    // 7. Create Android Notification Channels
    // ── FCM channel ──
    const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
      fcmChannelId,
      fcmChannelName,
      description: fcmChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // ── Class Reminder channel ──
    const AndroidNotificationChannel classReminderChannel =
        AndroidNotificationChannel(
      classReminderChannelId,
      classReminderChannelName,
      description: classReminderChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(fcmChannel);
    await androidPlugin?.createNotificationChannel(classReminderChannel);

    debugPrint('✅ Created notification channels: $fcmChannelId, $classReminderChannelId');

    // 8. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              fcmChannel.id,
              fcmChannel.name,
              channelDescription: fcmChannel.description,
              icon: '@mipmap/launcher_icon',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 9. Handle when app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped from background state!');
      debugPrint('Message data: ${message.data}');
    });
  }
}
