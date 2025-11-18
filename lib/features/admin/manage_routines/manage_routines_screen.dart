import 'package:flutter/material.dart';
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
  final List<String> batches = ['56th', '57th', '58th', '59th', '60th'];

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
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
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

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(routine == null ? 'Add Class' : 'Edit Class'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courseName,
                  decoration: const InputDecoration(labelText: 'Course Name'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: courseCode,
                  decoration: const InputDecoration(labelText: 'Course Code'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: teacher,
                  decoration: const InputDecoration(labelText: 'Teacher Name'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: teacherInitial,
                  decoration: const InputDecoration(labelText: 'Teacher Initial (unique)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
                TextFormField(
                  controller: room,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
                TextFormField(
                  controller: time,
                  decoration: const InputDecoration(labelText: 'Time (e.g. 8:30 AM - 10:00 AM)'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final newClass = RoutineClass(
                courseName: courseName.text.trim(),
                courseCode: courseCode.text.trim(),
                teacherName: teacher.text.trim(),
                teacherInitial: teacherInitial.text.trim(),
                room: room.text.trim(),
                time: time.text.trim(),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teacher initial already exists in this routine')),
                  );
                  return;
                }

                if (routine == null) {
                  await _routineService.addClass(docId, newClass);
                } else {
                  // update by index
                  await _routineService.updateClass(docId, index!, newClass);
                }

                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
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

    setState(() {
      batches.add(newBatch);
    });
    _batchController.clear();
  }

  void _deleteBatch(String batch) {
    if (batches.length <= 1) return;

    setState(() {
      batches.remove(batch);
      if (selectedBatch == batch) {
        selectedBatch = batches.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Routine list is loaded from Firestore per selected batch/day

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedDay,
                  onChanged: (val) => setState(() => selectedDay = val!),
                  items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedBatch,
                  onChanged: (val) => setState(() => selectedBatch = val!),
                  items: batches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Manage Batches", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _batchController,
                        decoration: InputDecoration(
                          hintText: 'Enter new batch (e.g. 61st)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addBatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: batches.map((batch) {
                    return Chip(
                      label: Text(batch),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _deleteBatch(batch),
                      backgroundColor: Colors.grey.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
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
                  final classes = routineDoc?.classes ?? [];

                  if (classes.isEmpty) {
                    return const Center(child: Text('No routine found for this day and batch.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: classes.length,
                    itemBuilder: (_, index) {
                      final cls = classes[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(cls.courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Code: ${cls.courseCode}'),
                              Text('Teacher: ${cls.teacherName}'),
                              Text('Initial: ${cls.teacherInitial}'),
                              Text('Room: ${cls.room}'),
                              Text('Time: ${cls.time}'),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _showRoutineForm(routine: {
                                  'courseName': cls.courseName,
                                  'courseCode': cls.courseCode,
                                  'teacher': cls.teacherName,
                                  'teacherInitial': cls.teacherInitial,
                                  'room': cls.room,
                                  'time': cls.time,
                                }, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRoutine(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
        onPressed: () => _showRoutineForm(),
      ),
    );
  }
}
