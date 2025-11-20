import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  // Email Launcher
  Future<void> _launchEmail(String emailAddress) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: emailAddress);
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email client for $emailAddress')),
        );
      }
    }
  }

  // Generate and save PDF for teacher's full routine
  Future<void> _generateTeacherPDF(Teacher teacher) async {
    try {
      // Get all routines
      final routineService = RoutineService();
      final routines = await routineService.streamAllRoutines().first;
      
      final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
      
      // Collect all matching classes by day
      final Map<String, List<RoutineClass>> dayToClasses = {};
      
      final dayMap = {
        'sat': 'Saturday',
        'sun': 'Sunday',
        'mon': 'Monday',
        'tue': 'Tuesday',
        'wed': 'Wednesday',
        'thu': 'Thursday',
        'fri': 'Friday',
      };
      
      for (final r in routines) {
        if (r.classes.isEmpty) continue;
        
        for (final routineClass in r.classes) {
          final classTeacherInitial = routineClass.teacherInitial.trim().toUpperCase();
          
          if (classTeacherInitial == teacherInitials && classTeacherInitial.isNotEmpty) {
            final fullDay = dayMap[r.day.toLowerCase().trim()] ?? r.day;
            dayToClasses.putIfAbsent(fullDay, () => []).add(routineClass);
          }
        }
      }
      
      if (dayToClasses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No classes found for this teacher.')),
          );
        }
        return;
      }
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Days in order
      final daysOrder = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      
      // Add first page with teacher info
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Teacher Schedule',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Name: ${teacher.name}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Role: ${teacher.role}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Email: ${teacher.email}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('ID: ${teacher.id}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              pw.Text(
                'Weekly Routine',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      
      // Add a page for each day that has classes
      for (final day in daysOrder) {
        if (!dayToClasses.containsKey(day)) continue;
        
        final classesToday = dayToClasses[day] ?? [];
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  day,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 15),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Course Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Room', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...classesToday.map((c) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(c.courseName)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(c.courseCode)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(c.time)),
                          pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(c.room)),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      
      // Save PDF to device
      final output = await getApplicationDocumentsDirectory();
      final fileName = '${teacher.name.replaceAll(' ', '_')}_routine.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
                  padding: const EdgeInsets.all(0),
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
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // Collapsed View
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.blueGrey,
                                    // Choose image provider safely: network if http(s), asset if local asset path, else show initials
                                    backgroundImage: (() {
                                      final url = teacher.imageUrl.trim();
                                      if (url.isEmpty) return null;
                                      final lower = url.toLowerCase();
                                      try {
                                        if (lower.startsWith('http://') || lower.startsWith('https://')) {
                                          return NetworkImage(url);
                                        }
                                        if (lower.startsWith('assets/') || lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
                                          return AssetImage(url) as ImageProvider;
                                        }
                                      } catch (_) {}
                                      return null;
                                    })(),
                                    child: (teacher.imageUrl.trim().isEmpty)
                                        ? Text(_getInitials(teacher.name), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(teacher.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(teacher.role, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Icon(isSelected ? Icons.expand_less : Icons.expand_more),
                                ],
                              ),

                              // Expanded View
                              if (isSelected)
                                Column(
                                  children: [
                                    const Divider(height: 24),
                                    // Email Section
                                    ListTile(
                                      leading: const Icon(Icons.email_outlined, color: Colors.blueGrey),
                                      title: Text(teacher.email),
                                      onTap: () => _launchEmail(teacher.email),
                                      dense: true,
                                    ),
                                    const Divider(),
                                    // Action Buttons (disabled for now)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.visibility_outlined),
                                              label: const Text('Daily Routine'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                foregroundColor: Colors.white,
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
                                              icon: const Icon(Icons.picture_as_pdf_outlined),
                                              label: const Text('Get Full PDF'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.deepOrange,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () {
                                                _generateTeacherPDF(teacher);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Daily routine area (from Firestore)
                                    if (_showDailyRoutineIndex == index) ...[
                                      const SizedBox(height: 12),
                                      _buildDaySelector(),
                                      const SizedBox(height: 12),
                                      _buildTeacherRoutineWidget(teacher),
                                    ],
                                  ],
                                ),
                            ],
                          ),
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
