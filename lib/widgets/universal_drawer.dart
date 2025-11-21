import 'package:flutter/material.dart';

class UniversalDrawer extends StatelessWidget {
  final String currentPage;

  const UniversalDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final Color green = Colors.green.shade700;

    return Drawer(
      backgroundColor: Colors.grey.shade100, // Unified background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔄 Removed separate green background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(Icons.school, color: green, size: 28),
                const SizedBox(width: 10),
                Text(
                  'ITM Connect',
                  style: TextStyle(
                    color: green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // 📚 Navigation items
          _buildItem(context, icon: Icons.home, label: 'Home', page: 'Home', green: green),
          _buildItem(context, icon: Icons.calendar_month, label: 'Class Routine', page: 'Class Routine', green: green),
          _buildItem(context, icon: Icons.person_search, label: 'Teachers', page: 'Teachers', green: green),
          _buildItem(context, icon: Icons.notifications, label: 'Notices', page: 'Notices', green: green),
          _buildItem(context, icon: Icons.contact_mail, label: 'Contact Us', page: 'Contact', green: green),
          _buildItem(context, icon: Icons.feedback, label: 'Feedback', page: 'Feedback', green: green),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context,
      {required IconData icon,
        required String label,
        required String page,
        required Color green}) {
    final bool isSelected = currentPage == page;

    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: green),
          title: Text(
            label,
            style: TextStyle(
              color: green,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            // Replace with navigation logic as needed
            Navigator.pop(context);
          },
        ),
        const Divider(height: 0),
      ],
    );
  }
}
