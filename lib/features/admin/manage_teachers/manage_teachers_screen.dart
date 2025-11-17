import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ManageTeacherScreen extends StatefulWidget {
  const ManageTeacherScreen({super.key});

  @override
  State<ManageTeacherScreen> createState() => _ManageTeacherScreenState();
}

class _ManageTeacherScreenState extends State<ManageTeacherScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _teachers = [
    {
      'name': 'Md. Imran Hossain',
      'email': 'imran@diu.edu.bd',
      'role': 'Professor',
      'initial': 'MIH',
      'imageFile': null,
    },
    {
      'name': 'Farzana Akter',
      'email': 'farzana@diu.edu.bd',
      'role': 'Lecturer',
      'initial': 'FA',
      'imageFile': null,
    },
  ];

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

  void _showTeacherForm({Map<String, dynamic>? existingData, int? index}) {
    final nameController = TextEditingController(text: existingData?['name']);
    final emailController = TextEditingController(text: existingData?['email']);
    final roleController = TextEditingController(text: existingData?['role']);
    final initialController = TextEditingController(text: existingData?['initial']);
    File? selectedFile = existingData?['imageFile'];

    bool showNameError = false;
    bool showEmailError = false;
    bool showRoleError = false;
    bool showInitialError = false;
    String? initialErrorMessage;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(existingData == null ? 'Add Teacher' : 'Edit Teacher'),
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
                    decoration: InputDecoration(
                      labelText: 'Teacher Initial (Unique)',
                      errorText: showInitialError ? initialErrorMessage : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setModalState(() {
                          selectedFile = File(result.files.single.path!);
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Photo'),
                  ),
                  const SizedBox(height: 12),
                  if (selectedFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedFile!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final role = roleController.text.trim();
                  final initial = initialController.text.trim().toUpperCase();

                  setModalState(() {
                    showNameError = name.isEmpty;
                    showEmailError = email.isEmpty;
                    showRoleError = role.isEmpty;
                    showInitialError = initial.isEmpty ||
                        _teachers.any((t) =>
                        t['initial'] == initial &&
                            (existingData == null || t != existingData));
                    initialErrorMessage = initial.isEmpty
                        ? 'Required'
                        : 'Initial already exists';
                  });

                  if (showNameError ||
                      showEmailError ||
                      showRoleError ||
                      showInitialError) {
                    return;
                  }

                  final newData = {
                    'name': name,
                    'email': email,
                    'role': role,
                    'initial': initial,
                    'imageFile': selectedFile,
                  };

                  setState(() {
                    if (existingData == null) {
                      _teachers.add(newData);
                    } else {
                      _teachers[index!] = newData;
                    }
                  });

                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteTeacher(int index) {
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
            onPressed: () {
              setState(() => _teachers.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher, int index) {
    final imageFile = teacher['imageFile'];

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
          backgroundImage: imageFile != null
              ? FileImage(imageFile)
              : const AssetImage('assets/images/default_profile.png') as ImageProvider,
        ),
        title: Text(
          '${teacher['name']} (${teacher['initial']})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teacher['email'] ?? '', style: const TextStyle(fontSize: 14)),
            Text(teacher['role'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showTeacherForm(existingData: teacher, index: index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTeacher(index),
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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _teachers.length,
                itemBuilder: (_, index) =>
                    _buildTeacherCard(_teachers[index], index),
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
