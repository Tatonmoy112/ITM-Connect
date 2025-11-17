import 'package:flutter/material.dart';
import 'package:itm_connect/features/user/home/user_home_screen.dart';
import 'package:itm_connect/features/user/class_routine/class_routine_screen.dart';
import 'package:itm_connect/features/user/teacher/list/teacher_list_screen.dart';
import 'package:itm_connect/features/user/notice/notice_board_screen.dart';
import 'package:itm_connect/features/user/contact/contact_us_screen.dart';
import 'package:itm_connect/features/user/feedback/feedback_screen.dart';

class UserDrawer extends StatelessWidget {
  final String currentPage;
  const UserDrawer({super.key, required this.currentPage});

  Widget buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(color: Colors.black12),
        ),
        color: selected ? Colors.green.shade100 : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.green : Colors.black87),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.green.shade800 : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.green.shade50,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: const [
                Icon(Icons.school, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'ITM Connect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          buildDrawerTile(
            icon: Icons.home,
            title: 'Home',
            selected: currentPage == 'Home',
            onTap: () {
              if (currentPage != 'Home') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const UserHomeScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
          buildDrawerTile(
            icon: Icons.calendar_today,
            title: 'Class Routine',
            selected: currentPage == 'Class Routine',
            onTap: () {
              if (currentPage != 'Class Routine') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ClassRoutineScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
          buildDrawerTile(
            icon: Icons.person,
            title: 'Teachers',
            selected: currentPage == 'Teachers',
            onTap: () {
              if (currentPage != 'Teachers') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const TeacherListScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
          buildDrawerTile(
            icon: Icons.notifications,
            title: 'Notice Board',
            selected: currentPage == 'Notice Board',
            onTap: () {
              if (currentPage != 'Notice Board') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const NoticeBoardScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
          buildDrawerTile(
            icon: Icons.contact_mail,
            title: 'Contact Us',
            selected: currentPage == 'Contact Us',
            onTap: () {
              if (currentPage != 'Contact Us') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
          buildDrawerTile(
            icon: Icons.feedback,
            title: 'Feedback',
            selected: currentPage == 'Feedback',
            onTap: () {
              if (currentPage != 'Feedback') {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()));
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
