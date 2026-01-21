import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class ManageTeacherScreen extends StatefulWidget {
  const ManageTeacherScreen({super.key});

  @override
  State<ManageTeacherScreen> createState() => _ManageTeacherScreenState();
}

class _ManageTeacherScreenState extends State<ManageTeacherScreen>
    with SingleTickerProviderStateMixin {
  final TeacherService _teacherService = TeacherService();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final String _imageBbApiKey = '4a859feec3e15adfebf576f9bf215b39';

  Future<String?> _uploadImageToImageBB(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _imageBbApiKey
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Failed to upload image: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }

  Future<void> _pickAndUploadImage(
    TextEditingController imageUrlController,
    Function setModalState,
  ) async {
    try {
      if (kIsWeb) {
        // Web implementation using universal_html
        final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
          ..accept = '.jpg,.png'
          ..click();

        uploadInput.onChange.listen((e) async {
          final files = uploadInput.files;
          if (files == null || files.isEmpty) return;

          final file = files[0];
          final reader = html.FileReader();

          // Validate file name
          final fileName = file.name.toLowerCase();
          if (!fileName.endsWith('.jpg') && !fileName.endsWith('.png')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid format! Only .jpg and .png files are accepted.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          reader.onLoad.listen((e) async {
            final bytes = reader.result as List<int>;
            await _uploadImageToImageBBWeb(bytes, file.name, imageUrlController, setModalState);
          });

          reader.readAsArrayBuffer(file);
        });
      } else {
        // Mobile/Desktop implementation using image_picker
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          
          // Validate file extension
          final fileName = imageFile.path.toLowerCase();
          if (!fileName.endsWith('.jpg') && !fileName.endsWith('.png')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid format! Only .jpg and .png files are accepted.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          final uploadedUrl = await _uploadImageToImageBB(imageFile);
          
          if (uploadedUrl != null) {
            setModalState(() {
              imageUrlController.text = uploadedUrl;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// Upload image bytes to ImageBB (for web)
  Future<void> _uploadImageToImageBBWeb(
    List<int> imageBytes,
    String fileName,
    TextEditingController imageUrlController,
    Function setModalState,
  ) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _imageBbApiKey
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: fileName,
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        final uploadedUrl = jsonResponse['data']['url'];
        setModalState(() {
          imageUrlController.text = uploadedUrl;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${jsonResponse['error']['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllTeachers = false;

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
    _searchController.dispose();
    super.dispose();
  }

  /// Validates input to prevent SQL injection and malicious code
  /// Allows: Letters, numbers, spaces, hyphens, underscores, dots
  bool _isValidInput(String input) {
    if (input.isEmpty) return true; // Empty is handled elsewhere
    
    final inputLower = input.toLowerCase();
    
    // SQL injection keywords
    final sqlKeywords = [
      'select', 'insert', 'update', 'delete', 'drop', 'create',
      'alter', 'exec', 'execute', 'union', '--', 'xp_', 'sp_',
      'script', 'javascript', 'onerror', 'onclick'
    ];
    
    for (final keyword in sqlKeywords) {
      if (inputLower.contains(keyword)) return false;
    }
    
    // Dangerous characters
    final dangerousChars = ['\'', '"', ';', '\\', '<', '>', '`', '{', '}', '[', ']', '(', ')'];
    for (final char in dangerousChars) {
      if (input.contains(char)) return false;
    }
    
    return true;
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    return emailRegex.hasMatch(email);
  }

  void _showTeacherForm({Teacher? teacher}) {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final roleController = TextEditingController(text: teacher?.role ?? '');
    final initialController = TextEditingController(text: (teacher?.teacherInitial ?? teacher?.id ?? '').toString().trim());
    final List<String> consultingSlots = List<String>.from(teacher?.consultingHours ?? []);
    final imageUrlController = TextEditingController(text: teacher?.imageUrl ?? '');

    bool showNameError = false;
    bool showEmailError = false;
    bool showRoleError = false;
    bool showInitialError = false;
    String? initialErrorMessage;
    bool isLoading = false;
    bool hasRefetched = false; // Flag to ensure we fetch fresh data only once

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          // Fetch fresh data immediately when opening edit dialog
          if (teacher != null && !hasRefetched) {
            hasRefetched = true;
            _teacherService.getTeacher(teacher.teacherInitial).then((fresh) {
              if (fresh != null && context.mounted) {
                setModalState(() {
                  consultingSlots.clear();
                  consultingSlots.addAll(fresh.consultingHours);
                  print("Refreshed data for ${teacher.teacherInitial}: $consultingSlots");
                });
              }
            });
          }

          final size = MediaQuery.of(context).size;
          final dlgIsMobile = size.width < 600;
          final dlgIsTablet = size.width >= 600 && size.width < 1024;
          final dialogMaxWidth = dlgIsMobile ? size.width - 32 : (dlgIsTablet ? 600.0 : 700.0);
          final dlgPadding = dlgIsMobile ? 12.0 : (dlgIsTablet ? 14.0 : 18.0);
          final maxDialogHeight = size.height * 0.9;

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: maxDialogHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Teal Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
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
                                teacher == null ? 'Add New Teacher' : 'Edit Teacher Details',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (teacher != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'ID: ${teacher.id}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        // Current Photo Preview
                        if (teacher != null && imageUrlController.text.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrlController.text,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.image, color: Colors.white30),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Form Content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(dlgPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Full Name
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showNameError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Email
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showEmailError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Role
                            TextField(
                              controller: roleController,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                prefixIcon: const Icon(Icons.work),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showRoleError ? 'Required' : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Initial
                            TextField(
                              controller: initialController,
                              enabled: teacher == null,
                              decoration: InputDecoration(
                                labelText: 'Initial',
                                prefixIcon: const Icon(Icons.badge),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                errorText: showInitialError ? initialErrorMessage : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: teacher != null,
                                fillColor: teacher != null ? Colors.grey.shade100 : Colors.transparent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Consulting Hours (Multi-slot)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Consulting Hours", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      if (isLoading || !hasRefetched) 
                                        const SizedBox(
                                          width: 16, 
                                          height: 16, 
                                          child: CircularProgressIndicator(strokeWidth: 2)
                                        )
                                      else
                                        TextButton.icon(
                                          icon: const Icon(Icons.add_circle, color: Colors.teal, size: 18),
                                          label: const Text("Add Slot", style: TextStyle(color: Colors.teal, fontSize: 13)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () {
                                            print("User clicked Add Slot. Current count: ${consultingSlots.length}");
                                            setModalState(() {
                                              consultingSlots.add("Sat 08:30 AM - 10:00 AM");
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (consultingSlots.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Text("No consulting hours added", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ),
                                    ),
                                  ...consultingSlots.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final slot = entry.value;
                                    
                                    // Parse day and time with robust fallbacks
                                    String currentDay = "Sat";
                                    String currentTime = RoutineService.classSlots[0];
                                    
                                    final parts = slot.split(' ');
                                    if (parts.isNotEmpty) {
                                      final rawDay = parts[0];
                                      // Normalize legacy full names to short form
                                      final normalizedDay = rawDay.length >= 3 
                                          ? (rawDay.substring(0, 1).toUpperCase() + rawDay.substring(1, 3).toLowerCase()) 
                                          : rawDay;
                                      
                                      final allowedDays = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];
                                      if (allowedDays.contains(normalizedDay)) {
                                        currentDay = normalizedDay;
                                      }

                                      if (slot.contains('-')) {
                                         final rawTime = slot.substring(slot.indexOf(RegExp(r'\d'))).trim();
                                         if (RoutineService.classSlots.contains(rawTime)) {
                                           currentTime = rawTime;
                                         }
                                      }
                                    }

                                    return Container(
                                      key: ValueKey("${slot}_$idx"),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              // Day Dropdown
                                              Expanded(
                                                flex: 2,
                                                child: DropdownButton<String>(
                                                  value: currentDay,
                                                  isExpanded: true,
                                                  underline: const SizedBox(),
                                                  items: ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"].map((d) {
                                                    return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
                                                  }).toList(),
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      setModalState(() {
                                                        consultingSlots[idx] = "$val $currentTime";
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Time Slot Dropdown
                                              Expanded(
                                                flex: 5,
                                                child: DropdownButton<String>(
                                                  value: RoutineService.classSlots.contains(currentTime) ? currentTime : RoutineService.classSlots[0],
                                                  isExpanded: true,
                                                  underline: const SizedBox(),
                                                  items: RoutineService.classSlots.map((s) {
                                                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)));
                                                  }).toList(),
                                                  onChanged: (val) async {
                                                    if (val != null) {
                                                      // 1. Update list IMMEDIATELY (sync)
                                                      setModalState(() {
                                                        consultingSlots[idx] = "$currentDay $val";
                                                      });

                                                      // 2. Then check for conflicts (async)
                                                      final initial = initialController.text.trim().toUpperCase();
                                                      if (initial.isNotEmpty) {
                                                        final conflict = await RoutineService().checkTeacherAvailability(
                                                          teacherInitial: initial,
                                                          day: _getFullDayName(currentDay),
                                                          timeRange: val,
                                                          skipConsultingCheck: true, // Don't check against self
                                                        );
                                                        
                                                        if (conflict != null) {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text(conflict), backgroundColor: Colors.orange),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                                onPressed: () {
                                                  setModalState(() {
                                                    consultingSlots.removeAt(idx);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),
                            // Photo Upload Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Photo',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                // Pick Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            await _pickAndUploadImage(imageUrlController, setModalState);
                                          },
                                    icon: const Icon(Icons.image, color: Colors.white),
                                    label: const Text(
                                      'Pick Photo',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Format info text
                                const SizedBox(height: 6),
                                const Text(
                                  'Accepted formats: .jpg, .png',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                // Important instruction message
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Important: Click "Add Teacher" only after the "Delete Photo" button appears below. This confirms the photo has been successfully uploaded. Clicking "Add Teacher" before this will not save the teacher to the database.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade800,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Delete Button (shown only if photo exists)
                                if (imageUrlController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade500,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          imageUrlController.clear();
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.white),
                                      label: const Text(
                                        'Delete Photo',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Buttons Footer
                  Container(
                    padding: EdgeInsets.all(dlgPadding),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final role = roleController.text.trim();
                                  final initial = initialController.text.trim().toUpperCase();
                                  final imageUrl = imageUrlController.text.trim();

                                  setModalState(() {
                                    showNameError = name.isEmpty;
                                    showEmailError = email.isEmpty;
                                    showRoleError = role.isEmpty;
                                    showInitialError = initial.isEmpty;
                                    initialErrorMessage = initial.isEmpty ? 'Required' : null;
                                  });

                                  if (showNameError ||
                              showEmailError ||
                              showRoleError ||
                              showInitialError) {
                        // Show error dialog if any required field is empty
                        List<String> missingFields = [];
                        if (showNameError) missingFields.add('Full Name');
                        if (showEmailError) missingFields.add('Email');
                        if (showRoleError) missingFields.add('Role');
                        if (showInitialError) missingFields.add('Initial');

                        if (mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                '⚠️ Missing Required Fields',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Please fill in all required fields:',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  ...missingFields.map((field) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          field,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fix Fields', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }
                        return;
                      }

                      setModalState(() => isLoading = true);

                      try {
                        // Validate input for malicious content
                        if (!_isValidInput(name) || !_isValidInput(email) || 
                            !_isValidInput(role) || !_isValidInput(initial)) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Invalid Input',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Input contains invalid characters or potentially harmful content.\n\n'
                                  'Allowed characters: Letters, numbers, spaces, hyphens, underscores, dots, and @ for email only.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          setModalState(() => isLoading = false);
                          return;
                        }

                        // Validate email format
                        if (!_isValidEmail(email)) {
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Invalid Email',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Please enter a valid email address.\n\n'
                                  'Example: teacher@daffodil.edu.bd',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          setModalState(() => isLoading = false);
                          return;
                        }

                        // Check if name already exists (excluding current teacher when editing)
                        final existingTeachers = await _teacherService.getAllTeachers();
                        final nameTaken = existingTeachers.any((t) => 
                          t.name.toLowerCase() == name.toLowerCase() && 
                          (teacher == null || t.id != teacher.id)
                        );
                        final initialTaken = existingTeachers.any((t) => 
                          t.id.toUpperCase() == initial && 
                          (teacher == null || t.id != teacher.id)
                        );

                        if (nameTaken) {
                          setModalState(() {
                            showNameError = true;
                          });
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Duplicate Teacher Name',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'A teacher with this name already exists.\n\n'
                                  'Please use a different name or edit the existing teacher.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          setModalState(() => isLoading = false);
                          return;
                        }

                        if (initialTaken) {
                          setModalState(() {
                            showInitialError = true;
                            initialErrorMessage = 'This initial is already taken';
                          });
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Duplicate Teacher Initial',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  'A teacher with initial "$initial" already exists.\n\n'
                                  'Please use a different initial or edit the existing teacher.',
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          setModalState(() => isLoading = false);
                          return;
                        }

                        print('ManageTeachersScreen: Saving teacher with slots: $consultingSlots');
                        await _teacherService.addOrUpdateTeacher(
                          teacherInitial: initial,
                          name: name,
                          email: email,
                          role: role,
                          imageUrl: imageUrl,
                          consultingHours: consultingSlots,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          
                          // Show success dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.teal.shade600,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    teacher == null ? 'Teacher Added' : 'Teacher Updated',
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher == null
                                          ? 'Teacher has been successfully added to the database.'
                                          : 'Teacher information has been successfully updated.',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.teal.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Details:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '• Name: $name',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '• Email: $email',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '• Role: $role',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  teacher == null ? 'Add Teacher' : 'Update',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _deleteTeacher(String teacherId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this teacher? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _teacherService.deleteTeacher(teacherId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teacher deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher, bool isMobile, bool isTablet, double contentPadding, double cardMargin) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: cardMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Teal Header with Avatar
          Container(
            padding: EdgeInsets.all(contentPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Circle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: isMobile ? 24 : 32,
                    backgroundColor: Colors.white.withOpacity(0.15),
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
                        ? (() {
                            final name = teacher.name.trim();
                            if (name.isEmpty) {
                              return const Icon(Icons.person, color: Colors.white, size: 32);
                            }
                            final parts = name.split(' ');
                            var initials = '';
                            if (parts.isNotEmpty && parts[0].isNotEmpty) {
                              initials += parts[0][0];
                              if (parts.length > 1 && parts.last.isNotEmpty) {
                                initials += parts.last[0];
                              }
                            }
                            return Text(
                              initials.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          })()
                        : null,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 14),
                // Name and ID Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        teacher.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${teacher.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email, size: 18, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Role Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work, size: 18, color: Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.role,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Consulting Hours Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.access_time_filled, size: 18, color: Colors.amber.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consulting Hours',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (teacher.consultingHours.isEmpty)
                            const Text(
                              'Not set',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: teacher.consultingHours.map((slot) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons Footer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: isMobile ? 8 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: isMobile ? 32 : 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showTeacherForm(teacher: teacher),
                        icon: Icon(Icons.edit_rounded, size: isMobile ? 16 : 18),
                        label: Text(
                          'Edit',
                          style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 10),
                // Delete Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: isMobile ? 32 : 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _deleteTeacher(teacher.id),
                        icon: Icon(Icons.delete_rounded, size: isMobile ? 16 : 18),
                        label: Text(
                          'Delete',
                          style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);
    final headerPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final cardMargin = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);
    final contentPadding = isMobile ? 12.0 : (isTablet ? 14.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Card with Stats and Search
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, 0),
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
                      // Teal Header Section
                      Container(
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon Badge
                            Container(
                              padding: EdgeInsets.all(isMobile ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.waving_hand,
                                color: Colors.white,
                                size: isMobile ? 24 : 32,
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 16),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Teachers Hub',
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  Text(
                                    'View, manage and organize your online teaching team efficiently',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stats and Search Section
                      Padding(
                        padding: EdgeInsets.all(headerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Row
                            StreamBuilder<List<Teacher>>(
                              stream: _teacherService.streamAllTeachers(),
                              builder: (context, snapshot) {
                                final teacherCount = snapshot.data?.length ?? 0;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Teachers',
                                        teacherCount.toString(),
                                        Colors.teal,
                                        Icons.people,
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 10 : 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Active',
                                        teacherCount.toString(),
                                        Colors.orange,
                                        Icons.check_circle,
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            // Search Bar with Suggestions
                            StreamBuilder<List<Teacher>>(
                              stream: _teacherService.streamAllTeachers(),
                              builder: (context, snapshot) {
                                final allTeachers = snapshot.data ?? [];
                                final suggestions = _searchQuery.isEmpty
                                    ? []
                                    : allTeachers.where((t) {
                                        final q = _searchQuery;
                                        return t.name.toLowerCase().contains(q) ||
                                            t.role.toLowerCase().contains(q) ||
                                            t.email.toLowerCase().contains(q);
                                      }).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Search Bar
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(12),
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search teacher by name or role...',
                                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.teal),
                                          suffixIcon: _searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close, color: Colors.grey),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() {
                                                      _searchQuery = '';
                                                    });
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 15),
                                        onChanged: (value) {
                                          setState(() {
                                            _searchQuery = value.toLowerCase();
                                          });
                                        },
                                      ),
                                    ),
                                    // Suggestions Dropdown
                                    if (_searchQuery.isNotEmpty && suggestions.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.teal.withOpacity(0.2),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.teal.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: suggestions.length > 3 ? 200.0 : double.infinity,
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: suggestions.length > 3
                                              ? const AlwaysScrollableScrollPhysics()
                                              : const NeverScrollableScrollPhysics(),
                                          itemCount: suggestions.length,
                                          itemBuilder: (context, index) {
                                            final teacher = suggestions[index];
                                            return Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  _showTeacherForm(teacher: teacher);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Avatar
                                                      CircleAvatar(
                                                        radius: 18,
                                                        backgroundColor: Colors.teal.withOpacity(0.1),
                                                        backgroundImage: (() {
                                                          final url = teacher.imageUrl.trim();
                                                          if (url.isEmpty) return null;
                                                          final lower = url.toLowerCase();
                                                          try {
                                                            if (lower.startsWith('http://') ||
                                                                lower.startsWith('https://')) {
                                                              return NetworkImage(url);
                                                            }
                                                          } catch (_) {}
                                                          return null;
                                                        })(),
                                                        child: teacher.imageUrl.trim().isEmpty
                                                            ? Text(
                                                                teacher.name.isNotEmpty
                                                                    ? teacher.name[0].toUpperCase()
                                                                    : '?',
                                                                style: const TextStyle(
                                                                  color: Colors.teal,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Teacher Info
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              teacher.name,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black87,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              teacher.role,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade600,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Icon
                                                      Icon(
                                                        Icons.arrow_forward_rounded,
                                                        size: 18,
                                                        color: Colors.teal.withOpacity(0.6),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    // No suggestions message
                                    if (_searchQuery.isNotEmpty &&
                                        suggestions.isEmpty &&
                                        allTeachers.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: Colors.orange.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'No teachers match your search',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            // Teachers List
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, horizontalPadding),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: StreamBuilder<List<Teacher>>(
                      stream: _teacherService.streamAllTeachers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.teal),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Error loading teachers',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${snapshot.error}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final allTeachers = snapshot.data ?? [];
                        final filtered = _searchQuery.isEmpty
                            ? allTeachers
                            : allTeachers.where((t) {
                                final q = _searchQuery;
                                return t.name.toLowerCase().contains(q) ||
                                    t.role.toLowerCase().contains(q) ||
                                    t.email.toLowerCase().contains(q);
                              }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                                        size: 56,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty ? 'No teachers yet' : 'No teachers found',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Tap the + button to add a teacher'
                                            : 'Try different search keywords',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Display all teachers with collapsible button
                        return StatefulBuilder(
                          builder: (context, setStateLocal) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Show All Teachers Button
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: () {
                                      setStateLocal(() {
                                        _showAllTeachers = !_showAllTeachers;
                                      });
                                    },
                                    icon: Icon(
                                      _showAllTeachers ? Icons.expand_less : Icons.expand_more,
                                      size: 22,
                                    ),
                                    label: Text(
                                      _showAllTeachers 
                                          ? 'Hide All Teachers (${filtered.length})'
                                          : 'Show All Teachers (${filtered.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                // Teachers List - Shows when expanded
                                if (_showAllTeachers)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, index) {
                                      return ScaleTransition(
                                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                          CurvedAnimation(
                                            parent: _animationController,
                                            curve: Interval(
                                              0.65 + (index * 0.08),
                                              math.min(0.65 + (index * 0.08) + 0.25, 1.0),
                                              curve: Curves.easeOutBack,
                                            ),
                                          ),
                                        ),
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.2, 0),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Interval(
                                                0.65 + (index * 0.06),
                                                math.min(0.65 + (index * 0.06) + 0.20, 1.0),
                                                curve: Curves.easeOut,
                                              ),
                                            ),
                                          ),
                                          child: FadeTransition(
                                            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                              CurvedAnimation(
                                                parent: _animationController,
                                                curve: Interval(
                                                  0.65 + (index * 0.06),
                                                  math.min(0.65 + (index * 0.06) + 0.20, 1.0),
                                                  curve: Curves.easeIn,
                                                ),
                                              ),
                                            ),
                                            child: _buildTeacherCard(filtered[index], isMobile, isTablet, contentPadding, cardMargin),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => _showTeacherForm(),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, color: color, size: isMobile ? 16 : 18),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getFullDayName(String shortDay) {
    switch (shortDay) {
      case 'Sat': return 'Saturday';
      case 'Sun': return 'Sunday';
      case 'Mon': return 'Monday';
      case 'Tue': return 'Tuesday';
      case 'Wed': return 'Wednesday';
      case 'Thu': return 'Thursday';
      case 'Fri': return 'Friday';
      default: return shortDay;
    }
  }
}
