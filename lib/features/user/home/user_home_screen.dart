import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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
                              Text(
                                'Featured Announcements',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2c3e50),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Announcement Card 1
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF667eea).withValues(alpha: 0.1),
                                      const Color(0xFF764ba2).withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active_rounded,
                                        color: Color(0xFF667eea),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Semester Examination Schedule',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2c3e50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Exams start from 15th December 2025',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Announcement Card 2
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF093fb).withValues(alpha: 0.1),
                                      const Color(0xFFf5576c).withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF093fb).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF093fb).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.assignment_rounded,
                                        color: Color(0xFFF093fb),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'New Course Registration',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2c3e50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Advanced programming & Data Science courses now available',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ============ QUICK STATS SECTION ============
                              Text(
                                'Department Overview',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2c3e50),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Stats Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF43cea2).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF43cea2).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF43cea2).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.people_rounded,
                                              color: Color(0xFF43cea2),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '1,250',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF43cea2),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Students',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF667eea).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF667eea).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.book_rounded,
                                              color: Color(0xFF667eea),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '45',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF667eea),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Courses',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA500).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFFA500).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFA500).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.person_outline_rounded,
                                              color: Color(0xFFFFA500),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '72',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFFFA500),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Faculty',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.event_rounded,
                                              color: Color(0xFF00BCD4),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '28',
                                            style: theme.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF00BCD4),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Events',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  'https://i.imgur.com/1vOifiN.png',
  'https://i.imgur.com/lsx4Sjy.png',
  'https://i.imgur.com/ao4FFHe.png',
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
                  child: Image.network(
                    bannerImages[index],
                    fit: BoxFit.cover,
                    // width: 320, // Removed fixed width to allow scaling
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