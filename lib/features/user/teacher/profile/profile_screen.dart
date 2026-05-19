import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itm_connect/features/user/teacher/profile/routine_screen.dart';
import 'package:itm_connect/widgets/universal_header.dart';

import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final Teacher teacher;
  const ProfileScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final name = teacher.name;
    final position = teacher.role;
    final email = teacher.email;
    final imageUrl = teacher.imageUrl;
    final teacherInitial = teacher.teacherInitial;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const UniversalHeader(title: 'Teacher Profile', showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🖼 Image with border
                  Animate(
                    effects: [FadeEffect(duration: 500.ms), ScaleEffect(duration: 400.ms)],
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade700, width: 3),
                      ),
                      child: ClipOval(
                        child: imageUrl.isNotEmpty 
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.green,
                                child: const Icon(Icons.person, size: 60, color: Colors.white),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          : Container(
                              color: Colors.green,
                              child: const Icon(Icons.person, size: 60, color: Colors.white),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 👤 Name and Position
                  Animate(
                    effects: [FadeEffect(duration: 400.ms), SlideEffect(begin: Offset(0, 0.1))],
                    child: Column(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          position,
                          style: TextStyle(fontSize: 16, color: isDark ? ITMColors.darkTextSecondary : Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 📧 Email
                  Animate(
                    effects: [FadeEffect(duration: 400.ms)],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          email,
                          style: TextStyle(fontSize: 14, color: isDark ? ITMColors.darkTextTertiary : Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📋 Additional info
                  Animate(
                    effects: [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? ITMColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? ITMColors.darkTextPrimary : Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This teacher is a highly experienced faculty member known for excellent academic delivery and student mentorship.',
                            style: TextStyle(fontSize: 14, color: isDark ? ITMColors.darkTextSecondary : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ⏰ Consulting Hours
                  if (teacher.consultingHour.isNotEmpty)
                    Animate(
                      effects: [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? ITMColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                          border: Border.all(color: Colors.amber.shade700.withOpacity(isDark ? 0.15 : 0.3), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_filled, color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Consulting Hours',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? ITMColors.darkTextPrimary : Colors.black),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...teacher.consultingHours.map((slot) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? ITMColors.darkTextPrimary : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // 🔁 View Routine Button with white icon and text
                  Animate(
                    effects: [FadeEffect(), SlideEffect(begin: Offset(0, 0.05))],
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.schedule, color: Color(0xFFFFFFFF)),
                      label: const Text(
                        'View Routine',
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineScreen(
                              teacherName: name,
                              teacherInitial: teacherInitial,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
