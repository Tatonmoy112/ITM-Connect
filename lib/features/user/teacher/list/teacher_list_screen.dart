import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final TeacherService _teacherService = TeacherService();

  // State
  int? _selectedIndex;
    int? _showDailyRoutineIndex;
    String _selectedDay = DateTime.now().weekday == DateTime.sunday
      ? 'Sunday'
      : DateTime.now().weekday == DateTime.monday
        ? 'Monday'
        : DateTime.now().weekday == DateTime.tuesday
          ? 'Tuesday'
          : DateTime.now().weekday == DateTime.wednesday
            ? 'Wednesday'
            : DateTime.now().weekday == DateTime.thursday
              ? 'Thursday'
              : DateTime.now().weekday == DateTime.friday
                ? 'Friday'
                : 'Saturday';
    final RoutineService _routineService = RoutineService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    final nameParts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (nameParts.isEmpty) return '';
    // Take the first letter of EACH word (not just first and last)
    String initials = '';
    for (final part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.toUpperCase();
  }

  // Ranking helper removed; teacher ordering handled by Firestore or client-side sorting when needed.

  @override
  void initState() {
    super.initState();
    // No local mock data to sort — teachers are loaded from Firestore in real-time.
    // Keep selected indices null by default.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // PDF generation and per-teacher routine export were removed because
  // this screen now uses Firestore for teachers and routines are stored
  // in the separate `routines` collection. PDF export can be added later.

  // Generate and save PDF for teacher's routine (current day format like class routine)
  Future<void> _generateTeacherPDF(Teacher teacher) async {
    try {
      final pdf = pw.Document();
      final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

      final image = pw.MemoryImage(
        (await rootBundle.load('assets/images/Itm_logo.png')).buffer.asUint8List(),
      );

      final routineService = RoutineService();
      final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
      
      // Collect all classes for the full week
      final List<List<String>> fullWeekTableData = [];
      
      final dayMap = {
        'Sat': 'Saturday',
        'Sun': 'Sunday',
        'Mon': 'Monday',
        'Tue': 'Tuesday',
        'Wed': 'Wednesday',
        'Thu': 'Thursday',
        'Fri': 'Friday',
      };
      
      final daysOrder = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

      // Fetch routines for each batch and day to find all classes for this teacher
      // First, get all batches from Firestore by fetching routines
      final allRoutines = await routineService.streamAllRoutines().first;
      final batchesSet = <String>{};
      
      for (final routine in allRoutines) {
        if (routine.batch.isNotEmpty) {
          batchesSet.add(routine.batch);
        }
      }
      
      print('DEBUG: Teacher searching - Name: ${teacher.name}, Initials: $teacherInitials');
      print('DEBUG: Found batches: $batchesSet');

      // Now fetch each batch's routine for each day
      for (final day in daysOrder) {
        for (final batch in batchesSet) {
          final routineId = '${batch}_$day';
          print('DEBUG: Fetching routine: $routineId');
          
          final routine = await routineService.getRoutine(routineId);
          
          if (routine != null && routine.classes.isNotEmpty) {
            print('DEBUG: Found routine $routineId with ${routine.classes.length} classes');
            
            for (final classItem in routine.classes) {
              final classTeacherInitial = classItem.teacherInitial.trim().toUpperCase();
              print('DEBUG: Checking class ${classItem.courseName}, teacher: $classTeacherInitial vs $teacherInitials');
              
              if (classTeacherInitial == teacherInitials && classTeacherInitial.isNotEmpty) {
                fullWeekTableData.add([
                  dayMap[day] ?? day,
                  '${classItem.courseName} (${classItem.courseCode})',
                  classItem.time,
                  classItem.room,
                  batch,
                ]);
                print('DEBUG: ✓ Added class: ${classItem.courseName} on $day');
              }
            }
          }
        }
      }
      
      print('DEBUG: Total classes collected: ${fullWeekTableData.length}');
      for (final row in fullWeekTableData) {
        print('  - $row');
      }
      
      if (fullWeekTableData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No classes scheduled for this teacher.')),
          );
        }
        return;
      }

      // Add page with teacher info and full week routine
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(image, width: 80, height: 80),
                pw.SizedBox(height: 10),
                pw.Text('Department of Information Technology and Management', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Faculty of Science and Information Technology', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Daffodil International University', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 15),
                pw.Text('Teacher Routine Schedule', style: boldStyle.copyWith(fontSize: 16, decoration: pw.TextDecoration.underline)),
                pw.SizedBox(height: 10),
                pw.Text('Name: ${teacher.name}', style: boldStyle.copyWith(fontSize: 12)),
                pw.Text('Email: ${teacher.email}', style: boldStyle.copyWith(fontSize: 11)),
                pw.Text('Role: ${teacher.role}', style: boldStyle.copyWith(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text('Full Week Routine', style: boldStyle.copyWith(fontSize: 12)),
                pw.SizedBox(height: 10),
              ],
            ),
          ),
          build: (context) {
            final widgets = <pw.Widget>[];
            
            // Group classes by day
            final Map<String, List<List<String>>> classesByDay = {};
            for (final row in fullWeekTableData) {
              final day = row[0];
              if (!classesByDay.containsKey(day)) {
                classesByDay[day] = [];
              }
              // Add row without day column (since we'll show it as header)
              classesByDay[day]!.add([row[1], row[2], row[3], row[4]]);
            }
            
            // Create separate table for each day
            for (final day in daysOrder) {
              final fullDay = dayMap[day] ?? day;
              final dayClasses = classesByDay[fullDay];
              
              if (dayClasses != null && dayClasses.isNotEmpty) {
                widgets.add(
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(fullDay, style: boldStyle.copyWith(fontSize: 13, color: PdfColors.teal700)),
                      pw.SizedBox(height: 5),
                      pw.Table.fromTextArray(
                        headers: ['Course', 'Time Slot', 'Room', 'Batch'],
                        data: dayClasses,
                        headerStyle: boldStyle.copyWith(color: PdfColors.white, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.teal700,
                        ),
                        cellAlignment: pw.Alignment.center,
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2.5),
                          1: const pw.FlexColumnWidth(1.8),
                          2: const pw.FlexColumnWidth(1.2),
                          3: const pw.FlexColumnWidth(1),
                        },
                      ),
                      pw.SizedBox(height: 15),
                    ],
                  ),
                );
              }
            }
            
            return widgets;
          },
        ),
      );

      // Save PDF to device
      final output = await getTemporaryDirectory();
      final fileName = '${teacher.name.replaceAll(' ', '_')}_Full_Week_Routine.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Professional Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search teacher by name or role...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _selectedIndex = null;
                  });
                },
              ),
            ),
          ),

          // Teacher List (from Firestore)
          Expanded(
            child: StreamBuilder<List<Teacher>>(
              stream: _teacherService.streamAllTeachers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allTeachers = snapshot.data ?? [];
                final filtered = _searchQuery.isEmpty
                    ? allTeachers
                    : allTeachers.where((t) {
                        final q = _searchQuery.toLowerCase();
                        return t.name.toLowerCase().contains(q) || t.role.toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No teachers found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final teacher = filtered[index];
                    final isSelected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndex = null;
                          } else {
                            _selectedIndex = index;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
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
                                          teacher.name,
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
                                          teacher.role,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Teacher Avatar
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    backgroundImage: (() {
                                      final url = teacher.imageUrl.trim();
                                      if (url.isEmpty) return null;
                                      final lower = url.toLowerCase();
                                      try {
                                        if (lower.startsWith('http://') || lower.startsWith('https://')) {
                                          return NetworkImage(url);
                                        }
                                      } catch (_) {}
                                      return null;
                                    })(),
                                    child: (teacher.imageUrl.trim().isEmpty)
                                        ? Text(
                                            _getInitials(teacher.name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isSelected ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.white,
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
                                      const Icon(Icons.email, size: 16, color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          teacher.email,
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Expanded View
                                  if (isSelected) ...[
                                    const SizedBox(height: 16),
                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.visibility_outlined, size: 16),
                                            label: const Text('Daily Routine'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_showDailyRoutineIndex == index) {
                                                  _showDailyRoutineIndex = null;
                                                } else {
                                                  _showDailyRoutineIndex = index;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                            label: const Text('Get PDF'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.deepOrange,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              _generateTeacherPDF(teacher);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Daily routine area (from Firestore)
                                    if (_showDailyRoutineIndex == index) ...[
                                      const SizedBox(height: 12),
                                      _buildDaySelector(),
                                      const SizedBox(height: 12),
                                      _buildTeacherRoutineWidget(teacher),
                                    ],
                                  ],
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: 250.ms,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade500 : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(day.substring(0, 3), style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherRoutineWidget(Teacher teacher) {
    // Listen to all routines and filter client-side for the selected day and teacher initial (full day name)
    return StreamBuilder<List<Routine>>(
      stream: _routineService.streamAllRoutines(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading routines: ${snapshot.error}'),
          );
        }
        final routines = snapshot.data ?? [];
        
        // Get teacher's teacherInitial from Firestore (uppercase for comparison)
        final teacherInitials = teacher.teacherInitial.trim().toUpperCase();

        // Debug info
        print('=== TEACHER ROUTINE MATCHING ===');
        print('Teacher ID: "${teacher.id}"');
        print('Teacher Name: "${teacher.name}"');
        print('Teacher TeacherInitial (raw): "${teacher.teacherInitial}"');
        print('Teacher TeacherInitial (uppercase): "$teacherInitials"');
        print('Is teacherInitial empty? ${teacherInitials.isEmpty}');
        print('Total Routines: ${routines.length}');
        
        // Helper function to convert short day names to full names
        String getFullDayName(String shortDay) {
          final dayMap = {
            'sat': 'Saturday',
            'sun': 'Sunday',
            'mon': 'Monday',
            'tue': 'Tuesday',
            'wed': 'Wednesday',
            'thu': 'Thursday',
            'fri': 'Friday',
          };
          final lower = shortDay.toLowerCase().trim();
          return dayMap[lower] ?? shortDay; // Return full name or original if not found
        }
        
        // Group all classes for this teacher by full day name
        final Map<String, List<RoutineClass>> dayToClasses = {};
        for (final r in routines) {
          print('\nRoutine ID: "${r.id}" | Day="${r.day}" | Batch="${r.batch}" | Classes count: ${r.classes.length}');
          
          // If routine has no classes, skip it
          if (r.classes.isEmpty) {
            print('  Skipping routine with no classes');
            continue;
          }
          
          // Convert day to full name (e.g., "sat" → "Saturday")
          final fullDay = getFullDayName(r.day);
          print('  Day converted: "${r.day}" → "$fullDay"');
          
          // Check each class in the routine
          for (final routineClass in r.classes) {
            // Get routine class teacherInitial from Firestore and normalize to uppercase
            final classTeacherInitial = routineClass.teacherInitial.trim().toUpperCase();
            
            print('  Class: ${routineClass.courseName}');
            print('    Class TeacherInitial (raw): "${routineClass.teacherInitial}"');
            print('    Class TeacherInitial (uppercase): "$classTeacherInitial"');
            print('    Comparing: "$classTeacherInitial" == "$teacherInitials" -> ${classTeacherInitial == teacherInitials}');
            
            // Compare Firestore teacherInitial fields (both uppercase)
            if (classTeacherInitial == teacherInitials && classTeacherInitial.isNotEmpty) {
              print('    ✓ MATCH FOUND! Adding to day: "$fullDay"');
              dayToClasses.putIfAbsent(fullDay, () => []).add(routineClass);
            } else {
              print('    ✗ No match');
            }
          }
        }
        
        if (dayToClasses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No classes found for this teacher.')),
          );
        }
        // Show classes for the selected day (full name)
        final classesToday = dayToClasses[_selectedDay] ?? [];
        if (classesToday.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No classes scheduled for this day.')),
          );
        }
        return SizedBox(
          height: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: classesToday.map((c) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.class_rounded, color: Colors.deepPurple),
                    title: Text('${c.courseName} (${c.courseCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(children: [const Icon(Icons.schedule, size: 14, color: Colors.grey), const SizedBox(width: 6), Text(c.time)]),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 6), Text('Room: ${c.room}')]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
