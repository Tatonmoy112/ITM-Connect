import 'package:flutter/material.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/manage_routines/manage_routines_screen.dart';
import '../features/admin/manage_teachers/manage_teachers_screen.dart';
import '../features/admin/manage_notices/manage_notices_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/dashboard': (_) => const AdminDashboardScreen(),
  '/routines': (_) => const ManageRoutineScreen(),
  '/teachers': (_) => const ManageTeacherScreen(),
  '/notices': (_) => const ManageNoticesScreen(),
};



