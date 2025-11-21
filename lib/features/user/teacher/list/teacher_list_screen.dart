import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/pdf_download_service.dart';

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
  bool _showSearchBar = false;
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
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF43cea2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Generating PDF...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

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
      final allRoutines = await routineService.streamAllRoutines().first;
      final batchesSet = <String>{};
      
      for (final routine in allRoutines) {
        if (routine.batch.isNotEmpty) {
          batchesSet.add(routine.batch);
        }
      }

      // Now fetch each batch's routine for each day
      for (final day in daysOrder) {
        for (final batch in batchesSet) {
          final routineId = '${batch}_$day';
          
          final routine = await routineService.getRoutine(routineId);
          
          if (routine != null && routine.classes.isNotEmpty) {
            for (final classItem in routine.classes) {
              final classTeacherInitial = classItem.teacherInitial.trim().toUpperCase();
              
              if (classTeacherInitial == teacherInitials && classTeacherInitial.isNotEmpty) {
                fullWeekTableData.add([
                  dayMap[day] ?? day,
                  '${classItem.courseName} (${classItem.courseCode})',
                  classItem.time,
                  classItem.room,
                  batch,
                ]);
              }
            }
          }
        }
      }
      
      if (fullWeekTableData.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          
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

      // Save PDF using cross-platform service
      final fileName = '${teacher.name.replaceAll(' ', '_')}_Full_Week_Routine.pdf';
      final pdfBytes = await pdf.save();
      await PdfDownloadService.downloadPdf(
        pdfBytes: pdfBytes.toList(),
        fileName: fileName,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✓ PDF Downloaded Successfully'),
            content: Text(
              'File: $fileName\n\nSize: ${PdfDownloadService.getFileSizeInKB(pdfBytes.toList())} KB',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 22.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);
    final iconSize = isMobile ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Teal Header Welcome Card Pattern
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
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
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
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
                        child: isMobile
                            ? Padding(
                                padding: EdgeInsets.all(6),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Teachers Directory',
                                          style: TextStyle(
                                            fontSize: headerFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Find and explore teacher information',
                                          style: TextStyle(
                                            fontSize: subtitleFontSize,
                                            color: Colors.white.withOpacity(0.9),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: -headerPadding,
                                      right: -headerPadding,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showSearchBar = !_showSearchBar;
                                            if (!_showSearchBar) {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _selectedIndex = null;
                                            }
                                          });
                                        },
                                        child: AnimatedScale(
                                          scale: _showSearchBar ? 1.1 : 1.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _showSearchBar 
                                                ? Colors.white.withOpacity(0.35)
                                                : Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(_showSearchBar ? 0.5 : 0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.person_search_rounded,
                                              color: Colors.white,
                                              size: iconSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.all(8),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Teachers Directory',
                                                style: TextStyle(
                                                  fontSize: headerFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Find and explore teacher information',
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
                                    Positioned(
                                      top: -headerPadding,
                                      right: -headerPadding,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showSearchBar = !_showSearchBar;
                                            if (!_showSearchBar) {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _selectedIndex = null;
                                            }
                                          });
                                        },
                                        child: AnimatedScale(
                                          scale: _showSearchBar ? 1.1 : 1.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _showSearchBar 
                                                ? Colors.white.withOpacity(0.35)
                                                : Colors.white.withOpacity(0.25),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(_showSearchBar ? 0.5 : 0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.person_search_rounded,
                                              color: Colors.white,
                                              size: iconSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      // Conditional search bar
                      if (_showSearchBar) ...[
                        Padding(
                          padding: EdgeInsets.all(headerPadding),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(14),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search teacher by name or role...',
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.teal),
                                  onPressed: () {
                                    setState(() {
                                      _showSearchBar = false;
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _selectedIndex = null;
                                    });
                                  },
                                ),
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
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Teacher List (from Firestore) - preserved Firebase logic
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: containerMaxWidth),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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

                    return Column(
                      children: List.generate(
                        filtered.length,
                        (index) {
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
                                        if (isSelected) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.schedule_rounded, size: 16),
                                                  label: Text(
                                                    _showDailyRoutineIndex == index ? 'Hide' : 'Routine',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
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
                                                  icon: const Icon(Icons.download_rounded, size: 16),
                                                  label: const Text(
                                                    'PDF',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
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
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: classesToday.map((c) {
                // Extract batch from routine ID (format: batch_semester)
                final routineId = routines.firstWhere(
                  (r) => r.classes.any((rc) => 
                    rc.courseName == c.courseName && 
                    rc.teacherInitial.trim().toUpperCase() == teacherInitials
                  ),
                  orElse: () => routines.first,
                ).id;
                final batchName = routineId.split('_').first;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Header with batch info
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.layers_rounded, size: 16, color: Colors.teal.shade700),
                              const SizedBox(width: 6),
                              Text(
                                'Batch: $batchName',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Course Name and Code
                        Row(
                          children: [
                            const Icon(Icons.class_rounded, color: Colors.deepPurple, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.courseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    c.courseCode,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Time and Room in a row
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.blue.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    c.time,
                                    style: TextStyle(fontSize: 13, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Colors.orange.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Room: ${c.room}',
                                    style: TextStyle(fontSize: 13, color: Colors.orange.shade600, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      ),
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
