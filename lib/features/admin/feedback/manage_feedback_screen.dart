import 'package:flutter/material.dart';
import 'package:itm_connect/models/feedback_entry.dart';
import 'package:itm_connect/services/feedback_service.dart';

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key});

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen>
    with SingleTickerProviderStateMixin {
  final FeedbackService _feedbackService = FeedbackService();

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

  void _deleteFeedbackById(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _feedbackService.deleteFeedback(docId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackEntry data, int index) {
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
          data.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.email, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(data.message, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            if (data.feedbackType.isNotEmpty) Text('Type: ${data.feedbackType}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 6),
            Text('📅 ${data.date}  🕒 ${data.time}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFeedbackById(data.id),
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
              child: StreamBuilder<List<FeedbackEntry>>(
                stream: _feedbackService.streamAllFeedbacks(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) return const Center(child: Text('No feedback available.'));
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    itemBuilder: (_, index) => _buildFeedbackCard(list[index], index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
