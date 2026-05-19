import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/routine.dart';
import '../models/batch.dart';
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
    String? departmentName,
    BatchInfo? batchInfo,
    String? teacherName,
    String? teacherRole,
    String? teacherEmail,
    String? teacherInitial,
    List<String>? consultingHours,
  }) async {
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/itm.png');
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
        margin: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular],
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 5),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Logo on the left
                  if (logoImage != null)
                    pw.Container(
                      width: 70,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),

                  // Branding on the right
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Daffodil International University",
                        style: pw.TextStyle(
                          color: diuBlue,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (departmentName != null)
                        pw.Text(
                          "Department of $departmentName",
                          style: pw.TextStyle(
                            color: diuBlue,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      pw.SizedBox(height: 1),
                      pw.Container(
                        height: 2,
                        width: 150,
                        color: diuGreen,
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Formal Document Title
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: diuBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      height: 1,
                      width: 60,
                      color: diuGreen,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Profile Information Card (Teacher or Batch)
              if (teacherName != null || batchName != null)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border:
                        pw.Border.all(color: diuBlue.shade(0.1), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Section: Name and Role
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  teacherName ??
                                      "Class Schedule for Batch: ${batchName?.toUpperCase()}",
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: diuBlue,
                                  ),
                                ),
                                if (teacherRole != null || batchInfo != null)
                                  pw.Text(
                                    (teacherRole ??
                                            "Session: ${batchInfo?.session}")
                                        .toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.grey600,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (teacherInitial != null || batchName != null)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: diuBlue,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    teacherInitial != null
                                        ? "INITIAL"
                                        : "BATCH",
                                    style: pw.TextStyle(
                                        fontSize: 6,
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    teacherInitial ?? batchName!,
                                    style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.white),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      pw.SizedBox(height: 8),
                      pw.Container(
                          height: 0.5,
                          width: double.infinity,
                          color: PdfColors.grey200),
                      pw.SizedBox(height: 8),

                      // Details Section
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (teacherEmail != null)
                            pw.Expanded(
                              flex: 2,
                              child: _detailItem("EMAIL ADDRESS", teacherEmail),
                            ),
                          if (batchInfo != null) ...[
                            pw.Expanded(
                                child: _detailItem(
                                    "ADVISOR", batchInfo.advisorName)),
                            if (batchInfo.totalStudents.isNotEmpty)
                              pw.Expanded(
                                  child: _detailItem(
                                      "STUDENTS", batchInfo.totalStudents)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              if (teacherName == null &&
                  batchName == null &&
                  subtitle.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic),
                  ),
                ),

              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> pdfContent = [];

          for (String day in weekDays) {
            // Find routines for this day
            final dayRoutines = routines
                .where((r) =>
                    _getFullDayName(r.day).toLowerCase() == day.toLowerCase())
                .toList();

            // Flatten all classes for this day
            final List<Map<String, String>> dayClasses = [];
            for (var r in dayRoutines) {
              for (var c in r.classes) {
                dayClasses.add({
                  'time': c.time,
                  'course': '${c.courseName} (${c.courseCode})',
                  'room': c.room,
                  'details': batchName != null
                      ? c.teacherInitial
                      : r.batch, // If student routine, show teacher. If teacher routine, show batch.
                  'label': batchName != null ? 'Teacher' : 'Batch',
                });
              }
            }

            if (dayClasses.isNotEmpty) {
              // Sort day classes by time
              dayClasses.sort((a, b) => _getMinutes(a['time'] ?? '')
                  .compareTo(_getMinutes(b['time'] ?? '')));

              // Day Header with Side Tab Style
              pdfContent.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
                  padding: const pw.EdgeInsets.only(left: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: diuGreen, width: 4),
                    ),
                  ),
                  child: pw.Text(
                    day.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: diuBlue,
                    ),
                  ),
                ),
              );

              final tableHeader = [
                'TIME',
                'COURSE NAME & CODE',
                'ROOM',
                batchName != null ? 'TEACHER' : 'BATCH'
              ];

              final tableData = dayClasses
                  .map((e) => [
                        formatTo12Hr(e['time'] ?? ''),
                        e['course'] ?? '',
                        e['room'] ?? '',
                        e['details'] ?? '',
                      ])
                  .toList();

              pdfContent.add(
                pw.Table.fromTextArray(
                  headers: tableHeader,
                  data: tableData,
                  headerStyle: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(color: diuBlue),
                  headerPadding:
                      const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  cellStyle:
                      const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
                  cellPadding:
                      const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  cellAlignment: pw.Alignment.centerLeft,

                  // Zebra Striping
                  cellDecoration: (index, data, rowNum) {
                    if (rowNum == 0)
                      return const pw.BoxDecoration(color: diuBlue);
                    return pw.BoxDecoration(
                      color: rowNum % 2 == 0
                          ? PdfColor.fromInt(0xFFF9FAFB)
                          : PdfColors.white,
                    );
                  },

                  // Border Styling (Removing vertical borders for corporate look)
                  border: pw.TableBorder(
                    horizontalInside:
                        pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    left: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    right: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),

                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(5.5),
                    2: const pw.FlexColumnWidth(0.8),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                ),
              );
              pdfContent.add(pw.SizedBox(height: 3));
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
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
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
      if (inputTime.contains('AM') || inputTime.contains('PM'))
        return inputTime;

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

  static pw.Widget _vDivider() {
    return pw.Container(
      height: 10,
      width: 1,
      color: PdfColors.grey400,
      margin: const pw.EdgeInsets.symmetric(horizontal: 15),
    );
  }

  static pw.Widget _detailItem(String label, String value) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value.isEmpty ? "N/A" : value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }
}
