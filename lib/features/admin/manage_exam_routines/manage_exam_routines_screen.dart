import 'package:flutter/material.dart';
import 'package:itm_connect/models/exam_routine.dart';
import 'package:itm_connect/services/exam_routine_service.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ManageExamRoutineScreen extends StatefulWidget {
  const ManageExamRoutineScreen({super.key});

  @override
  State<ManageExamRoutineScreen> createState() => _ManageExamRoutineScreenState();
}

class _ManageExamRoutineScreenState extends State<ManageExamRoutineScreen>
    with SingleTickerProviderStateMixin {
  final ExamRoutineService _examService = ExamRoutineService();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to generate a unique ID
  String _generateId(String date, String code, String batch) {
    return '${date}_${code}_${batch}'.replaceAll(RegExp(r'\s+'), '');
  }

  void _showForm({ExamRoutine? routine}) {
    final titleController = TextEditingController(text: routine?.examTitle);
    final batchController = TextEditingController(text: routine?.batch);
    final courseNameController = TextEditingController(text: routine?.courseName);
    final courseCodeController = TextEditingController(text: routine?.courseCode);
    final dateController = TextEditingController(text: routine?.date);
    final timeController = TextEditingController(text: routine?.time);
    final roomController = TextEditingController(text: routine?.room);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 600;
          
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: isMobile ? double.infinity : 500,
              constraints: BoxConstraints(maxHeight: size.height * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50), // Corporate dark blue
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_calendar, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          routine == null ? 'Add Exam Schedule' : 'Edit Exam Schedule',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(titleController, 'Exam Title', Icons.title, hint: 'e.g. Mid Term Spring 2026'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<String>>(
                                  stream: RoutineService().streamAllBatches(), // Suggest from existing class routines
                                  builder: (context, snapshot) {
                                    final suggestions = snapshot.data ?? [];
                                    // Filter suggestions to exclude 'offday' or other unwanted keywords
                                    final filteredSuggestions = suggestions.where((s) => !s.toLowerCase().contains('offday')).toList();
                                    
                                    return Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text == '') return filteredSuggestions;
                                        return filteredSuggestions.where((String option) {
                                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                        });
                                      },
                                      onSelected: (String selection) {
                                        batchController.text = selection;
                                      },
                                      fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                                        // Sync internal controller with our form controller
                                        if (batchController.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
                                          fieldTextEditingController.text = batchController.text;
                                        }
                                        fieldTextEditingController.addListener(() {
                                          batchController.text = fieldTextEditingController.text;
                                        });
                                        
                                        return TextField(
                                          controller: fieldTextEditingController,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: 'Batch',
                                            hintText: '58',
                                            prefixIcon: Icon(Icons.group, size: 20, color: Colors.grey[600]),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                            isDense: true,
                                          ),
                                        );
                                      },
                                    );
                                  }
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField(courseCodeController, 'Course Code', Icons.code, hint: 'CSE-101')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(courseNameController, 'Course Name', Icons.book, hint: 'Introduction to Computer Systems'),
                          const SizedBox(height: 12),
                          
                          // Date Picker Field
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                dateController.text = formatted;
                              }
                            },
                            child: AbsorbPointer(
                              child: _buildTextField(dateController, 'Date (YYYY-MM-DD)', Icons.calendar_today),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(roomController, 'Room', Icons.location_on, hint: '302')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Time Picker
                           GestureDetector(
                            onTap: () async {
                              // Pick Start Time
                              final start = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 10, minute: 0),
                                helpText: 'SELECT EXAM START TIME',
                              );
                              if (start == null) return;
                              
                              if (!context.mounted) return;

                              // Pick End Time
                              final end = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 12, minute: 0),
                                helpText: 'SELECT EXAM END TIME',
                              );
                              if (end == null) return;

                              if (!context.mounted) return;

                              final localizations = MaterialLocalizations.of(context);
                              final formattedStart = localizations.formatTimeOfDay(start, alwaysUse24HourFormat: false);
                              final formattedEnd = localizations.formatTimeOfDay(end, alwaysUse24HourFormat: false);
                              
                              timeController.text = "$formattedStart - $formattedEnd";
                            },
                            child: AbsorbPointer(
                              child: _buildTextField(timeController, 'Time', Icons.access_time, hint: 'Tap to select time'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () async {
                            if (titleController.text.isEmpty ||
                                batchController.text.isEmpty ||
                                courseCodeController.text.isEmpty ||
                                dateController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }
                            
                            final id = routine?.id ?? _generateId(dateController.text, courseCodeController.text, batchController.text);
                            
                            final newRoutine = ExamRoutine(
                              id: id,
                              examTitle: titleController.text,
                              batch: batchController.text,
                              courseName: courseNameController.text,
                              courseCode: courseCodeController.text,
                              date: dateController.text,
                              time: timeController.text,
                              room: roomController.text,
                            );
                            
                            try {
                              await _examService.setExamRoutine(newRoutine);
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          child: const Text('Save Schedule', style: TextStyle(color: Colors.white)),
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
    );
  }

  Future<void> _pickAndUploadCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() => _isLoading = true);

      String csvString;
      if (kIsWeb) {
        csvString = utf8.decode(result.files.single.bytes!);
      } else {
        final file = File(result.files.single.path!);
        csvString = await file.readAsString();
      }

      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
      if (rows.isEmpty) throw Exception('Empty CSV');

      // Assume headers: Exam Title, Batch, Course Name, Course Code, Date, Time, Room
      // Skip header row if necessary
      int startRow = 0;
      if (rows[0].first.toString().toLowerCase().contains('exam')) startRow = 1;

      List<ExamRoutine> routines = [];
      for (int i = startRow; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 7) continue;

        final title = row[0].toString();
        final batch = row[1].toString();
        final cName = row[2].toString();
        final cCode = row[3].toString();
        final date = row[4].toString();
        final time = row[5].toString();
        final room = row[6].toString();

        final id = _generateId(date, cCode, batch);
        routines.add(ExamRoutine(
          id: id,
          examTitle: title,
          batch: batch,
          courseName: cName,
          courseCode: cCode,
          date: date,
          time: time,
          room: room,
        ));
      }

      await _examService.bulkUploadExamRoutines(routines);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${routines.length} schedules'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _insertRandomData() async {
    setState(() => _isLoading = true);
    try {
      await _examService.createRandomExamData();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Random data inserted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch(e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      // Responsive layout
      final size = MediaQuery.of(context).size;
      final isMobile = size.width < 600;
      final containerWidth = isMobile ? double.infinity : 800.0;
      
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5), // Corporate light grey
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: containerWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                       children: [
                         if (!isMobile) ...[
                           Container(
                             decoration: BoxDecoration(
                               color: Colors.teal.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: IconButton(
                               icon: const Icon(Icons.arrow_back, color: Colors.teal),
                               onPressed: () => Navigator.pop(context),
                               tooltip: 'Back to Dashboard',
                             ),
                           ),
                           const SizedBox(width: 16),
                         ] else ...[
                            IconButton(
                               icon: const Icon(Icons.arrow_back, color: Colors.teal),
                               onPressed: () => Navigator.pop(context),
                             ),
                             const SizedBox(width: 8),
                         ],
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: const Color(0xFF2C3E50),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: const Icon(Icons.event_note, color: Colors.white, size: 28),
                         ),
                         const SizedBox(width: 16),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text(
                               'Exam Management',
                               style: TextStyle(
                                 fontSize: 24, 
                                 fontWeight: FontWeight.bold,
                                 color: Color(0xFF2C3E50),
                               ),
                             ),
                             Text(
                               'Schedule and manage exams efficiently',
                               style: TextStyle(
                                 fontSize: 14,
                                 color: Colors.grey[600],
                               ),
                             ),
                           ],
                         ),
                         const Spacer(),
                         // CSV Action
                         if (!isMobile) ...[
                            _buildActionButton(
                             'Import CSV', 
                             Icons.upload_file, 
                             Colors.green[700]!, 
                             _pickAndUploadCSV
                           ),
                           const SizedBox(width: 10),
                            _buildActionButton(
                             'Auto-Fill', 
                             Icons.auto_fix_high, 
                             Colors.orange[700]!, 
                             _insertRandomData
                           ),
                           const SizedBox(width: 10),
                            _buildActionButton(
                             'Clear All', 
                             Icons.delete_sweep, 
                             Colors.red[700]!, 
                             _confirmDeleteAll
                           ),
                         ]
                       ],
                    ),
                    
                    if (isMobile) ...[
                       const SizedBox(height: 16),
                       Row(
                         children: [
                            Expanded(child: _buildActionButton('Import CSV', Icons.upload_file, Colors.green[700]!, _pickAndUploadCSV)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildActionButton('Auto-Fill', Icons.auto_fix_high, Colors.orange[700]!, _insertRandomData)),
                         ],
                       ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton('Clear All', Icons.delete_sweep, Colors.red[700]!, _confirmDeleteAll)
                        ),
                    ],

                    const SizedBox(height: 24),
                    
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Schedule New Exam', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50), // Corporate Blue
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () => _showForm(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // List
                    const Text(
                      'Upcoming Exams',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    
                    StreamBuilder<List<ExamRoutine>>(
                      stream: _examService.streamAllExamRoutines(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final routines = snapshot.data!;
                        if (routines.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text('No exams scheduled yet', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: routines.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final r = routines[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                  border: Border(left: BorderSide(color: _getColorForBatch(r.batch), width: 4)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    r.courseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _tag(Icons.class_, 'Batch ${r.batch}', Colors.blueGrey),
                                          const SizedBox(width: 8),
                                          _tag(Icons.code, r.courseCode, Colors.teal),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${r.date}  •  ${r.time}  •  Room ${r.room}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _confirmDelete(r.id),
                                  ),
                                  onTap: () => _showForm(routine: r),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
    );
  }
  
  Widget _tag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Color _getColorForBatch(String batch) {
    // Deterministic color generation based on batch string
    final colors = [const Color(0xFF3498DB), const Color(0xFFE74C3C), const Color(0xFFF1C40F), const Color(0xFF9B59B6), const Color(0xFF1ABC9C)];
    int sum = 0;
    for (var i = 0; i < batch.length; i++) {
      sum += batch.codeUnitAt(i);
    }
    return colors[sum % colors.length];
  }

  void _confirmDelete(String id) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to remove this exam schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _examService.deleteExamRoutine(id);
              Navigator.pop(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Schedules'),
        content: const Text('Are you sure you want to delete ALL exam routines? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);
              try {
                await _examService.deleteAllExamRoutines();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All exam routines deleted'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }, 
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
