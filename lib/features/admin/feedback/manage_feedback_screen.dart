import 'package:flutter/material.dart';

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key});

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen>
    with SingleTickerProviderStateMixin {
  // ✅ Mock data — replace with Firestore in future
  final List<Map<String, String>> feedbacks = [
    {
      'name': 'John Doe',
      'email': 'john@diu.edu.bd',
      'message': 'The app is really helpful. Great job!',
      'timestamp': '2025-07-08 10:30 AM',
    },
    {
      'name': 'Sarah Ahmed',
      'email': 'sarah@diu.edu.bd',
      'message': 'Would love to see dark mode support.',
      'timestamp': '2025-07-08 11:00 AM',
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

  void _deleteFeedback(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                feedbacks.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, String> data, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          data['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(data['message'] ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text('🕒 ${data['timestamp'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFeedback(index),
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
          // UniversalHeader removed here
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: feedbacks.isEmpty
                  ? const Center(child: Text('No feedback available.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: feedbacks.length,
                itemBuilder: (_, index) => _buildFeedbackCard(feedbacks[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
