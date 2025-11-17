import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _feedbackType = 'Suggestion';
  bool isSubmitting = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  final List<String> _feedbackTypes = [
    'Suggestion',
    'Bug Report',
    'Complaint',
    'Appreciation'
  ];

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

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2)); // mock save

    if (mounted) {
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      _feedbackType = 'Suggestion';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Thank you for your feedback!')),
      );

      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.rate_review_rounded, color: Colors.deepPurple, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: const Text(
                              'Share your feedback',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name & Email Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Your Name',
                              icon: Icons.person_outline,
                              validator: (val) => val!.trim().isEmpty
                                  ? 'Please enter your name'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _emailController,
                              label: 'DIU Email',
                              icon: Icons.email_outlined,
                              hint: 'example@diu.edu.bd',
                              validator: (val) {
                                if (val!.isEmpty) return 'Email is required';
                                if (!val.endsWith('@diu.edu.bd')) {
                                  return 'Only DIU email addresses are allowed';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Feedback Type
                      DropdownButtonFormField<String>(
                        value: _feedbackType,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _feedbackTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Feedback Type',
                          prefixIcon: const Icon(Icons.category_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _feedbackType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Your Message',
                          hintText: 'Write your feedback here...',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (val) => val!.isEmpty
                            ? 'Feedback message cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // Submit
                      Center(
                        child: isSubmitting
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                onPressed: _submitFeedback,
                                icon: const Icon(Icons.send_rounded),
                                label: const Text('Submit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}