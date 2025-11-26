import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';

class ManageRoutineScreen extends StatefulWidget {
  const ManageRoutineScreen({super.key});

  @override
  State<ManageRoutineScreen> createState() => _ManageRoutineScreenState();
}

class _ManageRoutineScreenState extends State<ManageRoutineScreen>
    with SingleTickerProviderStateMixin {
  final List<String> days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
  // batches will be loaded from Firestore; start empty
  List<String> batches = [];

  String selectedDay = 'Sunday';
  String selectedBatch = '';  // No default batch selection
  bool showDeleteBatchSection = false;  // Show/hide delete batch section

  final RoutineService _routineService = RoutineService();

  final TextEditingController _batchController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Auto-select today's day (excluding Friday)
    final today = DateTime.now().weekday; // 1 = Monday, ..., 7 = Sunday
    final weekMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Saturday',  // Skipping Friday
      6: 'Saturday',
      7: 'Sunday'
    };
    final todayName = weekMap[today] ?? 'Sunday';
    if (days.contains(todayName)) {
      selectedDay = todayName;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  /// Parse time string like "10:00 AM - 11:30 AM" and return [startMinutes, endMinutes]
  /// Returns null if parsing fails
  List<int>? _parseTimeRange(String timeStr) {
    try {
      final parts = timeStr.split('-');
      if (parts.length != 2) return null;
      
      final startStr = parts[0].trim();
      final endStr = parts[1].trim();
      
      // Parse "10:00 AM" format using DateFormat
      final dateFormat = DateFormat('hh:mm a');
      final startTime = dateFormat.parse(startStr);
      final endTime = dateFormat.parse(endStr);
      
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      return [startMinutes, endMinutes];
    } catch (e) {
      return null;
    }
  }

  /// Parse time string like "10:00 AM" and return minutes since midnight
  /// Returns null if parsing fails
  int? _parseTime(String timeStr) {
    try {
      final dateFormat = DateFormat('hh:mm a');
      final time = dateFormat.parse(timeStr);
      return time.hour * 60 + time.minute;
    } catch (e) {
      return null;
    }
  }

  /// Check if two time ranges overlap
  /// timeRange1 and timeRange2 are [startMinutes, endMinutes]
  /// Check if a teacher has a time conflict across ALL routines on the SAME DAY
  /// Returns a conflict message if found, null if no conflict
  Future<String?> _checkGlobalTimeConflict(
    String teacherInitial,
    String timeRange,
    String day,  // The day to check conflicts for
    {String? excludeDocId}  // Document ID to exclude (for edit case)
  ) async {
    try {
      final newTimeRange = _parseTimeRange(timeRange);
      if (newTimeRange == null) return null;

      // Get all routines from Firestore using a query
      final querySnapshot = await FirebaseFirestore.instance
          .collection('routines')
          .get();

      // Check each routine for conflicts
      for (final doc in querySnapshot.docs) {
        final routine = Routine.fromMap(doc.id, doc.data());
        
        // Skip the current routine being edited
        if (excludeDocId != null && routine.id == excludeDocId) continue;

        // Only check routines for the same day
        if (routine.day != day) continue;

        // Check each class in this routine
        for (final routineClass in routine.classes) {
          if (routineClass.teacherInitial == teacherInitial) {
            final existingTimeRange = _parseTimeRange(routineClass.time);

            if (existingTimeRange != null && _timesOverlap(newTimeRange, existingTimeRange)) {
              return '${teacherInitial} already has a class on ${routine.day} from ${routineClass.time}';
            }
          }
        }
      }

      return null;  // No conflict found
    } catch (e) {
      print('Error checking global time conflict: $e');
      return null;
    }
  }

  bool _timesOverlap(List<int> timeRange1, List<int> timeRange2) {
    final start1 = timeRange1[0];
    final end1 = timeRange1[1];
    final start2 = timeRange2[0];
    final end2 = timeRange2[1];
    
    // Two ranges overlap if one starts before the other ends
    return start1 < end2 && start2 < end1;
  }

  /// Initialize and show time range picker dialog
  /// Returns formatted time string like "10:00 AM - 11:30 AM" or null if cancelled
  Future<String?> showTimeRangePicker(BuildContext context) async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // Show start time picker
    startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (startTime == null) return null;

    // Show end time picker
    endTime = await showTimePicker(
      context: context,
      initialTime: startTime.replacing(hour: (startTime.hour + 1) % 24),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (endTime == null) return null;

    // Format times to "HH:MM AM/PM" format
    final startFormatted = startTime.format(context);
    final endFormatted = endTime.format(context);

    return '$startFormatted - $endFormatted';
  }

  /// Validates input to prevent SQL injection and malicious code
  /// Allows: Letters, numbers, spaces, hyphens, underscores, dots
  bool _isValidInput(String input) {
    if (input.isEmpty) return true; // Empty is handled elsewhere
    
    final inputLower = input.toLowerCase();
    
    // SQL injection keywords
    final sqlKeywords = [
      'select', 'insert', 'update', 'delete', 'drop', 'create',
      'alter', 'exec', 'execute', 'union', '--', 'xp_', 'sp_',
      'script', 'javascript', 'onerror', 'onclick'
    ];
    
    for (final keyword in sqlKeywords) {
      if (inputLower.contains(keyword)) return false;
    }
    
    // Dangerous characters
    final dangerousChars = ['\'', '"', ';', '\\', '<', '>', '`', '{', '}', '[', ']', '(', ')'];
    for (final char in dangerousChars) {
      if (input.contains(char)) return false;
    }
    
    return true;
  }

  void _showRoutineForm({Map<String, String>? routine, int? index}) {
    // New implementation: save to Firestore under document id: {batch}_{day}
    final courseName = TextEditingController(text: routine?['courseName']);
    final courseCode = TextEditingController(text: routine?['courseCode']);
    final teacher = TextEditingController(text: routine?['teacher']);
    final room = TextEditingController(text: routine?['room']);
    final time = TextEditingController(text: routine?['time']);
    final teacherInitial = TextEditingController(text: routine?['teacherInitial']);

    bool showCourseNameError = false;
    bool showCourseCodeError = false;
    bool showTeacherError = false;
    bool showTeacherInitialError = false;
    bool showRoomError = false;
    bool showTimeError = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) {
        final size = MediaQuery.of(context).size;
        final dialogIsMobile = size.width < 600;
        final dialogMaxWidth = dialogIsMobile ? size.width - 32 : 500.0;
        final dlgPadding = dialogIsMobile ? 16.0 : 20.0;
        final maxDialogHeight = size.height * 0.9;

        return StatefulBuilder(builder: (context, setModalState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: maxDialogHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Teal Header
                  Container(
                    padding: EdgeInsets.all(dlgPadding),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routine == null ? 'Add Class' : 'Edit Class',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: dialogIsMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (routine != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Code: ${routine['courseCode'] ?? 'N/A'}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: dialogIsMobile ? 12 : 14,
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Form Content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(dlgPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Course Name
                            TextField(
                              controller: courseName,
                              decoration: InputDecoration(
                                labelText: 'Course Name',
                                prefixIcon: const Icon(Icons.book),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showCourseNameError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Course Code
                            TextField(
                              controller: courseCode,
                              decoration: InputDecoration(
                                labelText: 'Course Code',
                                prefixIcon: const Icon(Icons.code),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showCourseCodeError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Teacher Name
                            TextField(
                              controller: teacher,
                              decoration: InputDecoration(
                                labelText: 'Teacher Name',
                                prefixIcon: const Icon(Icons.person),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showTeacherError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Teacher Initial
                            TextField(
                              controller: teacherInitial,
                              decoration: InputDecoration(
                                labelText: 'Teacher Initial',
                                prefixIcon: const Icon(Icons.badge),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showTeacherInitialError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Room
                            TextField(
                              controller: room,
                              decoration: InputDecoration(
                                labelText: 'Room Number',
                                prefixIcon: const Icon(Icons.location_on),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showRoomError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Time with Clock Icon
                            TextField(
                              controller: time,
                              readOnly: true,
                              onTap: () async {
                                final selectedTime = await showTimeRangePicker(context);
                                if (selectedTime != null) {
                                  setModalState(() {
                                    time.text = selectedTime;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Time (Click to Select)',
                                prefixIcon: const Icon(Icons.schedule),
                                suffixIcon: const Icon(Icons.access_time, color: Colors.teal),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showTimeError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Buttons Footer
                  Container(
                    padding: EdgeInsets.all(dlgPadding),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final cName = courseName.text.trim();
                                  final cCode = courseCode.text.trim();
                                  final tName = teacher.text.trim();
                                  final tInitial = teacherInitial.text.trim().toUpperCase();
                                  final rRoom = room.text.trim();
                                  final tTime = time.text.trim();

                                  setModalState(() {
                                    showCourseNameError = cName.isEmpty;
                                    showCourseCodeError = cCode.isEmpty;
                                    showTeacherError = tName.isEmpty;
                                    showTeacherInitialError = tInitial.isEmpty;
                                    showRoomError = rRoom.isEmpty;
                                    showTimeError = tTime.isEmpty;
                                  });

                                  if (showCourseNameError ||
                                      showCourseCodeError ||
                                      showTeacherError ||
                                      showTeacherInitialError ||
                                      showRoomError ||
                                      showTimeError) {
                                    // Show error dialog if any required field is empty
                                    List<String> missingFields = [];
                                    if (showCourseNameError) missingFields.add('Course Name');
                                    if (showCourseCodeError) missingFields.add('Course Code');
                                    if (showTeacherError) missingFields.add('Teacher Name');
                                    if (showTeacherInitialError) missingFields.add('Teacher Initial');
                                    if (showRoomError) missingFields.add('Room Number');
                                    if (showTimeError) missingFields.add('Time');

                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            '⚠️ Missing Required Fields',
                                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Please fill in all required fields:',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 12),
                                              ...missingFields.map((field) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      field,
                                                      style: const TextStyle(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Fix Fields', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  // Validate input for malicious code
                                  if (!_isValidInput(cName) || !_isValidInput(cCode) || 
                                      !_isValidInput(tName) || !_isValidInput(tInitial) || 
                                      !_isValidInput(rRoom)) {
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Invalid Input'),
                                          content: const Text('Input contains invalid characters or SQL keywords. Please use only letters, numbers, spaces, hyphens, underscores, and dots.'),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('OK', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  setModalState(() => isLoading = true);

                                  final newClass = RoutineClass(
                                    courseName: cName,
                                    courseCode: cCode,
                                    teacherName: tName,
                                    teacherInitial: tInitial,
                                    room: rRoom,
                                    time: tTime,
                                  );

                                  final docId = _docId();

                                  try {
                                    // Check for time conflicts for the same teacher
                                    final existingRoutine = await _routineService.getRoutine(docId);
                                    final existingClasses = existingRoutine?.classes ?? [];

                                    // Parse the new class time
                                    final newTimeRange = _parseTimeRange(newClass.time);
                                    
                                    if (newTimeRange == null) {
                                      if (mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Invalid Time Format'),
                                            content: const Text('Please use format: HH:MM AM/PM - HH:MM AM/PM\nExample: 10:00 AM - 11:30 AM'),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      setModalState(() => isLoading = false);
                                      return;
                                    }

                                    // Check if this exact class (same time, course code) already exists for this batch/day (prevent duplicates)
                                    for (int i = 0; i < existingClasses.length; i++) {
                                      final existingClass = existingClasses[i];
                                      
                                      // When adding new class (routine == null), check all existing classes
                                      // When editing (routine != null), skip checking itself (at index position)
                                      if (routine == null || i != index) {
                                        final existingTimeRange = _parseTimeRange(existingClass.time);
                                        
                                        if (existingTimeRange != null && _timesOverlap(newTimeRange, existingTimeRange)) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Class Already Exists'),
                                                content: Text(
                                                  'A class with overlapping time (${existingClass.time}) already exists for batch $selectedBatch on $selectedDay.\n\n'
                                                  'Course: ${existingClass.courseName}\n'
                                                  'Teacher: ${existingClass.teacherInitial}',
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Understood', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          setModalState(() => isLoading = false);
                                          return;
                                        }
                                      }
                                    }

                                    // Check if this teacher has any time conflicts within this routine
                                    for (int i = 0; i < existingClasses.length; i++) {
                                      final existingClass = existingClasses[i];
                                      
                                      // Only check if it's the same teacher and different position (for edit case)
                                      if (existingClass.teacherInitial == newClass.teacherInitial && i != index) {
                                        final existingTimeRange = _parseTimeRange(existingClass.time);
                                        
                                        if (existingTimeRange != null && _timesOverlap(newTimeRange, existingTimeRange)) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Teacher Time Conflict'),
                                                content: Text(
                                                  '${newClass.teacherInitial} already has a class from ${existingClass.time} on this day.',
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Understood', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          setModalState(() => isLoading = false);
                                          return;
                                        }
                                      }
                                    }

                                    // Check for GLOBAL time conflicts (across all routines/batches/days)
                                    final globalConflictMsg = await _checkGlobalTimeConflict(
                                      newClass.teacherInitial,
                                      newClass.time,
                                      selectedDay,  // Pass the day to only check conflicts on the same day
                                      excludeDocId: routine == null ? null : docId,
                                    );

                                    if (globalConflictMsg != null) {
                                      if (mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Time Conflict - Cannot Add Class'),
                                            content: Text(globalConflictMsg),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('OK', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      setModalState(() => isLoading = false);
                                      return;
                                    }

                                    if (routine == null) {
                                      await _routineService.addClass(docId, newClass);
                                    } else {
                                      // update by index
                                      await _routineService.updateClass(docId, index!, newClass);
                                    }

                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(routine == null ? 'Class added successfully' : 'Class updated successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() => isLoading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  routine == null ? 'Add Class' : 'Save',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _deleteRoutine(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class from the routine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final docId = _docId();
              try {
                await _routineService.deleteClass(docId, index);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper: map full day name to short code used in document id (Sat, Sun, Mon, Tue, Wed, Thu)
  String _shortDay(String day) {
    switch (day) {
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      default:
        return day.substring(0, 3);
    }
  }

  String _docId() {
    // Document ID format: {batch}_{dayShort} e.g. "56th_Sat"
    return '${selectedBatch}_${_shortDay(selectedDay)}';
  }

  void _addBatch() {
    final newBatch = _batchController.text.trim();
    
    // Validate: check if batch is empty or already exists
    if (newBatch.isEmpty || batches.contains(newBatch)) {
      if (mounted && newBatch.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This batch already exists!')),
        );
      }
      return;
    }
    
    // Validate: check if batch contains only digits
    if (!RegExp(r'^\d+$').hasMatch(newBatch)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch must contain only numbers (e.g., 61, not 61st)')),
        );
      }
      return;
    }
    
    final docId = '${newBatch}_${_shortDay(selectedDay)}';
    _routineService.createEmptyRoutine(docId, newBatch, selectedDay).then((_) {
      _batchController.clear();
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating batch: ${e.toString()}')));
      }
    });
  }

  void _deleteBatch(String batch) {
    // delete all routine documents for this batch from Firestore
    _routineService.deleteBatch(batch).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch removed from Firestore')));
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting batch: ${e.toString()}')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final headerPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final cardMargin = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final contentPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Card with Dropdowns
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, 0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Teal Header Section
                      Container(
                        padding: EdgeInsets.all(headerPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.teal.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon Badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: isMobile ? 24 : 32,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Routines Hub',
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create and manage class routines for all batches',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dropdowns Section
                      Padding(
                        padding: EdgeInsets.all(headerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Selection
                            Text(
                              'Select Day',
                              style: TextStyle(
                                fontSize: subtitleFontSize - 1,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                underline: const SizedBox(),
                                value: selectedDay,
                                onChanged: (val) {
                                  if (val == null) return;
                                  setState(() => selectedDay = val);
                                },
                                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Batch Selection
                            Text(
                              'Select Batch',
                              style: TextStyle(
                                fontSize: subtitleFontSize - 1,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<String>>(
                              stream: _routineService.streamAllBatches(),
                              builder: (context, snapshot) {
                                final batchList = snapshot.data ?? [];
                                return Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        value: batchList.contains(selectedBatch) ? selectedBatch : null,
                                        hint: const Text('Select batch'),
                                        onChanged: (val) {
                                          if (val == null) return;
                                          setState(() => selectedBatch = val);
                                        },
                                        items: batchList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                      ),
                                    ),
                                    // Clear Batch Button - Show only when batch is selected
                                    if (selectedBatch.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              selectedBatch = '';
                                              showDeleteBatchSection = false;
                                            });
                                          },
                                          icon: const Icon(Icons.clear, size: 18),
                                          label: const Text('Clear Batch'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red.shade600,
                                            side: BorderSide(color: Colors.red.shade400),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            // Batch Management and Routines List
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, 0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show entire Manage Batches section only when no batch is selected
                      if (selectedBatch.isEmpty) ...[
                        Text(
                          'Manage Batches',
                          style: TextStyle(
                            fontSize: headerFontSize - 4,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Create Batch Section - Always on one line
                        Row(
                          children: [
                            Flexible(
                              flex: 3,
                              child: TextField(
                                controller: _batchController,
                                decoration: InputDecoration(
                                  hintText: 'Enter new batch (e.g. 61)',
                                  prefixIcon: const Icon(Icons.add_circle_outline),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: contentPadding - 4),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                style: TextStyle(fontSize: subtitleFontSize),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            SizedBox(width: headerPadding),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _addBatch,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Create'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: headerPadding + 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Delete Batch Section Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                showDeleteBatchSection = !showDeleteBatchSection;
                            });
                          },
                          icon: Icon(showDeleteBatchSection ? Icons.expand_less : Icons.expand_more, size: 20),
                          label: Text(
                            showDeleteBatchSection ? 'Hide Delete Batch' : 'Delete Batch',
                            style: const TextStyle(fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      // Show delete batch options when section is expanded
                      if (showDeleteBatchSection) ...[
                        const SizedBox(height: 12),
                        StreamBuilder<List<String>>(
                          stream: _routineService.streamAllBatches(),
                          builder: (context, snap) {
                            final list = snap.data ?? [];
                            if (list.isEmpty) {
                              return Container(
                                padding: EdgeInsets.all(contentPadding),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No batches to delete',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontSize: subtitleFontSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: list.map((batch) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red.shade200, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.class_, color: Colors.red.shade600, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        batch,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () => _deleteBatch(batch),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: StreamBuilder<Routine?>(
                      stream: _routineService.streamRoutine(_docId()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final routineDoc = snapshot.data;
                        // Continuous sync: keep selectedBatch in sync with Firestore
                        if (routineDoc != null) {
                          final fbBatch = routineDoc.batch.trim();
                          if (fbBatch.isNotEmpty && fbBatch != selectedBatch) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() {
                                if (!batches.contains(fbBatch)) {
                                  batches.insert(0, fbBatch);
                                }
                                selectedBatch = fbBatch;
                              });
                            });
                          }
                        }
                        final classes = routineDoc?.classes ?? [];

                        if (classes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No routine found for this day and batch.')),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(0),
                          itemCount: classes.length,
                          itemBuilder: (_, index) {
                            final cls = classes[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.only(bottom: cardMargin),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Teal Header
                                  Container(
                                    padding: EdgeInsets.all(contentPadding),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cls.courseName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isMobile ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Code: ${cls.courseCode}',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: isMobile ? 11 : 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cls.courseCode,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isMobile ? 11 : 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: EdgeInsets.all(contentPadding),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: isMobile ? 14 : 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Teacher',
                                                    style: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.grey),
                                                  ),
                                                  Text(
                                                    cls.teacherName,
                                                    style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.black87),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                cls.teacherInitial,
                                                style: TextStyle(
                                                  fontSize: isMobile ? 11 : 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: isMobile ? 14 : 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Room',
                                                    style: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.grey),
                                                  ),
                                                  Text(
                                                    cls.room,
                                                    style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Time',
                                                    style: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.grey),
                                                  ),
                                                  Text(
                                                    cls.time,
                                                    style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.black87),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            SizedBox(
                                              height: isMobile ? 32 : 36,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                                onPressed: () => _showRoutineForm(routine: {
                                                  'courseName': cls.courseName,
                                                  'courseCode': cls.courseCode,
                                                  'teacher': cls.teacherName,
                                                  'teacherInitial': cls.teacherInitial,
                                                  'room': cls.room,
                                                  'time': cls.time,
                                                }, index: index),
                                                icon: Icon(Icons.edit, size: isMobile ? 16 : 18, color: Colors.white),
                                                label: Text(
                                                  'Edit',
                                                  style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              height: isMobile ? 32 : 36,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                                onPressed: () => _deleteRoutine(index),
                                                icon: Icon(Icons.delete, size: isMobile ? 16 : 18, color: Colors.white),
                                                label: Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: selectedBatch.isEmpty ? Colors.grey.shade400 : Colors.teal.shade600,
        foregroundColor: Colors.white,
        onPressed: selectedBatch.isEmpty ? null : () => _showRoutineForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
