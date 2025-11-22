import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itm_connect/models/feedback.dart' as feedback_model;
import 'package:itm_connect/services/feedback_service.dart';

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
  final FeedbackService _feedbackService = FeedbackService();

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

    try {
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      // Generate document ID as {date}_{email}
      final docId = '${date}_${_emailController.text.trim()}';

      final fbModel = feedback_model.Feedback(
        id: docId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        feedbackType: _feedbackType,
        message: _messageController.text.trim(),
        date: date,
        time: time,
      );

      await _feedbackService.submitFeedback(fbModel);

      if (mounted) {
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        _feedbackType = 'Suggestion';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 22.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);
    final formPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final iconSize = isMobile ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teal Gradient Header - Full Width Pattern
                  Container(
                    width: double.infinity,
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
                    child: isMobile
                        ? Padding(
                            padding: EdgeInsets.all(headerPadding),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Share your Feedback',
                                      style: TextStyle(
                                        fontSize: headerFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Help us improve your experience',
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -headerPadding,
                                  right: -headerPadding,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.rate_review_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(headerPadding),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Share your Feedback',
                                            style: TextStyle(
                                              fontSize: headerFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Help us improve your experience',
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
                                Positioned(
                                  top: -headerPadding,
                                  right: -headerPadding,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.rate_review_rounded,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Form Content
                  Padding(
                    padding: EdgeInsets.all(formPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & Email Row - Responsive
                          isMobile
                              ? Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Your Name',
                                      icon: Icons.person,
                                      validator: (val) => val!.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email,
                                      hint: 'example@diu.edu.bd',
                                      validator: (val) {
                                        if (val!.isEmpty) return 'Required';
                                        if (!val.endsWith('@diu.edu.bd')) {
                                          return 'DIU email only';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _nameController,
                                        label: 'Your Name',
                                        icon: Icons.person,
                                        validator: (val) => val!.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email,
                                        hint: 'example@diu.edu.bd',
                                        validator: (val) {
                                          if (val!.isEmpty) return 'Required';
                                          if (!val.endsWith('@diu.edu.bd')) {
                                            return 'DIU email only';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 14),
                          // Feedback Type
                          DropdownButtonFormField<String>(
                            value: _feedbackType,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _feedbackTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Feedback Type',
                              prefixIcon: const Icon(Icons.category),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 14),
                          // Message
                          TextFormField(
                            controller: _messageController,
                            maxLines: isMobile ? 4 : 5,
                            decoration: InputDecoration(
                              labelText: 'Your Message',
                              hintText: 'Write your feedback here...',
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.edit_note),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            validator: (val) => val!.isEmpty
                                ? 'Please enter your feedback'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          // Submit Button - Responsive
                          isMobile
                              ? SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: isSubmitting ? null : _submitFeedback,
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text('Submit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 40,
                                      child: ElevatedButton.icon(
                                        onPressed: isSubmitting ? null : _submitFeedback,
                                        icon: const Icon(Icons.send, size: 18),
                                        label: const Text('Submit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          if (isSubmitting) ...[
                            const SizedBox(height: 16),
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
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