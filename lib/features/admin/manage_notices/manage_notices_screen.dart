import 'package:flutter/material.dart';
import 'package:itm_connect/models/notice.dart';
import 'package:itm_connect/services/notice_service.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

class _ManageNoticesScreenState extends State<ManageNoticesScreen>
    with SingleTickerProviderStateMixin {
  final NoticeService _noticeService = NoticeService();

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

  void _showNoticeForm({Notice? existingNotice}) {
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final bodyController = TextEditingController(text: existingNotice?.body ?? '');
    final dateController = TextEditingController(text: existingNotice?.date ?? '');
    final formKey = GlobalKey<FormState>();

    String _makeDocId(String date, String title) {
      final t = title.replaceAll(' ', '');
      final safe = t.replaceAll(RegExp(r"[^A-Za-z0-9_]"), '');
      return '${date}_$safe';
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        bool isLoading = false;
        return AlertDialog(
          title: Text(existingNotice == null ? 'Add Notice' : 'Edit Notice'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Body'),
                    validator: (value) => value!.isEmpty ? 'Body is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    keyboardType: TextInputType.datetime,
                    validator: (value) => value!.isEmpty ? 'Date is required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // prevent duplicate taps
                if (isLoading) return;
                if (!formKey.currentState!.validate()) return;
                setModalState(() => isLoading = true);

                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                final date = dateController.text.trim();

                final newId = _makeDocId(date, title);

                try {
                  final newNotice = Notice(id: newId, title: title, body: body, date: date);
                  await _noticeService.setNotice(newNotice);

                  // if editing and id changed, delete old doc
                  if (existingNotice != null && existingNotice.id != newId) {
                    await _noticeService.deleteNotice(existingNotice.id);
                  }

                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                  }
                } finally {
                  setModalState(() => isLoading = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  void _deleteNotice(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _noticeService.deleteNotice(docId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted')));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
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

  Widget _buildNoticeCard(Notice notice) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          notice.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notice.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '📅 ${notice.date}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showNoticeForm(existingNotice: notice),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNotice(notice.id),
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
          // Removed UniversalHeader here
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<List<Notice>>(
                stream: _noticeService.streamAllNotices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final notices = snapshot.data ?? [];
                  if (notices.isEmpty) return const Center(child: Text('No notices available.'));
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notices.length,
                    itemBuilder: (_, index) => _buildNoticeCard(notices[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Notice'),
        onPressed: () => _showNoticeForm(),
      ),
    );
  }
}
