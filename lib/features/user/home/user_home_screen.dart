import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:itm_connect/theme/app_colors.dart';
import 'package:itm_connect/widgets/app_layout.dart';
import 'package:itm_connect/features/user/class_routine/class_routine_screen.dart';
import 'package:itm_connect/features/user/contact/contact_us_screen.dart';
import 'package:itm_connect/features/user/settings/settings_screen.dart';
import 'package:itm_connect/features/user/notice/notice_board_screen.dart';
import 'package:itm_connect/features/user/teacher/list/teacher_list_screen.dart';
import '../../../../models/news.dart';
import '../../../../services/news_service.dart';

class UserHomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const UserHomeScreen({super.key, this.initialTabIndex = -1});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _bgController;
  StreamSubscription<DocumentSnapshot>? _notificationSub;
  Timestamp? _lastSeenSyncTimestamp;
  bool _popupShown = false;
  bool _hasNewNotification = false;
  String _lastNotificationMessage = '';
  DateTime? _lastNotificationTime;

  final List<Widget> _pages = [
    const TeacherListScreen(),
    const NoticeBoardScreen(),
    const ClassRoutineScreen(),
    const ContactUsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _initData();
  }

  Future<void> _initData() async {
    await _loadLastSeenTimestamp();
    _listenForRoutineUpdates();
  }

  Future<void> _loadLastSeenTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMs = prefs.getInt('last_seen_notification_ms');
      if (savedMs != null) {
        _lastSeenSyncTimestamp = Timestamp.fromMillisecondsSinceEpoch(savedMs);
      }
      // Load last notification data for the bell panel
      final savedMsg = prefs.getString('last_notification_message');
      final savedTimeMs = prefs.getInt('last_notification_time_ms');
      if (savedMsg != null && savedMsg.isNotEmpty) {
        _lastNotificationMessage = savedMsg;
      }
      if (savedTimeMs != null) {
        _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(savedTimeMs);
      }
    } catch (e, stack) {
      debugPrint('Error loading SharedPreferences: $e\n$stack');
    }
  }

  void _listenForRoutineUpdates() {
    try {
      _notificationSub = FirebaseFirestore.instance
          .collection('app_notifications')
          .doc('routine_sync')
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists || !mounted) return;
        final data = snapshot.data();
        if (data == null) return;

        final updatedAt = data['updatedAt'] as Timestamp?;
        if (updatedAt == null) return;

        final message = data['message'] as String? ?? 'Class routine has been updated!';

        // Always update the notification panel data with the latest from Firestore
        // if it's newer than what we currently have in the panel.
        if (_lastNotificationTime == null || updatedAt.toDate().isAfter(_lastNotificationTime!)) {
          _lastNotificationMessage = message;
          _lastNotificationTime = updatedAt.toDate();
          _saveNotificationData(message, _lastNotificationTime!);
        }

        // First snapshot: record the timestamp if we don't have one saved, don't show popup
        if (_lastSeenSyncTimestamp == null) {
          _lastSeenSyncTimestamp = updatedAt;
          return;
        }

        // Show badge and popup only if timestamp is newer
        if (updatedAt.compareTo(_lastSeenSyncTimestamp!) > 0 && !_popupShown) {
          _lastSeenSyncTimestamp = updatedAt;
          _popupShown = true;
          setState(() => _hasNewNotification = true);
          _showRoutineUpdatePopup(message);
        }
      });
    } catch (e, stack) {
      debugPrint('Error listening for routine updates (Firebase might not be initialized): $e\n$stack');
    }
  }

  Future<void> _saveNotificationData(String message, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_notification_message', message);
    await prefs.setInt('last_notification_time_ms', time.millisecondsSinceEpoch);
  }

  void _showRoutineUpdatePopup(String message) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? ITMColors.darkCard : null,
            gradient: isDark ? null : const LinearGradient(
              colors: [Color(0xFFe0f7fa), Color(0xFFffffff)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? ITMColors.darkSurface : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20, color: isDark ? ITMColors.darkTextTertiary : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.teal, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Routine Updated!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? ITMColors.darkTextSecondary : Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ITMColors.gradientStart,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got it!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNotificationTap() async {
    // Show notification details panel
    _showNotificationPanel();
    // Mark notification as seen
    setState(() => _hasNewNotification = false);
    // Save the timestamp so badge stays dismissed across app restarts
    if (_lastSeenSyncTimestamp != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_seen_notification_ms', _lastSeenSyncTimestamp!.millisecondsSinceEpoch);
    }
  }

  void _showNotificationPanel() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNotification = _lastNotificationMessage.isNotEmpty && _lastNotificationTime != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? ITMColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? ITMColors.darkCardBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: Colors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? ITMColors.darkDivider : null),
            if (hasNotification)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.withOpacity(isDark ? 0.1 : 0.05),
                        Colors.blue.withOpacity(isDark ? 0.08 : 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.withOpacity(isDark ? 0.3 : 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.update_rounded, color: Colors.orange, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '📢 Routine Updated!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _lastNotificationMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? ITMColors.darkTextSecondary : Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: isDark ? ITMColors.darkTextTertiary : Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy — hh:mm a').format(_lastNotificationTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? ITMColors.darkTextTertiary : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 48, color: isDark ? ITMColors.darkTextTertiary : Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(fontSize: 14, color: isDark ? ITMColors.darkTextTertiary : Colors.grey[400], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            if (hasNotification)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ITMColors.gradientStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() => _currentIndex = 2);
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('View Routine', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Animated background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Color.lerp(ITMColors.darkBackground,
                                const Color(0xFF0D2137), _bgController.value)!,
                            Color.lerp(const Color(0xFF0D2137),
                                ITMColors.darkBackground, 1 - _bgController.value)!,
                          ]
                        : [
                            Color.lerp(ITMColors.gradientEnd,
                                ITMColors.gradientStart, _bgController.value)!,
                            Color.lerp(const Color(0xFFf5f7fa),
                                const Color(0xFFe0f7fa), 1 - _bgController.value)!,
                            Color.lerp(const Color(0xFFe0f7fa),
                                const Color(0xFFf5f7fa), _bgController.value)!,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
        ),
        // Foreground content (AppLayout)
        AppLayout(
          showAppBar: true,
          showBottomNavBar: true,
          currentIndex: _currentIndex,
          onBottomNavTap: _handleBottomNavTap,
          hasNewNotification: _hasNewNotification,
          onNotificationTap: _onNotificationTap,
          body: _currentIndex == -1
              ? ITMDepartmentHomeBody(bgController: _bgController)
              : _pages[_currentIndex],
        ),
      ],
    );
  }
}

class ITMDepartmentHomeBody extends StatefulWidget {
  final AnimationController bgController;
  const ITMDepartmentHomeBody({super.key, required this.bgController});

  @override
  State<ITMDepartmentHomeBody> createState() => _ITMDepartmentHomeBodyState();
}

class _ITMDepartmentHomeBodyState extends State<ITMDepartmentHomeBody> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth =
        isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            horizontalPadding, horizontalPadding, horizontalPadding, horizontalPadding + 90),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: containerMaxWidth),
            decoration: BoxDecoration(
              color: isDark ? ITMColors.darkCard : ITMColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : ITMColors.gradientStart).withOpacity(isDark ? 0.3 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(headerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Big Image (Banner Section)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/ITM_ALL.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text(
                                'Banner Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Circular Profile Image (Overlapping Section)
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Info Card (Welcome Message Section)
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark ? ITMColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Extra space for the circular image
                            const SizedBox(height: 50),
                            // Section label
                            Text(
                              'Head of Department',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ITMColors.gradientEnd,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            Text(
                              'Dr. Nusrat Jahan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Welcome message
                            Text(
                              'Welcome to the Department of Information Technology & Management. We are committed to providing excellent education and nurturing the next generation of IT professionals with cutting-edge knowledge and practical skills.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? ITMColors.darkTextSecondary : Colors.grey[700],
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Circular Profile Image (floating on top)
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/citations-Picsart-AiImageEnhancer.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Banner Carousel
                  const BannerCarousel(),
                  const SizedBox(height: 32),

                  // ============ IMPORTANT LINKS SECTION ============
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Links',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLinkSection(
                        icon: Icons.school_rounded,
                        title: 'Student Portal',
                        subtitle: 'Access Daffodil University portal',
                        color: Colors.deepPurple,
                        url: 'https://daffodilvarsity.edu.bd/article/students',
                      ),
                      const SizedBox(height: 10),
                      _buildLinkSection(
                        icon: Icons.library_books_rounded,
                        title: 'Digital Library',
                        subtitle: 'Browse academic materials',
                        color: Colors.teal,
                        url: 'https://library.daffodilvarsity.edu.bd/',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ============ QUICK STATS SECTION ============
                  Text(
                    'Department Stats',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF185a9d).withOpacity(0.08),
                          const Color(0xFF43cea2).withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFF185a9d).withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF185a9d).withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          // First row
                          Row(
                            children: [
                              _buildStatItemWithIcon(
                                count: '300+',
                                label: 'Students',
                                iconWidget: const CustomPaint(
                                  painter: _PeopleIconPainter(color: Color(0xFF00BCD4)),
                                ),
                                color: const Color(0xFF00BCD4),
                              ),
                              const Spacer(),
                              Container(
                                width: 1,
                                height: 60,
                                color: const Color(0xFF185a9d).withOpacity(0.1),
                              ),
                              const Spacer(),
                              _buildStatItemWithIcon(
                                count: '20+',
                                label: 'Faculty',
                                iconWidget: const CustomPaint(
                                  painter: _FacultyIconPainter(color: Color(0xFF9C27B0)),
                                ),
                                color: const Color(0xFF9C27B0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            color: const Color(0xFF185a9d).withOpacity(0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          // Second row
                          Row(
                            children: [
                              _buildStatItemWithIcon(
                                count: '50+',
                                label: 'Courses',
                                iconWidget: const CustomPaint(
                                  painter: _BookIconPainter(color: Color(0xFFFFC107)),
                                ),
                                color: const Color(0xFFFFC107),
                              ),
                              const Spacer(),
                              Container(
                                width: 1,
                                height: 60,
                                color: const Color(0xFF185a9d).withOpacity(0.1),
                              ),
                              const Spacer(),
                              _buildStatItemWithIcon(
                                count: '95%',
                                label: 'Satisfaction',
                                iconWidget: const CustomPaint(
                                  painter: _StarIconPainter(color: Color(0xFFFF6B6B)),
                                ),
                                color: const Color(0xFFFF6B6B),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ============ ITM CURRENT NEWS SECTION ============
                  // Dynamic News Feed
                  LayoutBuilder(builder: (context, constraints) {
                    return StreamBuilder<List<News>>(
                        stream: NewsService().streamAllNews(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ));
                          }

                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox(); // Hide section if no news
                          }

                          // Displaying only the latest news for now
                          final latestNews = snapshot.data!.first;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.06),
                                  Colors.teal.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF185a9d)
                                            .withOpacity(0.15),
                                        const Color(0xFF43cea2)
                                            .withOpacity(0.15),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '📰 ITM Current News',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF185a9d),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // News Image
                                if (latestNews.imageUrl.isNotEmpty) ...[
                                  Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.network(
                                        latestNews.imageUrl,
                                        width: 280,
                                        height: 280,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // News Title
                                Text(
                                  latestNews.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF185a9d),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // News Content
                                Text(
                                  latestNews.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Facebook Share Button (if available)
                                if (latestNews.facebookUrl.isNotEmpty)
                                  Center(
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          final Uri uri =
                                              Uri.parse(latestNews.facebookUrl);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Cannot open link')),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          // Error handling
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1877F2)
                                                  .withOpacity(0.9),
                                              const Color(0xFF165FD1)
                                                  .withOpacity(0.9),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1877F2)
                                                  .withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.facebook_rounded,
                                                color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'View on Facebook',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        });
                  }),
                  const SizedBox(height: 32),

                  // ============ FOOTER SECTION WITH SOCIAL ICONS ============
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.08),
                          Colors.blue.withOpacity(0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.teal.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF185a9d).withOpacity(0.1),
                                const Color(0xFF43cea2).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color(0xFF185a9d).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Color(0xFF185a9d),
                                Color(0xFF43cea2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Connect With Us',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialIcon(
                              icon: Icons.facebook_rounded,
                              color: Color(0xFF1877F2),
                              label: 'Facebook',
                              url: 'https://www.facebook.com/diu.itm',
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              icon: Icons.language,
                              color: Color(0xFF0EA5E9),
                              label: 'Website',
                              url:
                                  'https://daffodilvarsity.edu.bd/department/itm',
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              icon: Icons.location_on_rounded,
                              color: Color(0xFFE4405F),
                              label: 'Location',
                              url:
                                  'https://www.google.com/maps/search/Daffodil+International+University+Birulia',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Department of Information Technology & Management',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? ITMColors.darkTextSecondary : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daffodil Smart City (DSC), Birulia, Savar, Dhaka - 1216, Bangladesh',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? ITMColors.darkTextTertiary : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© ${DateTime.now().year} Daffodil International University',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? ITMColors.darkTextTertiary : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 300.ms)
        .slideY(begin: 0.3, end: 0);
  }

  // Helper method to build social media icons - Redesigned
  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: url.isNotEmpty
          ? () async {
              try {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cannot open $label')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening $label: $e')),
                  );
                }
              }
            }
          : null,
      child: Tooltip(
        message: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Helper method to build link section cards
  Widget _buildLinkSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: url.isNotEmpty
            ? () async {
                try {
                  final Uri uri = Uri.parse(url);
                  // Try to launch the URL - on Android/iOS, this will open in browser
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  print('Error launching URL: $e');
                }
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextPrimary : const Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextSecondary : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build stat items with icons
  Widget _buildStatItemWithIcon({
    required String count,
    required String label,
    required Widget iconWidget,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: iconWidget,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextPrimary : const Color(0xFF1a1a1a),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark ? ITMColors.darkTextSecondary : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build resource cards - Modern Interactive Design
  // (Kept for potential future use)
}

// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool showGlow;
  const GlassCard({super.key, required this.child, this.showGlow = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (showGlow)
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 5,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

final List<String> bannerImages = [
  'assets/images/ITM-1.JPG',
  'assets/images/ITM-2.JPG',
  'assets/images/ITM-3.JPG',
];

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      setState(() {
        _currentPage = (_currentPage + 1) % bannerImages.length;
      });
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Slightly increased height for better visual
      child: PageView.builder(
        controller: _controller,
        itemCount: bannerImages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = 1.0;
              if (_controller.position.haveDimensions) {
                value = _controller.page! - index;
                value = (1 - (value.abs() * 0.3))
                    .clamp(0.0, 1.0); // Parallax effect
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeOut.transform(value) * 180, // Scale effect
                  width: Curves.easeOut.transform(value) * 320,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GlassCard(
                // Using GlassCard for carousel items
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    bannerImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeopleIconPainter extends CustomPainter {
  final Color color;
  const _PeopleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Draw Background Person (left/top-ish)
    final head1 = Offset(w * 0.38, h * 0.36);
    canvas.drawCircle(head1, w * 0.13, paint);

    final shoulders1 = Path();
    shoulders1.moveTo(w * 0.16, h * 0.80);
    shoulders1.quadraticBezierTo(w * 0.16, h * 0.54, w * 0.38, h * 0.54);
    shoulders1.quadraticBezierTo(w * 0.60, h * 0.54, w * 0.60, h * 0.80);
    shoulders1.close();
    canvas.drawPath(shoulders1, paint);

    // 2. Draw Foreground Person (right/bottom-ish) with a visual mask
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());

    final head2 = Offset(w * 0.68, h * 0.44);
    final shoulders2 = Path();
    shoulders2.moveTo(w * 0.42, h * 0.88);
    shoulders2.quadraticBezierTo(w * 0.42, h * 0.62, w * 0.68, h * 0.62);
    shoulders2.quadraticBezierTo(w * 0.94, h * 0.62, w * 0.94, h * 0.88);
    shoulders2.close();

    // Visual gap/mask around head2 and shoulders2:
    final gapPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..isAntiAlias = true;

    canvas.drawCircle(head2, w * 0.15, gapPaint);
    canvas.drawPath(shoulders2, gapPaint);

    // Draw the actual foreground person:
    canvas.drawCircle(head2, w * 0.15, paint);
    canvas.drawPath(shoulders2, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PeopleIconPainter old) => old.color != color;
}

class _FacultyIconPainter extends CustomPainter {
  final Color color;
  const _FacultyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Draw graduation cap diamond top
    final capTop = Path();
    capTop.moveTo(w * 0.50, h * 0.08);
    capTop.lineTo(w * 0.80, h * 0.20);
    capTop.lineTo(w * 0.50, h * 0.32);
    capTop.lineTo(w * 0.20, h * 0.20);
    capTop.close();
    canvas.drawPath(capTop, paint);

    // Tassel hanging down
    final tasselPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(Offset(w * 0.80, h * 0.20), Offset(w * 0.82, h * 0.38), tasselPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.40), w * 0.04, paint);

    // Cap base band
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.38, h * 0.24, w * 0.24, h * 0.08),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(baseRect, paint);

    // 2. Head circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.46), w * 0.13, paint);

    // 3. Shoulders
    final shoulders = Path();
    shoulders.moveTo(w * 0.22, h * 0.88);
    shoulders.quadraticBezierTo(w * 0.22, h * 0.62, w * 0.50, h * 0.62);
    shoulders.quadraticBezierTo(w * 0.78, h * 0.62, w * 0.78, h * 0.88);
    shoulders.close();
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _FacultyIconPainter old) => old.color != color;
}

class _BookIconPainter extends CustomPainter {
  final Color color;
  const _BookIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw book spine and cover layers
    final pagePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Left page path
    final leftPage = Path();
    leftPage.moveTo(w * 0.50, h * 0.25);
    leftPage.quadraticBezierTo(w * 0.35, h * 0.15, w * 0.18, h * 0.22);
    leftPage.lineTo(w * 0.18, h * 0.78);
    leftPage.quadraticBezierTo(w * 0.35, h * 0.72, w * 0.50, h * 0.82);
    leftPage.lineTo(w * 0.50, h * 0.25);

    // Right page path
    final rightPage = Path();
    rightPage.moveTo(w * 0.50, h * 0.25);
    rightPage.quadraticBezierTo(w * 0.65, h * 0.15, w * 0.82, h * 0.22);
    rightPage.lineTo(w * 0.82, h * 0.78);
    rightPage.quadraticBezierTo(w * 0.65, h * 0.72, w * 0.50, h * 0.82);
    rightPage.lineTo(w * 0.50, h * 0.25);

    canvas.drawPath(leftPage, fillPaint);
    canvas.drawPath(rightPage, fillPaint);

    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);

    // Middle separator line (spine)
    canvas.drawLine(Offset(w * 0.50, h * 0.25), Offset(w * 0.50, h * 0.82), pagePaint);
  }

  @override
  bool shouldRepaint(covariant _BookIconPainter old) => old.color != color;
}

class _StarIconPainter extends CustomPainter {
  final Color color;
  const _StarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.52;

    final path = Path();
    final double outerRadius = w * 0.46;
    final double innerRadius = w * 0.18;

    for (int i = 0; i < 10; i++) {
      final double angle = i * math.pi / 5 - math.pi / 2;
      final double radius = i.isEven ? outerRadius : innerRadius;
      final double x = cx + radius * math.cos(angle);
      final double y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarIconPainter old) => old.color != color;
}
