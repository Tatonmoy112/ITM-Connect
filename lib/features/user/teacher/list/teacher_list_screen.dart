import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  // Updated Data Structure
  final List<Map<String, dynamic>> mockTeachers = [
    {
      "name": "Prof. Dr. Abdul Kalam",
      "position": "Dean, Faculty of Engineering",
      "email": "kalam@diu.edu.bd",
      "image": "https://placehold.co/150x150/7B68EE/FFFFFF/png?text=AK",
      "routine": {
        "Monday": [
          {"time": "09:00 AM - 10:30 AM", "courseName": "Leadership Seminar", "courseCode": "ENG-701", "room": "Dean's Office", "batch": "N/A"},
        ],
        "Wednesday": [
          {"time": "02:00 PM - 03:30 PM", "courseName": "Research Methodology", "courseCode": "ENG-702", "room": "Auditorium", "batch": "N/A"},
        ],
      },
    },
    {
      "name": "Dr. Aisha Khan",
      "position": "Associate Dean, Faculty of Science",
      "email": "aisha@diu.edu.bd",
      "image": "https://placehold.co/150x150/6495ED/FFFFFF/png?text=AK",
      "routine": {
        "Tuesday": [
          {"time": "11:00 AM - 12:30 PM", "courseName": "Advanced Physics", "courseCode": "PHY-501", "room": "Science Lab", "batch": "N/A"},
        ],
        "Thursday": [
          {"time": "09:00 AM - 10:30 AM", "courseName": "Quantum Mechanics", "courseCode": "PHY-502", "room": "Lecture Hall 1", "batch": "N/A"},
        ],
      },
    },
    {
      "name": "Dr. Rashed Ahmed",
      "position": "Head of Department, CSE",
      "email": "rashed@diu.edu.bd",
      "image": "https://placehold.co/150x150/FF7F50/FFFFFF/png?text=RA",
      "routine": {
        "Monday": [
          {"time": "10:00 AM - 11:30 AM", "courseName": "Data Structures", "courseCode": "CSE-221", "room": "303", "batch": "55th"},
        ],
        "Wednesday": [
          {"time": "01:00 PM - 02:30 PM", "courseName": "Algorithms", "courseCode": "CSE-301", "room": "304", "batch": "54th"},
        ],
      },
    },
    {
      "name": "Dr. Mahmudul Hasan",
      "position": "Professor, CSE",
      "email": "mahmudul@diu.edu.bd",
      "image": "https://placehold.co/150x150/7B68EE/FFFFFF/png?text=MH",
      "routine": {
        "Monday": [
          {"time": "09:00 AM - 10:30 AM", "courseName": "Advanced Algorithms", "courseCode": "CSE-321", "room": "501", "batch": "52nd"},
          {"time": "01:00 PM - 02:30 PM", "courseName": "Compiler Design", "courseCode": "CSE-411", "room": "502", "batch": "49th"},
        ],
        "Tuesday": [
          {"time": "11:00 AM - 12:30 PM", "courseName": "Data Structures", "courseCode": "CSE-221", "room": "303", "batch": "55th"},
        ],
      }
    },
    {
      "name": "Ms. Farzana Rahman",
      "position": "Lecturer, SWE",
      "email": "farzana@diu.edu.bd",
      "image": "https://placehold.co/150x150/6495ED/FFFFFF/png?text=FR",
      "routine": {
        "Monday": [
          {"time": "10:00 AM - 11:30 AM", "courseName": "Intro to SWE", "courseCode": "SWE-101", "room": "601", "batch": "58th"},
        ],
        "Wednesday": [
          {"time": "02:00 PM - 03:30 PM", "courseName": "Software Testing", "courseCode": "SWE-311", "room": "602", "batch": "54th"},
        ]
      }
    },
    {
      "name": "Mr. John Doe",
      "position": "Professor, Physics",
      "email": "john@diu.edu.bd",
      "image": "https://placehold.co/150x150/8A2BE2/FFFFFF/png?text=JD",
      "routine": {
        "Tuesday": [
          {"time": "09:00 AM - 10:30 AM", "courseName": "Classical Mechanics", "courseCode": "PHY-301", "room": "Physics Lab", "batch": "N/A"},
        ],
        "Thursday": [
          {"time": "01:00 PM - 02:30 PM", "courseName": "Thermodynamics", "courseCode": "PHY-302", "room": "Lecture Hall 2", "batch": "N/A"},
        ],
      },
    },
    {
      "name": "Dr. Emily White",
      "position": "Lecturer, Chemistry",
      "email": "emily@diu.edu.bd",
      "image": "https://placehold.co/150x150/008080/FFFFFF/png?text=EW",
      "routine": {
        "Wednesday": [
          {"time": "11:00 AM - 12:30 PM", "courseName": "Organic Chemistry", "courseCode": "CHM-201", "room": "Chemistry Lab", "batch": "N/A"},
        ],
        "Friday": [
          {"time": "09:00 AM - 10:30 AM", "courseName": "Inorganic Chemistry", "courseCode": "CHM-202", "room": "Lecture Hall 3", "batch": "N/A"},
        ],
      },
    },
  ];

  // State
  int? _selectedIndex;
  int? _showDailyRoutineIndex;
  String _selectedDay = 'Monday';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    if (nameParts.isNotEmpty) {
      initials += nameParts[0][0];
      if (nameParts.length > 1) {
        initials += nameParts[nameParts.length - 1][0];
      }
    }
    return initials.toUpperCase();
  }

  int _getTeacherRank(Map<String, dynamic> teacher) {
    final name = teacher['name'] as String;
    final position = teacher['position'] as String;

    if (position.contains('Dean, Faculty')) return 1; // Dean
    if (position.contains('Associate Dean')) return 2; // Associate Dean
    if (position.contains('Head of Department')) return 3; // HOD
    if (name.startsWith('Dr.') && position.contains('Professor')) return 4; // Professor with PhD
    if (name.startsWith('Dr.') && position.contains('Lecturer')) return 5; // Lecturer with PhD
    if (position.contains('Professor')) return 6; // Professor without PhD
    if (position.contains('Lecturer')) return 7; // Lecturer without PhD
    return 8; // Other
  }

  @override
  void initState() {
    super.initState();
    mockTeachers.sort((a, b) => _getTeacherRank(a).compareTo(_getTeacherRank(b)));
    final now = DateTime.now();
    final formattedDay = DateFormat('EEEE').format(now);
    const validDays = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
    _selectedDay = validDays.contains(formattedDay) ? formattedDay : 'Monday';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Updated PDF Generation Logic
  Future<void> _generateAndOpenFile(Map<String, dynamic> teacher) async {
    final pdf = pw.Document();
    final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    final teacherName = teacher['name'] as String;
    final routine = teacher['routine'] as Map<String, List<Map<String, dynamic>>>;

    final image = pw.MemoryImage(
      (await rootBundle.load('assets/images/Itm_logo.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(image, width: 100, height: 100),
              pw.SizedBox(height: 10),
              pw.Text('Department of Information Technology and Management', textAlign: pw.TextAlign.center),
              pw.Text('Faculty of Science and Information Technology', textAlign: pw.TextAlign.center),
              pw.Text('Daffodil International University', textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 20),
              pw.Text('Class Routine for $teacherName', style: boldStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 5),
            ],
          ),
        ),
        build: (context) {
          final List<pw.Widget> dayTables = [];
          routine.forEach((day, classes) {
            dayTables.add(pw.Header(level: 1, text: day, textStyle: boldStyle));
            dayTables.add(pw.SizedBox(height: 10));

            final List<List<String>> tableData = [];
            for (final classItem in classes) {
              tableData.add([
                '${classItem['courseName']} (${classItem['courseCode']})',
                classItem['time']!,
                classItem['room']!,
                classItem['batch']!,
              ]);
            }

            dayTables.add(
              pw.Table.fromTextArray(
                headers: ['Course', 'Time Slot', 'Room', 'Batch'],
                data: tableData,
                headerStyle: boldStyle.copyWith(color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal700,
                ),
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(fontSize: 10),
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
              ),
            );
            dayTables.add(pw.SizedBox(height: 20));
          });

          if (dayTables.isEmpty) {
            return [pw.Center(child: pw.Text('No routine available for this teacher.'))];
          }

          return dayTables;
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$teacherName-routine.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

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

  @override
  Widget build(BuildContext context) {
    // Filter teachers based on search query
    final filteredTeachers = _searchQuery.isEmpty
        ? mockTeachers
        : mockTeachers.where((teacher) {
            final name = (teacher['name'] as String).toLowerCase();
            final position = (teacher['position'] as String).toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || position.contains(query);
          }).toList();

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
                  hintText: 'Search teacher by name or position...',
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
                    _showDailyRoutineIndex = null;
                  });
                },
              ),
            ),
          ),
          // Teacher List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: filteredTeachers.length,
              itemBuilder: (context, index) {
                final teacher = filteredTeachers[index];
                final isSelected = _selectedIndex == index;
                final showDailyRoutine = _showDailyRoutineIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIndex = null;
                        _showDailyRoutineIndex = null;
                      } else {
                        _selectedIndex = index;
                        _showDailyRoutineIndex = null;
                      }
                    });
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Collapsed View
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blueGrey,
                                backgroundImage: (teacher['image'] != null && (teacher['image'] as String).isNotEmpty && !(teacher['image'] as String).contains('placehold.co'))
                                    ? NetworkImage(teacher['image'] as String)
                                    : null,
                                child: (teacher['image'] == null || (teacher['image'] as String).isEmpty || (teacher['image'] as String).contains('placehold.co'))
                                    ? Text(
                                        _getInitials(teacher['name'] as String),
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(teacher['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(teacher['position'] as String, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
                                  title: Text(teacher['email'] as String),
                                  onTap: () => _launchEmail(teacher['email'] as String),
                                  dense: true,
                                ),
                                const Divider(),
                                // Action Buttons
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(showDailyRoutine ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                          label: const Text('Daily Routine'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (showDailyRoutine) {
                                                _showDailyRoutineIndex = null;
                                              } else {
                                                _showDailyRoutineIndex = index;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8), // Add some spacing between buttons
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.picture_as_pdf_outlined),
                                          label: const Text('Get Full PDF'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            _generateAndOpenFile(teacher);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Daily Routine Display
                                if (showDailyRoutine)
                                  Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      _buildDaySelector(),
                                      const SizedBox(height: 16),
                                      _buildRoutineList(teacher['name']),
                                    ],
                                  ).animate().fadeIn(),
                              ],
                            ).animate().fadeIn(delay: 100.ms),
                        ],
                      ),
                    ),
                  ),
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(day.substring(0, 3)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDay = day);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.teal.withOpacity(0.8),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineList(String teacherName) {
    final teacher = mockTeachers.firstWhere((t) => t['name'] == teacherName);
    final routineForDay = (teacher['routine'] as Map<String, List<Map<String, String>>>)[_selectedDay] ?? [];

    if (routineForDay.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No classes scheduled for this day.')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routineForDay.length,
      itemBuilder: (context, index) {
        final classItem = routineForDay[index];
        return _buildTimelineTile(
          classItem: classItem,
          isFirst: index == 0,
          isLast: index == routineForDay.length - 1,
        );
      },
    );
  }

  Widget _buildTimelineTile({required Map<String, String> classItem, required bool isFirst, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.teal,
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                ),
                child: const Icon(Icons.class_, color: Colors.white, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.teal,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classItem['courseName']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classItem['courseCode']!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(classItem['time']!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Room: ${classItem['room']!}'),
                      ],
                    ),
                     const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Batch: ${classItem['batch']!}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
