import 'package:flutter/material.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final String _imageBbApiKey = 'f517e6ca9abc65dece38e282d13bff53';

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setModalState(() {});
        
        final imageFile = File(result.files.first.path!);
        final uploadedUrl = await _uploadImageToImageBB(imageFile);
        
        if (uploadedUrl != null) {
          imageUrlController.text = uploadedUrl;
          setModalState(() {});
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  void _showTeacherForm({Teacher? teacher}) {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final roleController = TextEditingController(text: teacher?.role ?? '');
    final initialController = TextEditingController(text: teacher?.id ?? '');
    final imageUrlController = TextEditingController(text: teacher?.imageUrl ?? '');

    bool showNameError = false;
    bool showEmailError = false;
    bool showRoleError = false;
    bool showInitialError = false;
    String? initialErrorMessage;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Dialog(
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
                // Form Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: 450,
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
                  padding: const EdgeInsets.all(16),
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
                          return;
                        }

                        setModalState(() => isLoading = true);

                        try {
                          await _teacherService.addOrUpdateTeacher(
                            teacherInitial: initial,
                            name: name,
                            email: email,
                            role: role,
                            imageUrl: imageUrl,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(teacher == null ? 'Teacher added successfully' : 'Teacher updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
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

  Widget _buildTeacherCard(Teacher teacher) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
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
                        teacher.name,
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
                        'ID: ${teacher.id}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Teacher Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                            return const Icon(Icons.person, color: Colors.white, size: 24);
                          }
                          final parts = name.split(' ');
                          var initials = '';
                          if (parts.isNotEmpty && parts[0].isNotEmpty) {
                            initials += parts[0][0];
                            if (parts.length > 1 && parts.last.isNotEmpty) {
                              initials += parts.last[0];
                            }
                          }
                          return Text(initials.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                        })()
                      : null,
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
                    const Icon(Icons.email, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teacher.email,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.work, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teacher.role,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _showTeacherForm(teacher: teacher),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _deleteTeacher(teacher.id),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontSize: 13),
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<List<Teacher>>(
                stream: _teacherService.streamAllTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final teachers = snapshot.data ?? [];

                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No teachers yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to add a teacher',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: teachers.length,
                    itemBuilder: (_, index) => _buildTeacherCard(teachers[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeacherForm(),
        label: const Text('Add Teacher'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
    );
  }
}
