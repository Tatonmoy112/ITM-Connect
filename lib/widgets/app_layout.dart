import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class AppLayout extends StatelessWidget {
  final bool showAppBar;
  final bool showBottomNavBar;
  final bool showFloatingActionButton;
  final int currentIndex;
  final Widget body;
  final void Function(int index) onBottomNavTap;
  final Widget? leading;

  const AppLayout({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.showFloatingActionButton = true,
    this.currentIndex = -1,
    required this.onBottomNavTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: leading ??
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.teal),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    },
                  ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(width: 8),
                  const Text(
                    'ITM Connect',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.teal),
                  tooltip: 'Admin Login',
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                ),
              ],
            )
          : null,
      body: SafeArea(child: body),
      bottomNavigationBar: showBottomNavBar
          ? SalomonBottomBar(
              currentIndex: currentIndex == -1 ? 2 : currentIndex,
              onTap: onBottomNavTap,
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.person),
                  title: const Text(""),
                  selectedColor: Colors.teal,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.notifications),
                  title: const Text(""),
                  selectedColor: Colors.orange,
                ),
                SalomonBottomBarItem(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.calendar_month_rounded, color: Colors.teal, size: 32),
                  ),
                  title: const Text(""),
                  selectedColor: Colors.teal,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.contact_mail),
                  title: const Text(""),
                  selectedColor: Colors.green,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.feedback),
                  title: const Text(""),
                  selectedColor: Colors.deepPurple,
                ),
              ],
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
