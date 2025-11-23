import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

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
                
                late EdgeInsets itemPadding;
                late double iconSize;
                late double fontSize;
                late double navBarHeight;
                
                if (isSmallScreen) {
                  itemPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 8);
                  iconSize = 22.0;
                  fontSize = 9.0;
                  navBarHeight = 70;
                } else if (isMediumScreen) {
                  itemPadding = const EdgeInsets.symmetric(vertical: 12, horizontal: 12);
                  iconSize = 26.0;
                  fontSize = 11.0;
                  navBarHeight = 75;
                } else {
                  itemPadding = const EdgeInsets.symmetric(vertical: 16, horizontal: 20);
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: SalomonBottomBar(
                        currentIndex: widget.currentIndex,
                        onTap: widget.onBottomNavTap,
                        itemPadding: itemPadding,
                        backgroundColor: Colors.white,
                        items: [
                          SalomonBottomBarItem(
                            icon: Icon(Icons.person_rounded, size: iconSize),
                            title: Text("Faculty", style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
                            selectedColor: const Color(0xFF185a9d),
                            unselectedColor: Colors.grey.shade500,
                          ),
                          SalomonBottomBarItem(
                            icon: Icon(Icons.notifications_rounded, size: iconSize),
                            title: Text("Notices", style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
                            selectedColor: const Color(0xFF43cea2),
                            unselectedColor: Colors.grey.shade500,
                          ),
                          SalomonBottomBarItem(
                            icon: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF185a9d), Color(0xFF43cea2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF43cea2).withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: isSmallScreen ? 24.0 : 28.0),
                            ),
                            title: Text("Routines", style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
                            selectedColor: const Color(0xFF185a9d),
                            unselectedColor: Colors.grey.shade500,
                          ),
                          SalomonBottomBarItem(
                            icon: Icon(Icons.feedback_rounded, size: iconSize),
                            title: Text("Feedback", style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
                            selectedColor: const Color(0xFF185a9d),
                            unselectedColor: Colors.grey.shade500,
                          ),
                        ],
                      ),
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

