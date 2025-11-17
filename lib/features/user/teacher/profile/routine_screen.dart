import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:itm_connect/widgets/universal_header.dart';

class RoutineScreen extends StatefulWidget {
  final String teacherName;
  const RoutineScreen({super.key, required this.teacherName});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  String selectedDay = 'Monday';

  // ✅ Expanded dummy routine
  final Map<String, Map<String, List<String>>> dummyRoutine = {
    'John Doe': {
      'Monday': ['9:00 AM - Math (Room 201)', '11:00 AM - Physics (Lab 2)'],
      'Tuesday': ['10:00 AM - Chemistry (Room 105)', '2:00 PM - Calculus (Room 101)'],
      'Wednesday': [],
      'Thursday': ['1:00 PM - Robotics (Lab 3)'],
      'Friday': ['9:30 AM - Engineering Math (Room 304)'],
    },
    'Jane Smith': {
      'Monday': ['10:00 AM - English (Room 108)', '1:00 PM - ICT (Lab 4)'],
      'Wednesday': ['9:00 AM - Communication (Room 202)'],
    },
  };

  @override
  Widget build(BuildContext context) {
    final routineList = dummyRoutine[widget.teacherName]?[selectedDay] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          // ✅ App header
          UniversalHeader(title: '${widget.teacherName}\'s Routine', showBackButton: true),

          // ✅ Day Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: buildDaySelector(),
          ),

          // ✅ Routine List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: routineList.isEmpty
                  ? buildEmptyState()
                  : ListView.builder(
                itemCount: routineList.length,
                itemBuilder: (context, index) {
                  final classItem = routineList[index];
                  return Animate(
                    effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.05))],
                    delay: (index * 100).ms,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.green,
                          child: Icon(Iconsax.clock, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          classItem,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDaySelector() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedDay == day;

          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Animate(
              effects: const [FadeEffect(), ScaleEffect()],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade700 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  day.substring(0, 3), // "Mon", "Tue"...
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildEmptyState() {
    return Animate(
      effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No routine available for this day.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check back later or choose another day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
