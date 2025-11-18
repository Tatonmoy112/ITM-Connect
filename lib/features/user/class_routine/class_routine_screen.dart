import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart'; // For mapIndexed
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';

class ClassRoutineScreen extends StatefulWidget {
  const ClassRoutineScreen({super.key});

  @override
  State<ClassRoutineScreen> createState() => _ClassRoutineScreenState();
}

class _ClassRoutineScreenState extends State<ClassRoutineScreen> {
  int? selectedBatch;
  String? selectedDay;

  final List<String> days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  final RoutineService _routineService = RoutineService();

  Future<void> _generateAndOpenFile() async {
    if (selectedBatch == null) return;

    final pdf = pw.Document();
    final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    final headers = ['Day', 'Course', 'Time Slot', 'Room', 'Teacher Initial'];

    final image = pw.MemoryImage(
      (await rootBundle.load('assets/images/Itm_logo.png')).buffer.asUint8List(),
    );

    // Fetch all routine data from Firebase first
    final List<List<String>> allTableData = [];
    for (final day in days) {
      final routineId = '${selectedBatch}_$day';
      final routine = await _routineService.getRoutine(routineId);

      if (routine != null && routine.classes.isNotEmpty) {
        for (final classItem in routine.classes) {
          allTableData.add([
            day,
            '${classItem.courseName} (${classItem.courseCode})',
            classItem.time,
            classItem.room,
            classItem.teacherInitial,
          ]);
        }
      }
    }

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
              pw.Text('Class Routine for Batch $selectedBatch', style: boldStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        build: (context) {
          if (allTableData.isEmpty) {
            return [pw.Center(child: pw.Text('No routine available for this batch.'))];
          }
          
          return [
            pw.Table.fromTextArray(
              headers: headers,
              data: allTableData,
              headerStyle: boldStyle.copyWith(color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.teal700,
              ),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 10),
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Batch${selectedBatch}_Weekly_Routine.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }


  @override
  void initState() {
    super.initState();
    final today = DateFormat('EEE').format(DateTime.now());
    if (days.contains(today)) {
      selectedDay = today;
    } else {
      selectedDay = days.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineId = selectedBatch != null && selectedDay != null
        ? '${selectedBatch}_$selectedDay'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: selectedBatch != null
          ? FloatingActionButton(
              onPressed: () {
                _generateAndOpenFile();
              },
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.picture_as_pdf),
            ).animate().scale()
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Batch Input
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter Batch Number',
                    prefixIcon: Icon(Icons.group),
                  ),
                  onChanged: (value) {
                    final batch = int.tryParse(value);
                    if (batch != null && batch > 0) {
                      setState(() => selectedBatch = batch);
                    }
                  },
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // Day Selector
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isSelected = selectedDay == day;
                    return GestureDetector(
                      onTap: () => setState(() => selectedDay = day),
                      child: AnimatedContainer(
                        duration: 300.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.shade500 : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ).animate().slideX(begin: 1).fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            if (selectedBatch == null || selectedDay == null)
              const Text(
                'Please enter batch and select day.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ).animate().fadeIn(),

            if (routineId != null)
              StreamBuilder<Routine?>(
                stream: _routineService.streamRoutine(routineId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final routine = snapshot.data;

                  if (routine == null || routine.classes.isEmpty) {
                    return Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 400)),
                        SlideEffect(begin: Offset(0, 0.1))
                      ],
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange, size: 28),
                                  SizedBox(width: 10),
                                  Text(
                                    'No Classes Today',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Class Time: 8:30 AM – 4:00 PM',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Each class duration: 1 hour 30 minutes.',
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: routine.classes.mapIndexed((index, classItem) {
                      return Animate(
                        effects: [
                          FadeEffect(duration: 300.ms, delay: (index * 100).ms),
                          SlideEffect(begin: const Offset(0, 0.2), duration: 300.ms),
                        ],
                        child: RoutineClassCard(
                          time: classItem.time,
                          courseName: classItem.courseName,
                          courseCode: classItem.courseCode,
                          teacherInitial: classItem.teacherInitial,
                          room: classItem.room,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Renamed GlassCard to RoutineClassCard
class RoutineClassCard extends StatelessWidget {
  final String time;
  final String courseName;
  final String courseCode;
  final String teacherInitial;
  final String room;

  const RoutineClassCard({
    super.key,
    required this.time,
    required this.courseName,
    required this.courseCode,
    required this.teacherInitial,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Animate(
          effects: [
            FadeEffect(duration: 300.ms, delay: 50.ms),
            SlideEffect(begin: Offset(0, 0.1), duration: 300.ms),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading with course name and code
              Row(
                children: [
                  const Icon(Icons.class_rounded, size: 22, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    '$courseName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      courseCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 22, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 22, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(teacherInitial.isNotEmpty ? teacherInitial : '-', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 22, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Room: $room', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


