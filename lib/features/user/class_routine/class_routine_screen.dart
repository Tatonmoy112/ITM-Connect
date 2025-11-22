import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart'; // For mapIndexed
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/pdf_download_service.dart';

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
    if (selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

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

      // Fetch all routine data from Firebase first
      final Map<String, List<List<String>>> classesByDay = {};
      for (final day in days) {
        final routineId = '${selectedBatch}_$day';
        final routine = await _routineService.getRoutine(routineId);

        if (routine != null && routine.classes.isNotEmpty) {
          classesByDay[day] = [];
          for (final classItem in routine.classes) {
            classesByDay[day]!.add([
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
            if (classesByDay.isEmpty) {
              return [pw.Center(child: pw.Text('No routine available for this batch.'))];
            }
            
            final widgets = <pw.Widget>[];
            
            // Create separate table for each day
            for (final day in days) {
              final dayClasses = classesByDay[day];
              
              if (dayClasses != null && dayClasses.isNotEmpty) {
                widgets.add(
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(day, style: boldStyle.copyWith(fontSize: 13, color: PdfColors.teal700)),
                      pw.SizedBox(height: 5),
                      pw.Table.fromTextArray(
                        headers: ['Course', 'Time Slot', 'Room', 'Teacher Initial'],
                        data: dayClasses,
                        headerStyle: boldStyle.copyWith(color: PdfColors.white, fontSize: 10),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.teal700,
                        ),
                        cellAlignment: pw.Alignment.center,
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(2.5),
                          2: const pw.FlexColumnWidth(1.5),
                          3: const pw.FlexColumnWidth(1.5),
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

      final fileName = 'Batch${selectedBatch}_Weekly_Routine.pdf';
      
      // Save PDF using cross-platform service and open it
      final pdfBytes = await pdf.save();
      await PdfDownloadService.downloadAndOpenPdf(
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 22.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);
    
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
        child: Column(
          children: [
            // Header Card with Batch Input and Day Selector
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
                      // Teal Header
                      Container(
                        width: double.infinity,
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
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class Routine',
                                style: TextStyle(
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select batch and day to view schedule',
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Body Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Batch Input
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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

                            const SizedBox(height: 12),

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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),

            // Routine Content Card
            if (selectedBatch == null || selectedDay == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Please enter batch and select day.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ).animate().fadeIn(),
                    ),
                  ),
                ),
              ),

            if (routineId != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: StreamBuilder<Routine?>(
                    stream: _routineService.streamRoutine(routineId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
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
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final routine = snapshot.data;

                      if (routine == null || routine.classes.isEmpty) {
                        return Container(
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
                          child: Padding(
                            padding: const EdgeInsets.all(20),
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
                        );
                      }

                      return Column(
                        children: routine.classes.mapIndexed((index, classItem) {
                          return Animate(
                            effects: [
                              FadeEffect(duration: 300.ms, delay: (index * 100).ms),
                              SlideEffect(begin: const Offset(0, 0.2), duration: 300.ms),
                            ],
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                                classItem.courseName,
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
                                                'Code: ${classItem.courseCode}',
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            classItem.courseCode,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
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
                                            const Icon(Icons.schedule, size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                classItem.time,
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Teacher: ${classItem.teacherInitial.isNotEmpty ? classItem.teacherInitial : '-'}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Room: ${classItem.room}',
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


