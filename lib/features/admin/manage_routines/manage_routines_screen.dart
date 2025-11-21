import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  String selectedBatch = '56th';

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
        return StatefulBuilder(builder: (context, setModalState) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Teal Header
                Container(
                  padding: const EdgeInsets.all(16),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (routine != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Code: ${routine['courseCode'] ?? 'N/A'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: 450,
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
                          // Time
                          TextField(
                            controller: time,
                            decoration: InputDecoration(
                              labelText: 'Time (e.g. 8:30 AM - 10:00 AM)',
                              prefixIcon: const Icon(Icons.schedule),
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
                  padding: const EdgeInsets.all(16),
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
                                  // Check for duplicates within the existing routine
                                  final existingRoutine = await _routineService.getRoutine(docId);
                                  final existingClasses = existingRoutine?.classes ?? [];

                                  final isDuplicate = existingClasses.any((c) =>
                                      c.teacherInitial == newClass.teacherInitial &&
                                      ((routine == null) || (existingClasses.indexOf(c) != index)));

                                  if (isDuplicate) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Teacher initial already exists in this routine')),
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
    if (newBatch.isEmpty || batches.contains(newBatch)) return;
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
    // Routine list is loaded from Firestore per selected batch/day

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Card with Dropdowns
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
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
                      padding: const EdgeInsets.all(20),
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
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Routines Hub',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Create and manage class routines for all batches',
                                  style: TextStyle(
                                    fontSize: 13,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day Selection
                          const Text(
                            'Select Day',
                            style: TextStyle(
                              fontSize: 12,
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
                          const Text(
                            'Select Batch',
                            style: TextStyle(
                              fontSize: 12,
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
                              return Container(
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            // Batch Management and Routines List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Batches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 12),
                // Create Batch Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _batchController,
                        decoration: InputDecoration(
                          hintText: 'Enter new batch (e.g. 61st)',
                          prefixIcon: const Icon(Icons.add_circle_outline),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _addBatch,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Show cards for batches from Firestore
                StreamBuilder<List<String>>(
                  stream: _routineService.streamAllBatches(),
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
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
                                'No batches created yet',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.class_, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                batch,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _deleteBatch(batch),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
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
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        margin: const EdgeInsets.only(bottom: 16),
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
                              padding: const EdgeInsets.all(14),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Code: ${cls.courseCode}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Teacher',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              cls.teacherName,
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                                          style: const TextStyle(
                                            fontSize: 12,
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
                                      const Icon(Icons.location_on, size: 16, color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Room',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              cls.room,
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Time',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Text(
                                              cls.time,
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                          label: const Text(
                                            'Edit',
                                            style: TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          onPressed: () => _deleteRoutine(index),
                                          icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                          label: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.white, fontSize: 13),
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
          const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        onPressed: () => _showRoutineForm(),
      ),
    );
  }
}
