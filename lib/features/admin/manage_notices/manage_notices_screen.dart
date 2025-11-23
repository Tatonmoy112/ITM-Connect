import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showNoticeForm({Notice? existingNotice}) {
    final titleController = TextEditingController(text: existingNotice?.title ?? '');
    final bodyController = TextEditingController(text: existingNotice?.body ?? '');
    final dateController = TextEditingController(text: existingNotice?.date ?? '');
    final attachmentController = TextEditingController(text: existingNotice?.attachment ?? '');

    String _makeDocId(String date, String title) {
      final t = title.replaceAll(' ', '');
      final safe = t.replaceAll(RegExp(r"[^A-Za-z0-9_]"), '');
      return '${date}_$safe';
    }

    bool showTitleError = false;
    bool showBodyError = false;
    bool showDateError = false;
    bool isLoading = false;
    bool hasAttachment = existingNotice?.attachment != null && existingNotice!.attachment!.isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setModalState) {
        final size = MediaQuery.of(context).size;
        final dialogIsMobile = size.width < 600;
        final dialogWidth = dialogIsMobile ? size.width - 32 : 500.0;
        final maxDialogHeight = size.height * 0.9;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxDialogHeight,
              maxWidth: dialogWidth,
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
                              existingNotice == null ? 'Add Notice' : 'Edit Notice',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (existingNotice != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Date: ${existingNotice.date}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              prefixIcon: const Icon(Icons.title),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              errorText: showTitleError ? 'Required' : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Body
                          TextField(
                            controller: bodyController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Body',
                              prefixIcon: const Icon(Icons.description),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              errorText: showBodyError ? 'Required' : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Date
                          TextField(
                            controller: dateController,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              labelText: 'Date (YYYY-MM-DD)',
                              prefixIcon: const Icon(Icons.calendar_today),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              errorText: showDateError ? 'Required' : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Attachment Section
                          Divider(color: Colors.grey.shade300, height: 1),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attachment (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!hasAttachment)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('Add Attachment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () {
                                    setModalState(() => hasAttachment = true);
                                  },
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: attachmentController,
                                      decoration: InputDecoration(
                                        labelText: 'Attachment URL',
                                        prefixIcon: const Icon(Icons.attachment),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () {
                                            attachmentController.clear();
                                            setModalState(() => hasAttachment = false);
                                          },
                                        ),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        hintText: 'https://example.com/file.pdf',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Enter the URL of the attachment (PDF, image, document, etc.)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
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
                                final title = titleController.text.trim();
                                final body = bodyController.text.trim();
                                final date = dateController.text.trim();
                                final attachment = attachmentController.text.trim().isEmpty ? null : attachmentController.text.trim();

                                setModalState(() {
                                  showTitleError = title.isEmpty;
                                  showBodyError = body.isEmpty;
                                  showDateError = date.isEmpty;
                                });

                                if (showTitleError || showBodyError || showDateError) {
                                  return;
                                }

                                setModalState(() => isLoading = true);

                                final newId = _makeDocId(date, title);

                                try {
                                  final newNotice = Notice(
                                    id: newId,
                                    title: title,
                                    body: body,
                                    date: date,
                                    attachment: attachment,
                                  );
                                  await _noticeService.setNotice(newNotice);

                                  // if editing and id changed, delete old doc
                                  if (existingNotice != null && existingNotice.id != newId) {
                                    await _noticeService.deleteNotice(existingNotice.id);
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(existingNotice == null ? 'Notice added successfully' : 'Notice updated successfully'),
                                        backgroundColor: Colors.green,
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
                                existingNotice == null ? 'Add Notice' : 'Save',
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted successfully')));
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

  Widget _buildNoticeCard(
    Notice notice,
    bool isMobile,
    bool isTablet,
    double cardMargin,
    double contentPadding,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: EdgeInsets.only(bottom: cardMargin),
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
            padding: EdgeInsets.all(isMobile ? 12 : 14),
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
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  notice.date,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          // Body Content
          Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.body,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                // Attachment Display
                if (notice.attachment != null && notice.attachment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attachment_rounded,
                          color: Colors.blue,
                          size: isMobile ? 18 : 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attachment available',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: isMobile ? 8 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: isMobile ? 32 : 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _showNoticeForm(existingNotice: notice),
                    icon: Icon(Icons.edit, size: isMobile ? 16 : 18, color: Colors.white),
                    label: Text(
                      'Edit',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                SizedBox(
                  height: isMobile ? 32 : 36,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _deleteNotice(notice.id),
                    icon: Icon(Icons.delete, size: isMobile ? 16 : 18, color: Colors.white),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 13),
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
                                Icons.notification_important,
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
                                    'Notices Hub',
                                    style: TextStyle(
                                      fontSize: headerFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 4 : 6),
                                  Text(
                                    'Create and manage notices for your students',
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
                            StreamBuilder<List<Notice>>(
                              stream: _noticeService.streamAllNotices(),
                              builder: (context, snapshot) {
                                final noticeCount = snapshot.data?.length ?? 0;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        'Total Notices',
                                        noticeCount.toString(),
                                        Colors.teal,
                                        Icons.notifications,
                                        isMobile,
                                        isTablet,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 10 : 12),
                                    Expanded(
                                      child: _buildStatCard(
                                        'Active',
                                        noticeCount.toString(),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            // Notices List
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, horizontalPadding),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: StreamBuilder<List<Notice>>(
                      stream: _noticeService.streamAllNotices(),
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
                                        'Error loading notices',
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

                        final allNotices = snapshot.data ?? [];
                        final filtered = allNotices;

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
                                        Icons.notifications_none,
                                        size: 56,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No notices yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap the + button to create a notice',
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

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) => _buildNoticeCard(
                            filtered[index],
                            isMobile,
                            isTablet,
                            cardMargin,
                            contentPadding,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Notice'),
        onPressed: () => _showNoticeForm(),
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
}
