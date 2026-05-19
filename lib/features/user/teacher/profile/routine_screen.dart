import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:itm_connect/widgets/universal_header.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/theme/app_colors.dart';

class RoutineScreen extends StatefulWidget {
  final String teacherName;
  final String teacherInitial;
  const RoutineScreen({super.key, required this.teacherName, required this.teacherInitial});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  String selectedDay = 'Monday';
  final RoutineService _routineService = RoutineService();

  String _getFullDayName(String shortDay) {
    final dayMap = {
      'sat': 'Saturday',
      'sun': 'Sunday',
      'mon': 'Monday',
      'tue': 'Tuesday',
      'wed': 'Wednesday',
      'thu': 'Thursday',
      'fri': 'Friday',
    };
    return dayMap[shortDay.toLowerCase().trim()] ?? shortDay;
  }

  String formatTo12Hr(String inputTime) {
    if (inputTime.isEmpty) return "";
    inputTime = inputTime.trim();
    try {
      final double? serialTime = double.tryParse(inputTime);
      if (serialTime != null) {
        int totalMinutes = (serialTime * 24 * 60).round();
        int hour = (totalMinutes ~/ 60) % 24;
        int minute = totalMinutes % 60;
        return _formatHourMinute(hour, minute);
      }
      
      // Handle 24h string like "13:00" or "8:30"
      if (!inputTime.toUpperCase().contains('AM') && !inputTime.toUpperCase().contains('PM')) {
        final bits = inputTime.split(':');
        if (bits.isNotEmpty) {
          int hour = int.tryParse(bits[0]) ?? 0;
          int minute = bits.length > 1 ? (int.tryParse(bits[1]) ?? 0) : 0;
          return _formatHourMinute(hour, minute);
        }
      }
      
      return inputTime;
    } catch (e) {
      return inputTime;
    }
  }

  String _formatHourMinute(int hour, int minute) {
    String period = "AM";
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$hour:$minuteStr $period";
  }

  String _convertTo24Hour(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return '00:00';

    if (timeStr.contains('AM') || timeStr.contains('PM')) {
      final parts = timeStr.split(RegExp(r'\s+'));
      if (parts.length < 2) return '00:00';
      final timePart = parts[0];
      final period = parts[1];
      final timeBits = timePart.split(':');
      if (timeBits.length < 1) return '00:00';
      var hour = int.tryParse(timeBits[0]) ?? 0;
      final minute = timeBits.length > 1 ? timeBits[1] : '00';
      if (period == 'PM' && hour != 12) hour += 12;
      else if (period == 'AM' && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
    }

    final bits = timeStr.split(':');
    if (bits.isEmpty) return '00:00';
    var hour = int.tryParse(bits[0]) ?? 0;
    final minute = bits.length > 1 ? bits[1] : '00';
    return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            child: StreamBuilder<List<Routine>>(
              stream: _routineService.streamAllRoutines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allRoutines = snapshot.data ?? [];
                final List<RoutineClass> routineList = [];
                
                for (final routine in allRoutines) {
                  if (_getFullDayName(routine.day) == selectedDay) {
                    for (final c in routine.classes) {
                      if (c.teacherInitial.trim().toUpperCase() == widget.teacherInitial.trim().toUpperCase()) {
                        routineList.add(c);
                      }
                    }
                  }
                }

                // Sort by time
                routineList.sort((a, b) {
                  final timeA = _convertTo24Hour(formatTo12Hr(a.time));
                  final timeB = _convertTo24Hour(formatTo12Hr(b.time));
                  return timeA.compareTo(timeB);
                });

                if (routineList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: buildEmptyState(),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: routineList.length,
                    itemBuilder: (context, index) {
                      final classItem = routineList[index];
                      final timeStr = formatTo12Hr(classItem.time);
                      
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
                              '${classItem.courseName} (${classItem.courseCode})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Iconsax.timer_1, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(timeStr, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Iconsax.location, size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text('Room: ${classItem.room}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDaySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: isSelected
                      ? Colors.green.shade700
                      : (isDark ? ITMColors.darkSurface : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  day.substring(0, 3), // "Mon", "Tue"...
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? ITMColors.darkTextSecondary : Colors.black87),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Animate(
      effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.1))],
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? ITMColors.darkCard : Colors.white,
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
