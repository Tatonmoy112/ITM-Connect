import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itm_connect/theme/app_theme.dart';
import 'package:itm_connect/theme/theme_provider.dart';
import 'package:itm_connect/features/landing/landing_screen.dart';
import 'package:itm_connect/features/landing/role_setup_screen.dart';
import 'package:itm_connect/features/user/home/user_home_screen.dart';
import 'package:itm_connect/features/user/class_routine/class_routine_screen.dart';
import 'package:itm_connect/features/user/teacher/list/teacher_list_screen.dart';
import 'package:itm_connect/features/user/notice/notice_board_screen.dart';
import 'package:itm_connect/features/user/contact/contact_us_screen.dart';
import 'package:itm_connect/features/user/feedback/feedback_screen.dart';
import 'package:itm_connect/features/user/settings/settings_screen.dart';
import 'package:itm_connect/features/admin/login/admin_login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ITM Connect',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: FutureBuilder<bool>(
        future: _hasCompletedSetup(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
          final hasSeen = snapshot.data ?? false;
          if (hasSeen) {
            return const UserHomeScreen(initialTabIndex: -1);
          }
          return const LandingScreen();
        },
      ),
      routes: {
        '/home': (context) => const UserHomeScreen(),
        '/class-routine': (context) => const ClassRoutineScreen(),
        '/teachers': (context) => const TeacherListScreen(),
        '/notices': (context) => const NoticeBoardScreen(),
        '/contact': (context) => const ContactUsScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
      },
      builder: (context, home) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: home!,
        );
      },
    );
  }

  static Future<bool> _hasCompletedSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_completed_setup') ?? false;
  }
}
