import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/pdf_routine_service.dart';
import 'package:itm_connect/features/user/teacher/profile/profile_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final TeacherService _teacherService = TeacherService();
  final RoutineService _routineService = RoutineService();
  final TextEditingController _searchController = TextEditingController();
  
  // Stream subscriptions
  dynamic _teacherSubscription;
  dynamic _routineSubscription;

  // Helper method to extract start time for sorting
  String _extractStartTime(String timeRange) {
    // Expects format like "8:30 AM - 10:00 AM"
    final parts = timeRange.split('-');
    if (parts.isNotEmpty) {
      final startTime = parts[0].trim();
      // Convert to 24-hour format for proper sorting
      return _convertTo24Hour(startTime);
    }
    return '00:00';
  }

  // Convert 12-hour to 24-hour format for sorting
  String _convertTo24Hour(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return '00:00';

    // Check if it already has AM/PM
    if (timeStr.contains('AM') || timeStr.contains('PM')) {
      final parts = timeStr.split(RegExp(r'\s+'));
      if (parts.length < 2) return '00:00';
      
      final timePart = parts[0];
      final period = parts[1];
      
      final timeBits = timePart.split(':');
      if (timeBits.length < 1) return '00:00';
      
      var hour = int.tryParse(timeBits[0]) ?? 0;
      final minute = timeBits.length > 1 ? timeBits[1] : '00';
      
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
    }

    // Handle 24h format like "13:00" or "8:30"
    final bits = timeStr.split(':');
    if (bits.isEmpty) return '00:00';
    
    var hour = int.tryParse(bits[0]) ?? 0;
    final minute = bits.length > 1 ? bits[1] : '00';
    
    return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
  }

  // State
  int? expandedIndex;
  int? showRoutineIndex;
  String selectedDay = 'Monday';
  bool isSearching = false;
  String searchQuery = '';
  
  // Data storage
  List<Teacher> allTeachers = [];
  Map<String, List<RoutineClass>> teacherRoutinesMap = {};
  Map<String, List<String>> routineDocIds = {}; // Stores document IDs (batch_day) for each routine
  
  // Loading & error states
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Initialize selected day to today automatically using locale-independent weekday
    // School days: Saturday, Sunday, Monday, Tuesday, Wednesday, Thursday
    // Off days: Friday
    final now = DateTime.now();
    final weekdayMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',    // Off day
      6: 'Saturday',
      7: 'Sunday',
    };
    final todayName = weekdayMap[now.weekday] ?? 'Monday';
    const schoolDays = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
    ];
    
    // If today is a school day, use it. Otherwise find next school day
    if (schoolDays.contains(todayName)) {
      selectedDay = todayName;
    } else {
      // Today is Friday (off day), so show Saturday (next school day)
      selectedDay = 'Saturday';
    }
    
    // Load all teachers and routines upfront and keep them updated
    _initStreams();
  }

  void _initStreams() {
    _teacherSubscription = _teacherService.streamAllTeachers().listen((teachers) {
      if (mounted) {
        setState(() {
          allTeachers = teachers;
          if (_loading && teacherRoutinesMap.isNotEmpty) _loading = false;
        });
      }
    });

    _routineSubscription = _routineService.streamAllRoutines().listen((allRoutines) {
      if (mounted) {
        _processRoutines(allRoutines);
      }
    });
  }

  void _processRoutines(List<Routine> allRoutines) {
    // Build a map of teacher initials to their routines by day
    final Map<String, List<RoutineClass>> routinesMap = {};
    final Map<String, List<String>> docIdsMap = {};

    for (final routine in allRoutines) {
      for (final routineClass in routine.classes) {
        final teacherInitials = routineClass.teacherInitial.trim().toUpperCase();
        final fullDay = _getFullDayName(routine.day);

        if (teacherInitials.isNotEmpty) {
          final key = '$teacherInitials|$fullDay';
          routinesMap.putIfAbsent(key, () => []).add(routineClass);
          docIdsMap.putIfAbsent(key, () => []).add(routine.id); // Store document ID (batch_day)
        }
      }
    }

    setState(() {
      teacherRoutinesMap = routinesMap;
      routineDocIds = docIdsMap;
      _loading = false;
    });
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

  bool _hasTeacherAnyClasses(Teacher teacher) {
    final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
    if (teacherInitials.isEmpty) return false;
    
    // Check if teacher has any classes for any day
    for (final key in teacherRoutinesMap.keys) {
      if (key.startsWith('$teacherInitials|')) {
        final routines = teacherRoutinesMap[key];
        if (routines != null && routines.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  List<Teacher> getFilteredTeachers() {
    if (searchQuery.isEmpty) {
      return allTeachers;
    }
    
    final query = searchQuery.toLowerCase();
    return allTeachers.where((teacher) {
      return teacher.name.toLowerCase().contains(query) ||
             teacher.email.toLowerCase().contains(query) ||
             teacher.role.toLowerCase().contains(query) ||
             _getRoleCategory(teacher.role).toLowerCase().contains(query);
    }).toList();
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

      final teacherInitials = teacher.teacherInitial.trim().toUpperCase();
      
      // Fetch all routines
      final allRoutines = await _routineService.streamAllRoutines().first;
      
      // Filter routines that contain this teacher
      final List<Routine> teacherRoutines = [];
      for (final routine in allRoutines) {
        final teacherClasses = routine.classes.where((c) => c.teacherInitial.trim().toUpperCase() == teacherInitials).toList();
        if (teacherClasses.isNotEmpty) {
          teacherRoutines.add(Routine(
            id: routine.id,
            batch: routine.batch.isEmpty && routine.id.contains('_') ? routine.id.split('_')[0] : routine.batch,
            day: routine.day,
            teacherInitial: routine.teacherInitial,
            classes: teacherClasses,
          ));
        }
      }
      
      if (mounted) Navigator.pop(context); // Hide loading

      if (teacherRoutines.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No classes scheduled for this teacher.')),
          );
        }
        return;
      }

      await PdfRoutineService.generateRoutinePdf(
        routines: teacherRoutines,
        title: "Teacher Full Week Routine",
        subtitle: "${teacher.name} (${teacher.role})",
        departmentName: "Information Technology & Management",
        teacherName: teacher.name,
        teacherRole: teacher.role,
        consultingHour: teacher.consultingHour,
      );

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _teacherSubscription?.cancel();
    _routineSubscription?.cancel();
    super.dispose();
  }

  void _showRoutineDetailsSheet(Teacher teacher, Color roleCategoryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeacherRoutineDetailsSheet(
        teacher: teacher,
        roleCategoryColor: roleCategoryColor,
        selectedDay: selectedDay,
        onDayChanged: (day) {
          setState(() {
            selectedDay = day;
          });
        },
        teacherRoutinesMap: teacherRoutinesMap,
        routineDocIds: routineDocIds,
        extractStartTime: _extractStartTime,
      ),
    );
  }

  Widget _buildTeacherActionButtons(Teacher teacher, int index, bool routineVisible, Color roleCategoryColor) {
    final hasClasses = _hasTeacherAnyClasses(teacher);

    return Row(
      children: [
        // Profile Button - Always visible
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_rounded, size: 16),
            label: const Text(
              'Profile',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(teacher: teacher),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Routine Button - Only if has classes
        if (hasClasses) ...[
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.schedule_rounded, size: 16),
              label: const Text(
                'Routine',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                _showRoutineDetailsSheet(teacher, roleCategoryColor);
              },
            ),
          ),
          const SizedBox(width: 8),
          // PDF Button - Only if has classes
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
      ],
    );
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
    
    // Filter teachers based on search query
    final filteredTeachers = searchQuery.isEmpty
        ? sortedTeachers
        : sortedTeachers.where((teacher) {
            final query = searchQuery.toLowerCase();
            return teacher.name.toLowerCase().contains(query) ||
                   teacher.email.toLowerCase().contains(query) ||
                   teacher.role.toLowerCase().contains(query) ||
                   _getRoleCategory(teacher.role).toLowerCase().contains(query);
          }).toList();

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
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
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
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  isSearching ? Icons.close_rounded : Icons.search_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isSearching = !isSearching;
                                                    searchQuery = '';
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isSearching)
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (value) {
                                            setState(() {
                                              searchQuery = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search by name, email, or role...',
                                            prefixIcon: const Icon(Icons.search, color: Colors.teal),
                                            suffixIcon: searchQuery.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      setState(() {
                                                        searchQuery = '';
                                                      });
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Colors.teal, width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.teal.withOpacity(0.3), width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Colors.teal, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          autofocus: true,
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
                                itemCount: filteredTeachers.length,
                                itemBuilder: (context, index) {
                                  final teacher = filteredTeachers[index];
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
                                                      if (teacher.consultingHour.isNotEmpty) ...[
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: Colors.amber.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              const Text(
                                                                "CONSULTING HOURS",
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.amber,
                                                                  letterSpacing: 1.0,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                teacher.consultingHour,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors.black87,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(height: 20),
                                                      ],
                                                      _buildTeacherActionButtons(teacher, index, false, roleCategoryColor),
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
}

class TeacherRoutineDetailsSheet extends StatefulWidget {
  final Teacher teacher;
  final Color roleCategoryColor;
  final String selectedDay;
  final Function(String) onDayChanged;
  final Map<String, List<RoutineClass>> teacherRoutinesMap;
  final Map<String, List<String>> routineDocIds;
  final String Function(String) extractStartTime;

  const TeacherRoutineDetailsSheet({
    super.key,
    required this.teacher,
    required this.roleCategoryColor,
    required this.selectedDay,
    required this.onDayChanged,
    required this.teacherRoutinesMap,
    this.routineDocIds = const {},
    required this.extractStartTime,
  });

  @override
  State<TeacherRoutineDetailsSheet> createState() => _TeacherRoutineDetailsSheetState();
}

class _TeacherRoutineDetailsSheetState extends State<TeacherRoutineDetailsSheet> {
  late String _currentDay;

  @override
  void initState() {
    super.initState();
    _currentDay = widget.selectedDay;
  }

  @override
  void didUpdateWidget(TeacherRoutineDetailsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      setState(() {
        _currentDay = widget.selectedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag indicator
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with teacher info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.roleCategoryColor,
                      widget.roleCategoryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: (() {
                            final url = widget.teacher.imageUrl.trim();
                            if (url.isEmpty) return null;
                            final lower = url.toLowerCase();
                            try {
                              if (lower.startsWith('http://') || lower.startsWith('https://')) {
                                return NetworkImage(url);
                              }
                            } catch (_) {}
                            return null;
                          })(),
                          child: (widget.teacher.imageUrl.trim().isEmpty)
                              ? Text(
                                  _getInitials(widget.teacher.name),
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                widget.teacher.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.teacher.role,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Day selector and routine content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
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
                        const SizedBox(height: 12),
                        _buildDaySelector(),
                        const SizedBox(height: 20),
                        _buildRoutineList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          final isSelected = _currentDay == day;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentDay = day;
              });
              widget.onDayChanged(day);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? widget.roleCategoryColor : Colors.grey[200],
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

  Widget _buildRoutineList() {
    final teacherInitials = widget.teacher.teacherInitial.trim().toUpperCase();
    final key = '$teacherInitials|$_currentDay';
    final routines = widget.teacherRoutinesMap[key] ?? [];
    final docIds = widget.routineDocIds[key] ?? [];

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

    // Create indexed list to maintain correspondence between routines and doc IDs
    final indexedRoutines = routines.asMap().entries.toList();
    
    // Sort by time
    indexedRoutines.sort((a, b) {
      final timeA = widget.extractStartTime(a.value.time);
      final timeB = widget.extractStartTime(b.value.time);
      return timeA.compareTo(timeB);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: indexedRoutines.map((entry) {
        final index = entry.key;
        final c = entry.value;
        
        // Extract batch from document ID (format: "batch_day")
        String batch = 'N/A';
        if (index < docIds.length) {
          final docId = docIds[index];
          if (docId.contains('_')) {
            batch = docId.split('_')[0]; // Get first part before underscore
          }
        }
        
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
                    Icon(Icons.class_rounded, color: widget.roleCategoryColor, size: 18),
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
                    const Spacer(),
                    Icon(Icons.layers_outlined, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Batch: $batch',
                      style: TextStyle(fontSize: 13, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
// Bump for recompile
