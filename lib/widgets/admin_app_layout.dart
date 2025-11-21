import 'package:flutter/material.dart';

class AdminAppLayout extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNavBar;
  final int currentIndex;
  final Widget body;
  final void Function(int index) onBottomNavTap;
  final Widget? leading;

  const AdminAppLayout({
    super.key,
    required this.body,
    required this.onBottomNavTap,
    this.currentIndex = 0,
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.leading,
  });

  @override
  State<AdminAppLayout> createState() => _AdminAppLayoutState();
}

class _AdminAppLayoutState extends State<AdminAppLayout> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _floatingAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.08),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: widget.leading ??
                  IconButton(
                    icon: const Icon(Icons.dashboard, color: Colors.teal),
                    onPressed: () {
                      if (widget.currentIndex != -1) {
                        widget.onBottomNavTap(-1); // Go to dashboard welcome page
                      }
                    },
                  ),
              title: SlideTransition(
                position: _floatingAnimation,
                child: _buildLogo(),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.teal),
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/admin_login', (route) => false);
                  },
                ),
              ],
            )
          : null,
      body: widget.body,
      bottomNavigationBar: widget.showBottomNavBar
          ? LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 360;
                final isMediumScreen = constraints.maxWidth >= 360 && constraints.maxWidth < 600;

                late double iconSize;
                late double fontSize;
                late double navBarHeight;

                if (isSmallScreen) {
                  iconSize = 22.0;
                  fontSize = 9.0;
                  navBarHeight = 70;
                } else if (isMediumScreen) {
                  iconSize = 24.0;
                  fontSize = 11.0;
                  navBarHeight = 75;
                } else {
                  iconSize = 28.0;
                  fontSize = 12.0;
                  navBarHeight = 85;
                }

                return Container(
                  height: navBarHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: BottomNavigationBar(
                      currentIndex: widget.currentIndex >= 0 ? widget.currentIndex : 0,
                      onTap: widget.onBottomNavTap,
                      selectedItemColor: const Color(0xFF185a9d),
                      unselectedItemColor: Colors.grey.shade500,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedLabelStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.normal,
                      ),
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_rounded, size: iconSize),
                          label: 'Teachers',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.notifications_rounded, size: iconSize),
                          label: 'Notices',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.calendar_month_rounded, size: iconSize),
                          label: 'Routines',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.feedback_rounded, size: iconSize),
                          label: 'Feedback',
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildLogo() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: Icon(
        Icons.school,
        size: 20,
        color: Colors.teal.shade700,
      ),
    );
  }
}

