import 'package:flutter/material.dart';
import 'package:itm_connect/models/teacher.dart';
import 'package:itm_connect/services/teacher_service.dart';

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
          return AlertDialog(
            title: Text(teacher == null ? 'Add Teacher' : 'Edit Teacher'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      errorText: showNameError ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: showEmailError ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      labelText: 'Role (e.g. Professor, Lecturer)',
                      errorText: showRoleError ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: initialController,
                    enabled: teacher == null,
                    decoration: InputDecoration(
                      labelText: 'Teacher Initial (Unique)',
                      helperText: 'e.g., TAT, MIH, FA',
                      errorText: showInitialError ? initialErrorMessage : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'https://example.com/image.jpg',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteTeacher(String teacherId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this teacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blueGrey,
          backgroundImage: (() {
            final url = teacher.imageUrl.trim();
            if (url.isEmpty) return null;
            final lower = url.toLowerCase();
            try {
              if (lower.startsWith('http://') || lower.startsWith('https://')) return NetworkImage(url);
              if (lower.startsWith('assets/') || lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return AssetImage(url) as ImageProvider;
            } catch (_) {}
            return null;
          })(),
          child: (teacher.imageUrl.trim().isEmpty)
              ? (() {
                  final name = teacher.name.trim();
                  if (name.isEmpty) {
                    return const Icon(Icons.person, color: Colors.white, size: 28);
                  }
                  final parts = name.split(' ');
                  var initials = '';
                  if (parts.isNotEmpty && parts[0].isNotEmpty) {
                    initials += parts[0][0];
                    if (parts.length > 1 && parts.last.isNotEmpty) {
                      initials += parts.last[0];
                    }
                  }
                  return Text(initials.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                })()
              : null,
        ),
        title: Text(
          '${teacher.name} (${teacher.id})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher.email, style: const TextStyle(fontSize: 14)),
            Text(teacher.role, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showTeacherForm(teacher: teacher),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTeacher(teacher.id),
            ),
          ],
        ),
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
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
    );
  }
}
