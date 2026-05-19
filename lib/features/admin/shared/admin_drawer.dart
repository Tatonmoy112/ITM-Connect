import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final String currentPage;
  const AdminDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFEAF8EF),
      width: 230,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Logo + App Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.school, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  'ITM Connect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 🔝 Dashboard on top
          _buildDrawerItem(
            context,
            label: 'Dashboard',
            icon: Icons.dashboard,
            targetPage: 'dashboard',
          ),
          const Divider(),

          // 👇 Management buttons after
          _buildDrawerItem(
            context,
            label: 'Manage Routines',
            icon: Icons.calendar_month,
            targetPage: 'routines',
          ),
          _buildDrawerItem(
            context,
            label: 'Manage Teachers',
            icon: Icons.people,
            targetPage: 'teachers',
          ),
          _buildDrawerItem(
            context,
            label: 'Manage Notices',
            icon: Icons.feed,
            targetPage: 'notices',
          ),
        ],
      ),
    );
  }

  // 🔹 Drawer Item Builder with pushReplacementNamed
  Widget _buildDrawerItem(
      BuildContext context, {
        required String label,
        required IconData icon,
        required String targetPage,
      }) {
    final bool isSelected = currentPage == targetPage;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.black54,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, '/$targetPage');
        } else {
          Navigator.pop(context); // Just close drawer
        }
      },
    );
  }
}


