import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/schedule_service.dart';
import 'services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // 2. Initialize NotificationService FIRST — this creates the shared plugin
  //    instance AND both notification channels (FCM + class reminders).
  //    This MUST run before ScheduleService so channels exist before scheduling.
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification Service initialization error: $e');
  }

  // 3. Initialize ScheduleService (timezone setup) AFTER NotificationService
  try {
    await ScheduleService().init();
  } catch (e) {
    debugPrint('Schedule Service init error: $e');
  }

  // 4. Schedule/re-schedule class notifications on every app launch.
  //    This ensures notifications are re-registered even if they were
  //    lost due to app update, cache clear, or force-stop.
  try {
    await ScheduleService().scheduleClassNotifications();
  } catch (e) {
    debugPrint('Schedule notifications error: $e');
  }

  // 5. Register WorkManager periodic background sync (~every 6 hours).
  //    This ensures notifications stay up-to-date with any routine changes
  //    on Firebase, even if the user never opens the app.
  try {
    await BackgroundSyncService.register();
  } catch (e) {
    debugPrint('Background sync registration error: $e');
  }

  // Run the app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}
