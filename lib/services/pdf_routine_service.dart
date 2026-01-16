import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/routine.dart';
import 'package:intl/intl.dart';

class PdfRoutineService {
  // Official DIU Colors
  static const PdfColor diuBlue = PdfColor.fromInt(0xFF2E3094);
  static const PdfColor diuGreen = PdfColor.fromInt(0xFF50B748);

  static Future<void> generateRoutinePdf({
    required List<Routine> routines,
    required String title,
    required String subtitle,
    String? batchName,
    String? teacherName,
    String? teacherRole,
    String? consultingHour,
  }) async {
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/PDF_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print("PDF Logo not found: $e");
    }

    final doc = pw.Document();
    
    final List<String> weekDays = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular],
        ),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 80,
                  alignment: pw.Alignment.center,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Daffodil International University",
                style: pw.TextStyle(
                  color: diuBlue,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 1.5,
                color: diuGreen,
                width: double.infinity,
              ),
              pw.SizedBox(height: 12),
              
              // Title of the document
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: diuBlue,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),

              // Profile Information Box (Teacher or Batch)
              if (teacherName != null || batchName != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3F4F6), // Light gray background
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        teacherName ?? "Batch: ${batchName?.toUpperCase()}",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      if (teacherRole != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          teacherRole,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey800,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                      if (consultingHour != null && consultingHour.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              "Consulting Hour: ",
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: diuBlue,
                              ),
                            ),
                             pw.Text(
                              consultingHour,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (subtitle.isNotEmpty) 
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
                
              pw.SizedBox(height: 15),
            ],
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> pdfContent = [];

          for (String day in weekDays) {
            // Find routines for this day
            final dayRoutines = routines.where((r) => _getFullDayName(r.day).toLowerCase() == day.toLowerCase()).toList();
            
            // Flatten all classes for this day
            final List<Map<String, String>> dayClasses = [];
            for (var r in dayRoutines) {
              for (var c in r.classes) {
                dayClasses.add({
                  'time': c.time,
                  'course': '${c.courseName} (${c.courseCode})',
                  'room': c.room,
                  'details': batchName != null ? c.teacherInitial : r.batch, // If student routine, show teacher. If teacher routine, show batch.
                  'label': batchName != null ? 'Teacher' : 'Batch',
                });
              }
            }

            if (dayClasses.isNotEmpty) {
              // Sort day classes by time
              dayClasses.sort((a, b) => _getMinutes(a['time'] ?? '').compareTo(_getMinutes(b['time'] ?? '')));

              pdfContent.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: const pw.BoxDecoration(
                    color: diuGreen,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    day.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              );

              final tableHeader = ['Time', 'Course', 'Room', batchName != null ? 'Teacher' : 'Batch'];
              
              final tableData = dayClasses.map((e) => [
                formatTo12Hr(e['time'] ?? ''),
                e['course'] ?? '',
                e['room'] ?? '',
                e['details'] ?? '',
              ]).toList();

              pdfContent.add(
                pw.Table.fromTextArray(
                  headers: tableHeader,
                  data: tableData,
                  border: pw.TableBorder.all(color: diuBlue, width: 0.5),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: diuBlue),
                  headerPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                  cellAlignment: pw.Alignment.centerLeft,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(4.5),
                    2: const pw.FlexColumnWidth(0.8),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                ),
              );
              pdfContent.add(pw.SizedBox(height: 12));
            }
          }
          
          if (pdfContent.isEmpty) {
            pdfContent.add(pw.Center(child: pw.Text("No classes scheduled.")));
          }
          
          return pdfContent;
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text(
                    'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }

  static String _getFullDayName(String shortDay) {
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

  static int _getMinutes(String timeStr) {
    if (timeStr.isEmpty) return 99999;
    timeStr = timeStr.trim().toUpperCase();
    
    // Handle "8:30 - 10:00" format by taking the first part
    if (timeStr.contains('-')) {
      timeStr = timeStr.split('-')[0].trim();
    }

    try {
      final double? serial = double.tryParse(timeStr);
      if (serial != null) return (serial * 24 * 60).round();
      
      // Handle "13:00" or "8:30 AM"
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
         final parts = timeStr.split(RegExp(r'\s+'));
         final timePart = parts[0];
         final period = parts[1];
         final timeBits = timePart.split(':');
         var hour = int.parse(timeBits[0]);
         final minute = timeBits.length > 1 ? int.parse(timeBits[1]) : 0;
         if (period == 'PM' && hour != 12) hour += 12;
         if (period == 'AM' && hour == 12) hour = 0;
         return hour * 60 + minute;
      } else {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        }
      }
      return 99999;
    } catch (e) {
      return 99999;
    }
  }

  static String formatTo12Hr(String inputTime) {
    if (inputTime.isEmpty) return "";
    inputTime = inputTime.trim().toUpperCase();
    
    // Handle ranges: "8:30 - 10:00"
    if (inputTime.contains('-')) {
      final parts = inputTime.split('-');
      return '${formatTo12Hr(parts[0])} - ${formatTo12Hr(parts[1])}';
    }

    try {
      final double? serialTime = double.tryParse(inputTime);
      if (serialTime != null) {
        int totalMinutes = (serialTime * 24 * 60).round();
        int hour = (totalMinutes ~/ 60) % 24;
        int minute = totalMinutes % 60;
        return _formatHourMinute(hour, minute);
      }
      
      // If already has AM/PM, return as is
      if (inputTime.contains('AM') || inputTime.contains('PM')) return inputTime;

      final parts = inputTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return _formatHourMinute(hour, minute);
      }
      return inputTime;
    } catch (e) {
      return inputTime;
    }
  }

  static String _formatHourMinute(int hour, int minute) {
    String period = "AM";
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }
    return "$hour:${minute.toString().padLeft(2, '0')} $period";
  }
}
