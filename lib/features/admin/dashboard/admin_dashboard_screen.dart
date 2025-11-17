import 'package:flutter/material.dart';
import '../../../widgets/admin_app_layout.dart';

import '../manage_teachers/manage_teachers_screen.dart';
import '../manage_notices/manage_notices_screen.dart';
import '../manage_routines/manage_routines_screen.dart';
import '../feedback/manage_feedback_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = -1; // -1 means dashboard welcome page (no bottom nav selected)

  final List<Widget> _pages = [
    const _WelcomeDashboardCard(),
    const ManageTeacherScreen(),
    const ManageNoticesScreen(),
    const ManageRoutineScreen(),
    const ManageFeedbackScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index; // 0 to 3 corresponds to ManageTeacher to ManageFeedback
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget currentBody =
    _currentIndex == -1 ? _pages[0] : _pages[_currentIndex + 1];

    return AdminAppLayout(
      currentIndex: _currentIndex,
      onBottomNavTap: _onNavTap,
      body: currentBody,
      showAppBar: true,
      showBottomNavBar: true,
    );
  }
}

class _WelcomeDashboardCard extends StatelessWidget {
  const _WelcomeDashboardCard();

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.teal.shade700,
    );
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.grey[700],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome to Admin Dashboard', style: titleStyle),
              const SizedBox(height: 16),
              Text(
                'Manage all teachers, notices, routines, and feedback easily from here.',
                style: textStyle,
              ),
              const SizedBox(height: 24),
              _infoRow(Icons.person, 'Teachers',
                  'Add, update, and delete teacher information.'),
              const SizedBox(height: 16),
              _infoRow(Icons.notifications, 'Notices',
                  'Create and publish important notices.'),
              const SizedBox(height: 16),
              _infoRow(Icons.calendar_month, 'Routines',
                  'Manage class schedules and routines.'),
              const SizedBox(height: 16),
              _infoRow(Icons.feedback, 'Feedback',
                  'Review feedback from students and staff.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
