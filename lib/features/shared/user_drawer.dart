import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:itm_connect/theme/app_colors.dart';

class UserDrawer extends StatelessWidget {
  final String currentPage;

  const UserDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? ITMColors.darkSurface : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ITMColors.brandGradient,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Image.asset(
                    'assets/images/Itm_logo.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ITM Connect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'User Panel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildTile(context, 'Home', Iconsax.home, '/user/home', isDark),
                _buildTile(context, 'Class Routine', Iconsax.calendar_1, '/user/class-routine', isDark),
                _buildTile(context, 'Teachers', Iconsax.teacher, '/user/teachers', isDark),
                _buildTile(context, 'Notice Board', Iconsax.notification, '/user/notices', isDark),
                _buildTile(context, 'Contact Us', Iconsax.call, '/user/contact', isDark),
                _buildTile(context, 'Settings', Iconsax.setting_2, '/user/settings', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, String route, bool isDark) {
    final bool isSelected =
        ModalRoute.of(context)?.settings.name == route || currentPage == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? ITMColors.gradientStart
            : (isDark ? ITMColors.darkTextTertiary : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? ITMColors.gradientStart
              : (isDark ? ITMColors.darkTextPrimary : Colors.black),
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context); // Close drawer
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
