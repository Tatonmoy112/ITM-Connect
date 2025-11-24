import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
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
  final RoutineService _routineService = RoutineService();
  final TextEditingController _searchController = TextEditingController();

  // State
  int? expandedIndex;
  int? showRoutineIndex;
  String selectedDay = 'Monday';
  
  // Data storage
  List<Teacher> allTeachers = [];
  Map<String, List<RoutineClass>> teacherRoutinesMap = {};
  
  // Loading & error states
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize selected day to today if it's a valid day
    final now = DateTime.now();
    final formattedDay = DateFormat('EEEE').format(now);
    const validDays = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];
    selectedDay = validDays.contains(formattedDay) ? formattedDay : 'Monday';
    
    // Load all teachers and routines upfront
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load all teachers
      final teachers = await _teacherService.getAllTeachers();
      
      // Load all routines
      final allRoutines = await _routineService.streamAllRoutines().first;

      // Build a map of teacher initials to their routines by day
      final Map<String, List<RoutineClass>> routinesMap = {};

      for (final routine in allRoutines) {
        for (final routineClass in routine.classes) {
          final teacherInitials = routineClass.teacherInitial.trim().toUpperCase();
          final fullDay = _getFullDayName(routine.day);

          if (teacherInitials.isNotEmpty) {
            final key = '$teacherInitials|$fullDay';
            routinesMap.putIfAbsent(key, () => []).add(routineClass);
          }
        }
      }

      if (mounted) {
        setState(() {
          allTeachers = teachers;
          teacherRoutinesMap = routinesMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
    };
    return dayMap[shortDay.toLowerCase().trim()] ?? shortDay;
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    final nameParts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (nameParts.isEmpty) return '';
    String initials = '';
    for (final part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.toUpperCase();
  }

  String _getRoleCategory(String role) {
    if (role.isEmpty) return 'Faculty';
    final roleLower = role.toLowerCase();
    
    if (roleLower.contains('dean')) {
      if (roleLower.contains('assistant')) return 'Assistant Dean';
      return 'Dean';
    }
    
    if (roleLower.contains('head')) return 'Head';
    
    if (roleLower.contains('professor')) {
      if (roleLower.contains('assistant')) return 'Assistant Professor';
      return 'Professor';
    }
    
    if (roleLower.contains('lecturer')) return 'Lecturer';
    
    if (roleLower.contains('instructor')) return 'Instructor';
    
    return role;
  }

  Color _getRoleCategoryColor(String role) {
    final category = _getRoleCategory(role);
    switch (category) {
      case 'Dean':
        return const Color(0xFF6B4226);
      case 'Assistant Dean':
        return const Color(0xFF8B5A3C);
      case 'Head':
        return const Color(0xFF1A73E8);
      case 'Professor':
        return const Color(0xFF00897B);
      case 'Assistant Professor':
        return const Color(0xFF00A86B);
      case 'Lecturer':
        return const Color(0xFFF57C00);
      case 'Instructor':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.grey;
    }
  }

  int _getRolePriority(String role) {
    final category = _getRoleCategory(role);
    switch (category) {
      case 'Dean':
        return 1;
      case 'Assistant Dean':
        return 2;
      case 'Head':
        return 3;
      case 'Professor':
        return 4;
      case 'Assistant Professor':
        return 5;
      case 'Lecturer':
        return 6;
      case 'Instructor':
        return 7;
      default:
        return 99;
    }
  }

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
      final normalStyle = pw.TextStyle(fontWeight: pw.FontWeight.normal);

      // Load DIU logo
      pw.MemoryImage? diuLogo;
      try {
        diuLogo = pw.MemoryImage(
          (await rootBundle.load('assets/images/DIU_logo.png')).buffer.asUint8List(),
        );
      } catch (e) {
        print('Warning: Could not load DIU logo from assets/images/DIU_logo.png: $e');
      }

      final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
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

      // Fetch all routines for PDF generation
      final allRoutines = await _routineService.streamAllRoutines().first;

      for (final day in daysOrder) {
        for (final routine in allRoutines) {
          if (_getFullDayName(routine.day) == dayMap[day]) {
            if (routine.classes.isNotEmpty) {
              for (final classItem in routine.classes) {
                final classTeacherInitial = classItem.teacherInitial.trim().toUpperCase();
                
                if (classTeacherInitial == teacherInitials && classTeacherInitial.isNotEmpty) {
                  fullWeekTableData.add([
                    dayMap[day] ?? day,
                    '${classItem.courseName} (${classItem.courseCode})',
                    classItem.time,
                    classItem.room,
                    routine.batch,
                  ]);
                }
              }
            }
          }
        }
      }
      
      if (fullWeekTableData.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No classes scheduled for this teacher.')),
          );
        }
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => pw.Column(
            children: [
              pw.Center(
                child: pw.Text(
                  'Teacher Full Week Routine',
                  style: boldStyle.copyWith(fontSize: 18, decoration: pw.TextDecoration.underline),
                ),
              ),
              pw.SizedBox(height: 20),
              
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(
                  'Generated through ITM Connect',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
              ),
              pw.SizedBox(height: 15),
              
              if (diuLogo != null)
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Image(diuLogo, width: 80, height: 80),
                )
              else
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'DIU Logo',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ),
              pw.SizedBox(height: 12),
              
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Department of Information Technology & Management',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Faculty of Science and Information Technology',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Daffodil International University',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(),
            ],
          ),
          build: (context) {
            final widgets = <pw.Widget>[];
            
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        pw.Text('Name: ', style: boldStyle.copyWith(fontSize: 13)),
                        pw.Text(teacher.name, style: normalStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        pw.Text('Email: ', style: boldStyle.copyWith(fontSize: 13)),
                        pw.Text(teacher.email, style: normalStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        pw.Text('Designation: ', style: boldStyle.copyWith(fontSize: 13)),
                        pw.Text(teacher.role, style: normalStyle.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 15));
            
            final Map<String, List<List<String>>> classesByDay = {};
            for (final row in fullWeekTableData) {
              final day = row[0];
              if (!classesByDay.containsKey(day)) {
                classesByDay[day] = [];
              }
              classesByDay[day]!.add([row[1], row[2], row[3], row[4]]);
            }
            
            for (final day in daysOrder) {
              final fullDay = dayMap[day] ?? day;
              final dayClasses = classesByDay[fullDay];
              
              if (dayClasses != null && dayClasses.isNotEmpty) {
                widgets.add(
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        fullDay,
                        style: boldStyle.copyWith(fontSize: 14, color: PdfColors.teal700),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Table.fromTextArray(
                        headers: ['Course', 'Time Slot', 'Room', 'Batch'],
                        data: dayClasses,
                        headerStyle: boldStyle.copyWith(color: PdfColors.white, fontSize: 11),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.teal700,
                        ),
                        cellAlignment: pw.Alignment.center,
                        cellStyle: const pw.TextStyle(fontSize: 10),
                        border: pw.TableBorder.all(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2.5),
                          1: const pw.FlexColumnWidth(1.8),
                          2: const pw.FlexColumnWidth(1.2),
                          3: const pw.FlexColumnWidth(1),
                        },
                      ),
                      pw.SizedBox(height: 14),
                    ],
                  ),
                );
              }
            }
            
            return widgets;
          },
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      final fileName = '${teacher.name.replaceAll(' ', '_')}_Full_Week_Routine.pdf';
      final pdfBytes = await pdf.save();
      
      try {
        await PdfDownloadService.downloadAndOpenPdf(
          pdfBytes: pdfBytes.toList(),
          fileName: fileName,
        );
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }

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
        Navigator.of(context).pop();
        
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);

    // Sort teachers by role priority
    final sortedTeachers = List<Teacher>.from(allTeachers);
    sortedTeachers.sort((a, b) => _getRolePriority(a.role).compareTo(_getRolePriority(b.role)));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : sortedTeachers.isEmpty
                  ? const Center(
                      child: Text(
                        'No Teachers Available',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
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
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Teachers Directory',
                                              style: TextStyle(
                                                fontSize: isMobile ? 16.0 : 22.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Find and explore teacher information',
                                              style: TextStyle(
                                                fontSize: isMobile ? 11.0 : 13.0,
                                                color: Colors.white.withOpacity(0.9),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              constraints: BoxConstraints(maxWidth: containerMaxWidth),
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sortedTeachers.length,
                                itemBuilder: (context, index) {
                                  final teacher = sortedTeachers[index];
                                  final isExpanded = expandedIndex == index;
                                  final routineVisible = showRoutineIndex == index;
                                  final roleCategory = _getRoleCategory(teacher.role);
                                  final roleCategoryColor = _getRoleCategoryColor(teacher.role);

                                  return GestureDetector(
                                    onTap: () {
                                      if (!routineVisible) {
                                        setState(() {
                                          expandedIndex = isExpanded ? null : index;
                                          showRoutineIndex = null;
                                        });
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: roleCategoryColor.withOpacity(0.15),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 1,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: roleCategoryColor.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Role Category Badge Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  roleCategoryColor,
                                                  roleCategoryColor.withOpacity(0.8),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(14),
                                                topRight: Radius.circular(14),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.25),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    roleCategory,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Teacher Info Section
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: isExpanded
                                                ? Column(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 60,
                                                        backgroundColor: roleCategoryColor.withOpacity(0.15),
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
                                                                style: TextStyle(
                                                                  color: roleCategoryColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 28,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        teacher.name,
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        teacher.role,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: roleCategoryColor,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        teacher.email,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 20),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: ElevatedButton.icon(
                                                              icon: const Icon(Icons.schedule_rounded, size: 16),
                                                              label: Text(
                                                                routineVisible ? 'Hide' : 'Routine',
                                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                              ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: roleCategoryColor,
                                                                foregroundColor: Colors.white,
                                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                elevation: 2,
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  showRoutineIndex = routineVisible ? null : index;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: ElevatedButton.icon(
                                                              icon: const Icon(Icons.download_rounded, size: 16),
                                                              label: const Text(
                                                                'PDF',
                                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                              ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.deepOrange,
                                                                foregroundColor: Colors.white,
                                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                elevation: 2,
                                                              ),
                                                              onPressed: () {
                                                                _generateTeacherPDF(teacher);
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 32,
                                                        backgroundColor: roleCategoryColor.withOpacity(0.15),
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
                                                                style: TextStyle(
                                                                  color: roleCategoryColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              teacher.name,
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 6),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: roleCategoryColor.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                teacher.role,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: roleCategoryColor,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                          // Routine Section
                                          if (routineVisible) ...[
                                            Divider(color: roleCategoryColor.withOpacity(0.2)),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Select Day:',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _buildDaySelector(),
                                                  const SizedBox(height: 16),
                                                  _buildTeacherRoutineWidget(teacher),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
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
    final days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedDay == day;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade500 : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                day.substring(0, 3),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeacherRoutineWidget(Teacher teacher) {
    final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
    final key = '$teacherInitials|$selectedDay';
    final routines = teacherRoutinesMap[key] ?? [];

    if (teacherInitials.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Teacher initials not available.')),
      );
    }

    if (routines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No classes scheduled for this day.')),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: routines.map((c) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.class_rounded, color: Colors.deepPurple, size: 18),
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
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Text(
                          c.time,
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.orange.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Room: ${c.room}',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
