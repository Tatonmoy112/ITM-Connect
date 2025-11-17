import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class UserDrawer extends StatelessWidget {
  final String currentPage;

  const UserDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/itm_logo.png',
                  width: 48,
                  height: 48,
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
                _buildTile(context, 'Home', Iconsax.home, '/user/home'),
                _buildTile(context, 'Class Routine', Iconsax.calendar_1, '/user/class-routine'),
                _buildTile(context, 'Teachers', Iconsax.teacher, '/user/teachers'),
                _buildTile(context, 'Notice Board', Iconsax.notification, '/user/notices'),
                _buildTile(context, 'Contact Us', Iconsax.call, '/user/contact'),
                _buildTile(context, 'Feedback', Iconsax.message_question, '/user/feedback'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, String route) {
    final bool isSelected =
        ModalRoute.of(context)?.settings.name == route || currentPage == title;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green.shade700 : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.green.shade700 : Colors.black,
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
