import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:itm_connect/models/notice.dart';
import 'package:itm_connect/models/exam_routine.dart';
import 'package:itm_connect/services/notice_service.dart';
import 'package:itm_connect/services/exam_routine_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:itm_connect/theme/app_colors.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final NoticeService _noticeService = NoticeService();
  final ExamRoutineService _examService = ExamRoutineService();

  // Filter
  String _selectedBatch = 'All';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final headerFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final headerPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 18.0 : 22.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header Section sticking to top
            Container(
              decoration: BoxDecoration(
                gradient: ITMColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: ITMColors.gradientStart.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          headerPadding, headerPadding, headerPadding, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: iconSize + 6,
                              height: iconSize + 6,
                              child: CustomPaint(
                                painter: _MegaphoneIconPainter(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Announcements',
                                style: TextStyle(
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Notices & Exam Schedules', // Update subtitle
                                style: TextStyle(
                                  fontSize: subtitleFontSize,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16),
                      tabs: [
                        const Tab(
                            text: "Notices",
                            icon: Icon(Icons.notifications_none)),
                        Tab(
                          text: "Exam Routine",
                          icon: Builder(
                            builder: (context) {
                              final iconColor = IconTheme.of(context).color ?? Colors.white;
                              return SizedBox(
                                width: 24,
                                height: 24,
                                child: CustomPaint(
                                  painter: _CalendarIconPainter(color: iconColor),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildNoticesTab(),
                  _buildExamRoutineTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesTab() {
    return StreamBuilder<List<Notice>>(
      stream: _noticeService.streamAllNotices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final notices = snapshot.data ?? [];
        if (notices.isEmpty)
          return const Center(child: Text('No notices available.'));

        // Sort notices, newest first
        notices.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 90),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            return _buildNoticeCard(notices[index])
                .animate()
                .fadeIn(delay: (50 * index).ms)
                .slideY(begin: 0.1);
          },
        );
      },
    );
  }

  Widget _buildExamRoutineTab() {
    return StreamBuilder<List<ExamRoutine>>(
      stream: _examService.streamAllExamRoutines(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final allRoutines = snapshot.data ?? [];

        // Extract unique batches dynamically
        final uniqueBatches = allRoutines.map((e) => e.batch).toSet().toList()
          ..sort();
        final dropdownBatches = ['All', ...uniqueBatches];

        // Filter for display
        var displayRoutines = allRoutines;
        if (_selectedBatch != 'All') {
          displayRoutines =
              displayRoutines.where((r) => r.batch == _selectedBatch).toList();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            // Filter & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? ITMColors.darkCard : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? ITMColors.darkSurface : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? ITMColors.darkCardBorder : Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dropdownBatches.contains(_selectedBatch)
                              ? _selectedBatch
                              : 'All',
                          isExpanded: true,
                          icon:
                              const Icon(Icons.filter_list, color: Colors.teal),
                          hint: const Text('Filter by Batch'),
                          items: dropdownBatches.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'All' ? 'All Batches' : 'Batch $value',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedBatch = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // PDF Download Button
                  if (_selectedBatch != 'All' && displayRoutines.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _generateAndOpenPdf(
                            displayRoutines, _selectedBatch),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50), // Corporate Blue
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (displayRoutines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                          _selectedBatch == 'All'
                              ? (allRoutines.isEmpty
                                  ? 'No exam schedules posted.'
                                  : 'No exams found.')
                              : 'No exams for Batch $_selectedBatch.',
                          style:
                              TextStyle(color: isDark ? ITMColors.darkTextSecondary : Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 90),
                  itemCount: displayRoutines.length,
                  itemBuilder: (context, index) {
                    return _buildExamRoutineCard(displayRoutines[index])
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.1);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoticeCard(Notice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCard : ITMColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkSurface : Colors.teal.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCardBorder : Colors.teal.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCardBorder : Colors.teal.shade200),
                  ),
                  child: Text(
                    notice.date,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.body,
                  style: TextStyle(
                      fontSize: 14, height: 1.5, color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextPrimary : Colors.black87),
                ),
                if (notice.attachment != null &&
                    notice.attachment!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(notice.attachment!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkSurface : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCardBorder : Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attachment, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text('View Attachment',
                              style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRoutineCard(ExamRoutine routine) {
    // Determine card accent color dynamically based on batch or just constant corporate color
    final accentColor = const Color(0xFF2C3E50);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? ITMColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Date Strip
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDay(routine.date),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getMonth(routine.date),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      routine.date.split('-')[0], // Year
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            routine.courseName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? ITMColors.darkTextPrimary : Colors.black87,
                            ),
                          ),
                        ),
                        // Batch Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Batch ${routine.batch}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      routine.examTitle, // "Mid Term..."
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),

                    // Details Row
                    Row(
                      children: [
                        Expanded(
                          child: _infoItem(Icons.access_time, routine.time),
                        ),
                        Expanded(
                          child: _infoItem(
                              Icons.location_on, 'Room ${routine.room}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextPrimary : Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getDay(String date) {
    try {
      final dt = DateTime.parse(date);
      return dt.day.toString();
    } catch (e) {
      return '';
    }
  }

  String _getMonth(String date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    try {
      final dt = DateTime.parse(date);
      return months[dt.month - 1];
    } catch (e) {
      return '';
    }
  }

  Future<void> _generateAndOpenPdf(
      List<ExamRoutine> routines, String batch) async {
    final pdf = pw.Document();

    // Fonts
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    // Colors (Official DIU)
    const PdfColor diuBlue = PdfColor.fromInt(0xFF2E3094);
    const PdfColor diuGreen = PdfColor.fromInt(0xFF50B748);

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/itm.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint("PDF Logo not found: $e");
    }

    // Sort logic for PDF (by Date)
    routines.sort((a, b) => a.date.compareTo(b.date));

    pdf.addPage(
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
                "EXAM SCHEDULE REPORT",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: diuBlue,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),

              // Batch Info
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF3F4F6), // Light gray background
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Text(
                  "Batch: ${batch.toUpperCase()}",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
            ],
          );
        },
        build: (pw.Context context) {
          final tableHeader = ['Date', 'Time', 'Course', 'Title', 'Room'];

          final tableData = routines
              .map((r) => [
                    r.date,
                    r.time,
                    '${r.courseName}\n(${r.courseCode})',
                    r.examTitle,
                    r.room
                  ])
              .toList();

          return [
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
              headerPadding:
                  const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8), // Date
                1: const pw.FlexColumnWidth(2.0), // Time
                2: const pw.FlexColumnWidth(3.5), // Course
                3: const pw.FlexColumnWidth(2.0), // Title
                4: const pw.FlexColumnWidth(1.0), // Room
              },
            ),
          ];
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

    // Preview/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Exam_Routine_Batch_$batch.pdf',
    );
  }
}

class _MegaphoneIconPainter extends CustomPainter {
  final Color color;
  const _MegaphoneIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Mouthpiece (vertical capsule on the left)
    final mouthpiece = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.08, h * 0.30),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(mouthpiece, paint);

    // 2. Handle (angled downwards)
    final handlePath = Path();
    handlePath.moveTo(w * 0.35, h * 0.55);
    handlePath.lineTo(w * 0.38, h * 0.85);
    handlePath.lineTo(w * 0.46, h * 0.84);
    handlePath.lineTo(w * 0.43, h * 0.52);
    handlePath.close();
    canvas.drawPath(handlePath, paint);

    // 3. Main Cone (trapezoid body)
    final conePath = Path();
    conePath.moveTo(w * 0.23, h * 0.40);
    conePath.lineTo(w * 0.65, h * 0.20);
    conePath.lineTo(w * 0.65, h * 0.80);
    conePath.lineTo(w * 0.23, h * 0.60);
    conePath.close();
    canvas.drawPath(conePath, paint);

    // 4. Front Opening (vertical capsule at the right end of the cone)
    final opening = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.61, h * 0.16, w * 0.08, h * 0.68),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(opening, paint);

    // 5. Sound waves / arcs (blast)
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // First small wave
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.45, h * 0.50), radius: w * 0.32),
      -0.6, // Start angle (in radians)
      1.2,  // Sweep angle (in radians)
      false,
      strokePaint,
    );

    // Second larger wave
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.45, h * 0.50), radius: w * 0.45),
      -0.6,
      1.2,
      false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MegaphoneIconPainter old) => old.color != color;
}

class _CalendarIconPainter extends CustomPainter {
  final Color color;
  const _CalendarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Outline body:
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final outlineBody = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.24, w * 0.64, h * 0.62),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(outlineBody, strokePaint);

    // 2. Header line inside calendar:
    canvas.drawLine(
      Offset(w * 0.18, h * 0.45),
      Offset(w * 0.82, h * 0.45),
      strokePaint,
    );

    // 3. Two binder rings / nubs at the top:
    final nubPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final nub1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.32, h * 0.10, w * 0.08, h * 0.22),
      Radius.circular(w * 0.03),
    );
    final nub2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.60, h * 0.10, w * 0.08, h * 0.22),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(nub1, nubPaint);
    canvas.drawRRect(nub2, nubPaint);

    // 4. Simple event notes / bullet lines inside the calendar sheet:
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.58, w * 0.36, h * 0.07),
        Radius.circular(w * 0.02),
      ),
      dotPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.72, w * 0.24, h * 0.07),
        Radius.circular(w * 0.02),
      ),
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalendarIconPainter old) => old.color != color;
}
