import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/admin_app_layout.dart';

import '../manage_teachers/manage_teachers_screen.dart';
import '../manage_notices/manage_notices_screen.dart';
import '../manage_routines/manage_routines_screen.dart';
import '../manage_exam_routines/manage_exam_routines_screen.dart';
import '../feedback/manage_feedback_screen.dart';
import '../manage_news/manage_news_screen.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = -1; // -1 means dashboard welcome page (no bottom nav selected)

  final List<Widget> _pages = [
    // We pass a placeholder function here initially, but we will fix it in build
    const SizedBox(), 
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

  Widget build(BuildContext context) {
    // Inject the callback for the welcome card
    final Widget currentBody = _currentIndex == -1 
        ? _WelcomeDashboardCard(onNavTap: _onNavTap) 
        : _pages[_currentIndex + 1];

    return AdminAppLayout(
      currentIndex: _currentIndex,
      onBottomNavTap: _onNavTap,
      body: currentBody,
      showAppBar: true,
      showBottomNavBar: true,
    );
  }
}

class _WelcomeDashboardCard extends StatefulWidget {
  final Function(int) onNavTap;
  const _WelcomeDashboardCard({required this.onNavTap});

  @override
  State<_WelcomeDashboardCard> createState() => _WelcomeDashboardCardState();
}

class _WelcomeDashboardCardState extends State<_WelcomeDashboardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    // Responsive spacing
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final contentPadding = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final infoRowSpacing = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: containerMaxWidth),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teal Header with Gradient
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(headerPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.teal.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage all operations',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: subtitleFontSize,
                                letterSpacing: 0.3,
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
                        padding: EdgeInsets.all(isMobile ? 8 : 10),
                        child: Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: isMobile ? 24 : 28,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: isMobile ? 14.0 : (isTablet ? 15.0 : 16.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: infoRowSpacing + 2),
                      _infoRow(
                        Icons.person,
                        'Teachers',
                        'Add, update, and delete teacher information.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () => widget.onNavTap(0),
                      ),
                      SizedBox(height: infoRowSpacing),
                      _infoRow(
                        Icons.notifications,
                        'Notices',
                        'Create and publish important notices.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () => widget.onNavTap(1),
                      ),
                      SizedBox(height: infoRowSpacing),
                      _infoRow(
                        Icons.calendar_month,
                        'Routines',
                        'Manage class schedules and routines.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () => widget.onNavTap(2),
                      ),
                      SizedBox(height: infoRowSpacing),
                       _infoRow(
                        Icons.event_note,
                        'Exam Routines',
                        'Schedule exams and manage dates.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () {
                           Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const ManageExamRoutineScreen())
                          );
                        },
                      ),
                      SizedBox(height: infoRowSpacing),
                      _infoRow(
                        Icons.newspaper,
                        'News',
                        'Manage news & announcements.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () {
                           Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const ManageNewsScreen())
                          );
                        },
                      ),
                      SizedBox(height: infoRowSpacing),

                      _infoRow(
                        Icons.feedback,
                        'Feedback',
                        'Review feedback from students and staff.',
                        isMobile,
                        isTablet,
                        infoRowSpacing,
                        onTap: () => widget.onNavTap(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
    bool isMobile,
    bool isTablet,
    double spacing, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withOpacity(0.1), width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                child: Icon(
                  icon,
                  color: Colors.teal.shade600,
                  size: isMobile ? 20 : 24,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13.0 : (isTablet ? 14.0 : 15.0),
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0),
                        color: Colors.black54,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                 Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400)
            ],
          ),
        ),
      ),
    );
  }
}
