import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
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
            padding: const EdgeInsets.all(16),
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
                    radius: 32,
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
                const SizedBox(width: 14),
                // Name and ID Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
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
            padding: const EdgeInsets.all(16),
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
              ],
            ),
          ),
          // Action Buttons Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _showTeacherForm(teacher: teacher),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text(
                        'Edit',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _deleteTeacher(teacher.id),
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Card with Stats and Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
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
                      padding: const EdgeInsets.all(20),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.waving_hand,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Teachers Hub',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'View, manage and organize your online teaching team efficiently',
                                  style: TextStyle(
                                    fontSize: 13,
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
                      padding: const EdgeInsets.all(20),
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
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Active',
                                      teacherCount.toString(),
                                      Colors.orange,
                                      Icons.check_circle,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
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
              ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            ),
            // Teachers List
            Padding(
              padding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 16),
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
                                        child: _buildTeacherCard(filtered[index]),
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
            const SizedBox(height: 20),
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
        child: FloatingActionButton.extended(
          onPressed: () => _showTeacherForm(),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Teacher'),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
