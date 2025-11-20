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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teal Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage all operations',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.person, 'Teachers',
                      'Add, update, and delete teacher information.'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.notifications, 'Notices',
                      'Create and publish important notices.'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.calendar_month, 'Routines',
                      'Manage class schedules and routines.'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.feedback, 'Feedback',
                      'Review feedback from students and staff.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
