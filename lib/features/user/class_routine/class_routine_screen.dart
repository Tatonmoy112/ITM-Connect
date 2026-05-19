import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart'; // For mapIndexed
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/pdf_routine_service.dart';
import 'package:itm_connect/services/batch_service.dart';
import 'package:itm_connect/theme/app_colors.dart';

class ClassRoutineScreen extends StatefulWidget {
  const ClassRoutineScreen({super.key});

  @override
  State<ClassRoutineScreen> createState() => _ClassRoutineScreenState();
}

class _ClassRoutineScreenState extends State<ClassRoutineScreen> {
  String? selectedBatch;
  String? selectedDay;

  final List<String> days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  final RoutineService _routineService = RoutineService();
  final BatchService _batchService = BatchService();
  List<String> _allBatches = [];
  StreamSubscription? _batchSubscription;

  // Helper method to extract start time for sorting
  String _extractStartTime(String timeRange) {
    // Expects format like "8:30 AM - 10:00 AM" or "8:30 AM"
    final parts = timeRange.split('-');
    String startTime = parts.isNotEmpty ? parts[0].trim() : timeRange.trim();

    // Handle the formatTo12Hr logic for serial/raw times if needed
    startTime = formatTo12Hr(startTime);

    // Convert to 24-hour format for proper sorting
    return _convertTo24Hour(startTime);
  }

  // User provided helper for time formatting
  String formatTo12Hr(String inputTime) {
    if (inputTime.isEmpty) return "";
    inputTime = inputTime.trim();
    try {
      // Handle serial time from Excel/Sheets
      final double? serialTime = double.tryParse(inputTime);
      if (serialTime != null) {
        int totalMinutes = (serialTime * 24 * 60).round();
        int hour = (totalMinutes ~/ 60) % 24;
        int minute = totalMinutes % 60;
        return _formatHourMinute(hour, minute);
      }

      // Handle 24h string like "13:00" or "8:30"
      if (!inputTime.toUpperCase().contains('AM') &&
          !inputTime.toUpperCase().contains('PM')) {
        final bits = inputTime.split(':');
        if (bits.isNotEmpty) {
          int hour = int.tryParse(bits[0]) ?? 0;
          int minute = bits.length > 1 ? (int.tryParse(bits[1]) ?? 0) : 0;
          return _formatHourMinute(hour, minute);
        }
      }

      return inputTime;
    } catch (e) {
      return inputTime;
    }
  }

  String _formatHourMinute(int hour, int minute) {
    String period = "AM";
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$hour:$minuteStr $period";
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

  String _shortDay(String day) {
    switch (day.trim().toLowerCase()) {
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      default:
        if (day.length >= 3) {
          return day.substring(0, 1).toUpperCase() +
              day.substring(1, 3).toLowerCase();
        }
        return day;
    }
  }

  Future<void> _generateAndOpenFile() async {
    final batch = selectedBatch;
    if (batch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

    // Check internet connectivity before PDF generation
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please turn on your internet connection to download PDF.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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

      // Fetch all routine data for this batch
      final List<Routine> batchRoutines = [];
      for (final day in days) {
        final routineId = '${batch.trim().toUpperCase()}_${_shortDay(day)}';
        final routine = await _routineService.getRoutine(routineId);
        if (routine != null && routine.classes.isNotEmpty) {
          batchRoutines.add(routine);
        }
      }

      if (mounted) Navigator.pop(context); // Hide loading

      if (batchRoutines.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No routine data found for this batch.')),
          );
        }
        return;
      }

      // Fetch batch info from database
      final batchInfo = await _batchService.getBatchInfo(batch);

      await PdfRoutineService.generateRoutinePdf(
        routines: batchRoutines,
        title: "Weekly Class Schedule",
        subtitle: "Batch: ${batch.toUpperCase()}",
        batchName: batch,
        departmentName: "Information Technology & Management",
        batchInfo: batchInfo,
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
  void initState() {
    super.initState();
    final today = DateFormat('EEE').format(DateTime.now());
    if (days.contains(today)) {
      selectedDay = today;
    } else {
      selectedDay = days.first;
    }
    _initBatchSuggestions();
  }

  void _initBatchSuggestions() {
    // Combine batches from both Routines and Batch Metadata for maximum coverage
    _routineService.streamAllBatches().listen((batches) {
      if (mounted) {
        _updateAllBatches(batches);
      }
    });

    _batchService.streamAllBatchIds().listen((batches) {
      if (mounted) {
        _updateAllBatches(batches);
      }
    });
  }

  void _updateAllBatches(List<String> newBatches) {
    setState(() {
      final combined = {..._allBatches, ...newBatches};
      _allBatches = combined.toList()..sort();
      debugPrint("Updated suggestions: ${_allBatches.length} batches loaded.");
    });
  }

  @override
  void dispose() {
    _batchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth =
        isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 22.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 8.0 : (isTablet ? 10.0 : 12.0);

    final batch = selectedBatch;
    final day = selectedDay;
    final routineId = batch != null && day != null
        ? '${batch.trim().toUpperCase()}_${_shortDay(day)}'
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: selectedBatch != null
          ? FloatingActionButton(
              onPressed: () {
                _generateAndOpenFile();
              },
              backgroundColor: ITMColors.gradientStart,
              foregroundColor: Colors.white,
              child: const Icon(Icons.picture_as_pdf),
            ).animate().scale()
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with Batch Input and Day Selector
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: horizontalPadding),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCard : ITMColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.black : ITMColors.gradientStart).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
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
                          gradient: ITMColors.brandGradient,
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
                            // Batch Input with Autocomplete
                            Card(
                              color: isDark ? ITMColors.darkCard : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Autocomplete<String>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }
                                    final query = textEditingValue.text
                                        .toUpperCase()
                                        .trim();
                                    return _allBatches.where((String option) {
                                      return option
                                          .toUpperCase()
                                          .contains(query);
                                    });
                                  },
                                  onSelected: (String selection) {
                                    setState(() {
                                      selectedBatch = selection;
                                    });
                                  },
                                  fieldViewBuilder: (context, textController,
                                      focusNode, onFieldSubmitted) {
                                    return TextField(
                                      controller: textController,
                                      focusNode: focusNode,
                                      keyboardType: TextInputType.text,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Enter Your Batch',
                                        prefixIcon: Icon(Icons.group),
                                      ),
                                      onChanged: (value) {
                                        // Update selectedBatch for the PDF button visibility
                                        setState(() {
                                          selectedBatch =
                                              value.trim().isNotEmpty
                                                  ? value.trim()
                                                  : null;
                                        });
                                      },
                                    );
                                  },
                                  optionsViewBuilder:
                                      (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Material(
                                          elevation: 8,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            width: 300,
                                            constraints: const BoxConstraints(
                                                maxHeight: 250),
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              separatorBuilder:
                                                  (context, index) =>
                                                      const Divider(height: 1),
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                final String option =
                                                    options.elementAt(index);
                                                return ListTile(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  title: Text(
                                                    option,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  onTap: () =>
                                                      onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms),

                            const SizedBox(height: 12),

                            // Day Selector
                            Card(
                              color: isDark ? ITMColors.darkCard : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: days.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final day = days[index];
                                    final isSelected = selectedDay == day;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => selectedDay = day),
                                      child: AnimatedContainer(
                                        duration: 300.ms,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? ITMColors.gradientStart
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? ITMColors.darkTextPrimary : Colors.black87),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                                .animate()
                                .slideX(begin: 1)
                                .fadeIn(duration: 400.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),

            // Routine Content Card
            if (selectedBatch == null || selectedDay == null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  decoration: BoxDecoration(
                    color: isDark ? ITMColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Keeps everything vertically centered
                        children: [
                          // 1. The Existing Text

                          // 2. Spacing between Text and GIF

                          // 3. The GIF (Added after text)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                20.0), // Adjust "20.0" for more/less roundness
                            child: Image.asset(
                              'assets/images/gif1.gif',
                              height: 200,
                              fit: BoxFit
                                  .cover, // Ensures the image fills the rounded area properly
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          // Added a slight delay for a smooth effect

                          const SizedBox(height: 30),
                          Text(
                            'Please enter batch and select day.',
                            style:
                                TextStyle(fontSize: 16, color: isDark ? ITMColors.darkTextSecondary : Colors.black54),
                          ).animate().fadeIn(),
                        ],
                      ),
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
                            color: isDark ? ITMColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
                          width: double
                              .infinity, // Ensures centering works horizontally
                          decoration: BoxDecoration(
                            color: isDark ? ITMColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min, // Hugs content height
                              crossAxisAlignment: CrossAxisAlignment
                                  .center, // Centers content horizontally
                              children: [
                                // 1. Rounded GIF
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners for the image
                                  child: Image.asset(
                                    'assets/images/gif3.gif',
                                    height: 200, // Adjust height as needed
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                const SizedBox(height: 20), // Spacing

                                // 2. The Text
                                Text(
                                  'No Classes Today',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? ITMColors.darkTextSecondary : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Sort classes by time
                      final sortedClasses = List.from(routine.classes);
                      sortedClasses.sort((a, b) {
                        final timeA = _extractStartTime(a.time);
                        final timeB = _extractStartTime(b.time);
                        return timeA.compareTo(timeB);
                      });

                      return Column(
                        children: sortedClasses.mapIndexed((index, classItem) {
                          return Animate(
                            effects: [
                              FadeEffect(
                                  duration: 300.ms, delay: (index * 100).ms),
                              SlideEffect(
                                  begin: const Offset(0, 0.2),
                                  duration: 300.ms),
                            ],
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? ITMColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
                                      color: ITMColors.gradientStart,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule,
                                                size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                classItem.time,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? ITMColors.darkTextPrimary : Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.person,
                                                size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Teacher: ${classItem.teacherInitial.isNotEmpty ? classItem.teacherInitial : '-'}',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? ITMColors.darkTextPrimary : Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 16, color: Colors.teal),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Room: ${classItem.room}',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: isDark ? ITMColors.darkTextPrimary : Colors.black87),
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

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
