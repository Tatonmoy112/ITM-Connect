import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itm_connect/widgets/app_layout.dart';
import 'package:itm_connect/features/user/class_routine/class_routine_screen.dart';
import 'package:itm_connect/features/user/contact/contact_us_screen.dart';
import 'package:itm_connect/features/user/feedback/feedback_screen.dart';
import 'package:itm_connect/features/user/notice/notice_board_screen.dart';
import 'package:itm_connect/features/user/teacher/list/teacher_list_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = -1;
  late final AnimationController _bgController;

  final List<Widget> _pages = [
    const TeacherListScreen(),
    const NoticeBoardScreen(),
    const ClassRoutineScreen(),
    const ContactUsScreen(),
    const FeedbackScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    colors: [
                      Color.lerp(const Color(0xFF43cea2), const Color(0xFF185a9d), _bgController.value)!,
                      Color.lerp(const Color(0xFFf5f5f5), const Color(0xFFe0f7fa), 1 - _bgController.value)!,
                      Color.lerp(const Color(0xFFe0f7fa), const Color(0xFFf5f5f5), _bgController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
        ),
        // Foreground content (AppLayout) - not rebuilt on every animation tick
        AppLayout(
          showAppBar: true,
          showBottomNavBar: true,
          currentIndex: _currentIndex,
          onBottomNavTap: _handleBottomNavTap,
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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToContent() {
    _scrollController.animateTo(
      210,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Animated flowing gradient background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: widget.bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF43cea2), const Color(0xFF185a9d), widget.bgController.value)!,
                      Color.lerp(const Color(0xFFf5f5f5), const Color(0xFFe0f7fa), 1 - widget.bgController.value)!,
                      Color.lerp(const Color(0xFFe0f7fa), const Color(0xFFf5f5f5), widget.bgController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _FlowingBackgroundPainter(widget.bgController.value),
                ),
              );
            },
          ),
        ),
        // Main scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============ LAYER 1: TOP BACKGROUND BLOCK (250px cover image) ============
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/ITM_ALL.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
                // Down arrow button at the bottom
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GestureDetector(
                      onTap: _scrollToContent,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black54,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ============ LAYER 2 & 3: WHITE MAIN CARD + PROFILE (negative overlap) ============
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: const EdgeInsets.only(left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ============ LAYER 3: PROFILE PHOTO (floating inside main card) ============
                        Positioned(
                          top: -50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: AssetImage('assets/images/Ms. Nusrat Jahan.jfif'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ============ MAIN CONTENT (padded below profile) ============
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ============ HEAD OF DEPARTMENT MESSAGE CARD ============
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFF43cea2),
                                      width: 4,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF43cea2).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.message_rounded,
                                            color: Color(0xFF43cea2),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Head of Department',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Ms. Nusrat Jahan',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF2c3e50),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '"Welcome to the academic year. We are committed to excellence in education and fostering a vibrant learning community. Let\'s work together to achieve great milestones."',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Banner carousel
                              const BannerCarousel(),

                              const SizedBox(height: 28),

                              // ============ FEATURED ANNOUNCEMENTS SECTION ============
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Featured Announcements',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2c3e50),
                                    ),
                                  ),
                                  Text(
                                    'View All',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF43cea2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Announcement Card 1 - Exam Schedule
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF667eea).withValues(alpha: 0.08),
                                      const Color(0xFF764ba2).withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea).withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.event_note_rounded,
                                            color: Color(0xFF667eea),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Semester Examination',
                                                style: theme.textTheme.labelLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF2c3e50),
                                                ),
                                              ),
                                              Text(
                                                'Exams start 15th Dec 2025',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Urgent',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: const Color(0xFF667eea),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Theory: 20 Dec | Lab: 27 Dec',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: const Color(0xFF667eea),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Announcement Card 2 - Course Registration
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF093fb).withValues(alpha: 0.08),
                                      const Color(0xFFf5576c).withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF093fb).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF093fb).withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF093fb).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.school_rounded,
                                            color: Color(0xFFF093fb),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Course Registration Open',
                                                style: theme.textTheme.labelLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF2c3e50),
                                                ),
                                              ),
                                              Text(
                                                'Advanced Programs Available',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.black54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF093fb).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'New',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: const Color(0xFFF093fb),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildCourseTag('Data Science', const Color(0xFFF093fb)),
                                        _buildCourseTag('Python Dev', const Color(0xFFF093fb)),
                                        _buildCourseTag('Web Dev', const Color(0xFFF093fb)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Announcement Card 3 - Scholarship
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFFB84D).withValues(alpha: 0.08),
                                      const Color(0xFFFF8C42).withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFB84D).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFB84D).withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB84D).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.card_giftcard_rounded,
                                        color: Color(0xFFFFB84D),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Scholarship Programs',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2c3e50),
                                            ),
                                          ),
                                          Text(
                                            'Apply now for merit-based scholarships',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: const Color(0xFFFFB84D),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ============ IMPORTANT LINKS SECTION ============
                              Text(
                                'Important Links',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2c3e50),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLinkCard('Library', Icons.library_books_rounded, const Color(0xFF4CAF50)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildLinkCard('Sports', Icons.sports_basketball_rounded, const Color(0xFF2196F3)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildLinkCard('Hostel', Icons.home_rounded, const Color(0xFFFF9800)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // ============ UPCOMING EVENTS SECTION ============
                              Text(
                                'Upcoming Events',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2c3e50),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF43cea2).withValues(alpha: 0.08),
                                      const Color(0xFF185a9d).withValues(alpha: 0.03),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF43cea2).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF43cea2).withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildEventTile('Annual Tech Summit', 'Dec 20', Colors.blue),
                                    const Divider(height: 20),
                                    _buildEventTile('Sports Day', 'Dec 25', Colors.orange),
                                    const Divider(height: 20),
                                    _buildEventTile('Cultural Fest', 'Jan 10', Colors.purple),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build course tags
  Widget _buildCourseTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper method to build link cards
  Widget _buildLinkCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2c3e50),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build event tiles
  Widget _buildEventTile(String title, String date, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2c3e50),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: color,
        ),
      ],
    );
  }
}

// ============ HELPER CLASSES ============

// New InteractiveGlassCard widget for hover/press effects
class InteractiveGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const InteractiveGlassCard({super.key, required this.child, this.onTap});

  @override
  State<InteractiveGlassCard> createState() => _InteractiveGlassCardState();
}

class _InteractiveGlassCardState extends State<InteractiveGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              showGlow: _glowAnimation.value > 0.5, // Show glow when pressed
              child: child!,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Custom painter for animated flowing background shapes
class _FlowingBackgroundPainter extends CustomPainter {
  final double value;
  _FlowingBackgroundPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.tealAccent.withOpacity(0.13),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.11),
          Colors.transparent,
        ],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Animated flowing shapes
    canvas.drawCircle(
      Offset(80 + 40 * value, 80 + 30 * value), 70 + 10 * value, paint1,
    );
    canvas.drawCircle(
      Offset(size.width - 80 - 40 * value, size.height - 80 - 30 * value), 50 + 10 * value, paint2,
    );
  }

  @override
  bool shouldRepaint(covariant _FlowingBackgroundPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final bool showGlow; // New property to control glow
  const GlassCard({super.key, required this.child, this.showGlow = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Slightly less opaque
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)), // More visible border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (showGlow) // Conditional glow effect
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3), // Neon glow color
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
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0); // Parallax effect
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
              child: GlassCard( // Using GlassCard for carousel items
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