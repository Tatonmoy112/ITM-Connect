import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/theme/app_colors.dart';

/// A reusable dialog that shows the user's class notification schedule.
/// Fetches routines from Firebase "routines" collection and displays:
///  - Which days they have classes
///  - How many classes per day
///  - At what time each notification will fire (10 min before class)
class NotificationScheduleDialog extends StatefulWidget {
  /// If provided, uses these values. Otherwise reads from SharedPreferences.
  final String? role;
  final String? identifier;

  const NotificationScheduleDialog({
    super.key,
    this.role,
    this.identifier,
  });

  /// Show this dialog from any screen
  static Future<void> show(BuildContext context,
      {String? role, String? identifier}) {
    return showDialog(
      context: context,
      builder: (_) => NotificationScheduleDialog(
        role: role,
        identifier: identifier,
      ),
    );
  }

  @override
  State<NotificationScheduleDialog> createState() =>
      _NotificationScheduleDialogState();
}

class _NotificationScheduleDialogState
    extends State<NotificationScheduleDialog> {
  bool _isLoading = true;
  String _role = '';
  String _identifier = '';
  Map<String, List<_ScheduleEntry>> _scheduleByDay = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      // Get role and identifier
      String role = widget.role ?? '';
      String identifier = widget.identifier ?? '';

      if (role.isEmpty || identifier.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        role = prefs.getString('user_role') ?? '';
        identifier = prefs.getString('user_identifier') ?? '';
      }

      if (role.isEmpty || identifier.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No role or batch/initial set up yet. Please set your status first.';
        });
        return;
      }

      _role = role;
      _identifier = identifier;

      // Fetch routines from Firebase
      final routineService = RoutineService();
      final allRoutines = await routineService.streamAllRoutines().first;

      // Filter relevant routines
      final Map<String, List<_ScheduleEntry>> scheduleByDay = {};

      final dayOrder = [
        'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
      ];

      for (var routine in allRoutines) {
        for (var routineClass in routine.classes) {
          bool isRelevant = false;

          if (role == 'Student') {
            isRelevant =
                routine.batch.toUpperCase() == identifier.toUpperCase();
          } else if (role == 'Teacher') {
            isRelevant = routineClass.teacherInitial.toUpperCase() ==
                identifier.toUpperCase();
          }

          if (isRelevant) {
            final day = _getFullDayName(routine.day);
            final parts = routineClass.time.split('-');
            String startTimeStr = parts.isNotEmpty ? parts[0].trim() : '';
            String endTimeStr = parts.length > 1 ? parts[1].trim() : '';

            // Parse the start time
            final parsedStart = _parseTimeFlexible(startTimeStr);
            final parsedEnd = _parseTimeFlexible(endTimeStr);

            String formattedTime = routineClass.time;
            String notificationTime = '';

            if (parsedStart != null) {
              final startFormatted = DateFormat('h:mm a').format(parsedStart);
              final endFormatted = parsedEnd != null
                  ? DateFormat('h:mm a').format(parsedEnd)
                  : '';
              formattedTime = endFormatted.isNotEmpty
                  ? '$startFormatted - $endFormatted'
                  : startFormatted;

              // Notification fires 10 min before
              final notifTime =
                  parsedStart.subtract(const Duration(minutes: 10));
              notificationTime = DateFormat('h:mm a').format(notifTime);
            }

            final entry = _ScheduleEntry(
              courseName: routineClass.courseName,
              courseCode: routineClass.courseCode,
              room: routineClass.room,
              time: formattedTime,
              notificationTime: notificationTime,
              teacherInitial: routineClass.teacherInitial,
              batch: routine.batch,
            );

            scheduleByDay.putIfAbsent(day, () => []);
            scheduleByDay[day]!.add(entry);
          }
        }
      }

      // Sort entries within each day by time
      for (var entries in scheduleByDay.values) {
        entries.sort((a, b) => a.time.compareTo(b.time));
      }

      // Sort days by predefined order
      final sortedSchedule = <String, List<_ScheduleEntry>>{};
      for (var day in dayOrder) {
        if (scheduleByDay.containsKey(day)) {
          sortedSchedule[day] = scheduleByDay[day]!;
        }
      }

      setState(() {
        _scheduleByDay = sortedSchedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not load schedule. Please check your internet connection.';
      });
      debugPrint('Error loading schedule: $e');
    }
  }

  DateTime? _parseTimeFlexible(String timeStr) {
    timeStr = timeStr.trim();
    if (timeStr.isEmpty) return null;

    // Try "hh:mm a"
    try {
      return DateFormat('hh:mm a').parse(timeStr);
    } catch (_) {}
    try {
      return DateFormat('h:mm a').parse(timeStr);
    } catch (_) {}

    // Try serial number
    final serial = double.tryParse(timeStr);
    if (serial != null && serial >= 0 && serial <= 1) {
      int totalMinutes = (serial * 24 * 60).round();
      int hour = (totalMinutes ~/ 60) % 24;
      int minute = totalMinutes % 60;
      return DateTime(2000, 1, 1, hour, minute);
    }

    // Try 24h
    try {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        int hour = int.parse(parts[0].trim());
        int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return DateTime(2000, 1, 1, hour, minute);
        }
      }
    } catch (_) {}

    return null;
  }

  String _getFullDayName(String shortDay) {
    final dayMap = {
      'sat': 'Saturday',
      'sun': 'Sunday',
      'mon': 'Monday',
      'tue': 'Tuesday',
      'wed': 'Wednesday',
      'thu': 'Thursday',
      'fri': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
    };
    return dayMap[shortDay.toLowerCase().trim()] ?? shortDay;
  }

  int get _totalClasses {
    int total = 0;
    for (var entries in _scheduleByDay.values) {
      total += entries.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? ITMColors.darkCard : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              decoration: BoxDecoration(
                gradient: ITMColors.brandGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Notification Schedule',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!_isLoading && _error == null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _role == 'Student'
                                ? 'Batch $_identifier • $_totalClasses classes'
                                : '$_identifier • $_totalClasses classes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your schedule...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? ITMColors.darkTextSecondary
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (_scheduleByDay.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No classes found for your ${_role == 'Student' ? 'batch' : 'initial'}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? ITMColors.darkTextSecondary
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ITMColors.info.withOpacity(isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ITMColors.info.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.alarm_rounded,
                                color: ITMColors.info, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You\'ll get a notification 10 minutes before each class.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? ITMColors.darkTextSecondary
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Day-wise schedule
                      ..._scheduleByDay.entries.map((entry) =>
                          _buildDaySection(entry.key, entry.value, isDark)),
                    ],
                  ),
                ),
              ),

            // ── Footer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ITMColors.gradientStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
      String day, List<_ScheduleEntry> entries, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: ITMColors.brandGradientHorizontal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entries.length} ${entries.length == 1 ? 'class' : 'classes'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ITMColors.darkTextTertiary
                      : ITMColors.lightTextTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Class cards
          ...entries.map((entry) => _buildClassCard(entry, isDark)),
        ],
      ),
    );
  }

  Widget _buildClassCard(_ScheduleEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ITMColors.darkSurface
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ITMColors.darkCardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name
          Text(
            entry.courseCode.isNotEmpty
                ? '${entry.courseName} (${entry.courseCode})'
                : entry.courseName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? ITMColors.darkTextPrimary : ITMColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          // Time and Room row
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: ITMColors.info),
              const SizedBox(width: 4),
              Text(
                entry.time,
                style: TextStyle(
                  fontSize: 12,
                  color: ITMColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              if (entry.room.isNotEmpty) ...[
                Icon(Icons.location_on_rounded,
                    size: 14, color: ITMColors.accentOrange),
                const SizedBox(width: 4),
                Text(
                  entry.room,
                  style: TextStyle(
                    fontSize: 12,
                    color: ITMColors.accentOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          // Notification time
          if (entry.notificationTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.notifications_rounded,
                    size: 14, color: ITMColors.success),
                const SizedBox(width: 4),
                Text(
                  'Notif at ${entry.notificationTime}',
                  style: TextStyle(
                    fontSize: 11,
                    color: ITMColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          // Show batch for teacher or teacher initial for student
          if (_role == 'Teacher' && entry.batch.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.group_rounded,
                    size: 14,
                    color: isDark
                        ? ITMColors.darkTextTertiary
                        : ITMColors.lightTextTertiary),
                const SizedBox(width: 4),
                Text(
                  'Batch ${entry.batch}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? ITMColors.darkTextTertiary
                        : ITMColors.lightTextTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (_role == 'Student' && entry.teacherInitial.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 14,
                    color: isDark
                        ? ITMColors.darkTextTertiary
                        : ITMColors.lightTextTertiary),
                const SizedBox(width: 4),
                Text(
                  entry.teacherInitial,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? ITMColors.darkTextTertiary
                        : ITMColors.lightTextTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleEntry {
  final String courseName;
  final String courseCode;
  final String room;
  final String time;
  final String notificationTime;
  final String teacherInitial;
  final String batch;

  _ScheduleEntry({
    required this.courseName,
    required this.courseCode,
    required this.room,
    required this.time,
    required this.notificationTime,
    required this.teacherInitial,
    required this.batch,
  });
}
