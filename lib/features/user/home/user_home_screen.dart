import 'dart:async';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

class ITMDepartmentHomeBody extends StatelessWidget {
  final AnimationController bgController;
  const ITMDepartmentHomeBody({super.key, required this.bgController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Animated flowing gradient background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF43cea2), const Color(0xFF185a9d), bgController.value)!,
                      Color.lerp(const Color(0xFFf5f5f5), const Color(0xFFe0f7fa), 1 - bgController.value)!,
                      Color.lerp(const Color(0xFFe0f7fa), const Color(0xFFf5f5f5), bgController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _FlowingBackgroundPainter(bgController.value),
                ),
              );
            },
          ),
        ),
        // Main content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Department Head Speech Section
              Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 900)),
                  SlideEffect(begin: Offset(0, -0.12), end: Offset.zero, duration: Duration(milliseconds: 900)),
                ],
                child: Center(
                  child: GlassCard(
                    showGlow: true, // Added glow to hero card
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: AssetImage('assets/images/Ms. Moni Akter.jpg'), // Placeholder image
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ms. Nusrat Jahan",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Department Head, ITM",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Stack(
                            children: [
                              Text(
                                "Welcome to ITM Connect, your gateway to the Department of Information Technology & Management. This platform keeps you informed, engaged, and connected with all department activities, achievements, and opportunities. Explore, participate, and be part of our vibrant ITM community",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 2,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.cyanAccent.withOpacity(0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Premium Feature Dashboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Quick Access",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), 
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9, // Adjusted for better text visibility
                ),
                itemCount: 6, // 2x3 grid
                itemBuilder: (context, index) {
                  String title = "";
                  String snippet = "";
                  IconData icon = Icons.info_outline;
                  Color iconColor = Colors.blue;

                  switch (index) {
                    case 0:
                      title = "Notices";
                      snippet = "Latest: Mid-term exams rescheduled.";
                      icon = Icons.notifications_active_rounded;
                      iconColor = Colors.indigo;
                      break;
                    case 1:
                      title = "Routine";
                      snippet = "Next class: ITM-401 at 10:30 AM (Room 602)";
                      icon = Icons.schedule_rounded;
                      iconColor = Colors.green;
                      break;
                    case 2:
                      title = "Assignments";
                      snippet = "Upcoming: Database Project due in 3 days.";
                      icon = Icons.assignment_rounded;
                      iconColor = Colors.orange;
                      break;
                    case 3:
                      title = "Events";
                      snippet = "IT Fest 2025: Registrations open!";
                      icon = Icons.event_note_rounded;
                      iconColor = Colors.purple;
                      break;
                    case 4:
                      title = "Resources";
                      snippet = "New: Python Programming E-book.";
                      icon = Icons.folder_open_rounded;
                      iconColor = Colors.teal;
                      break;
                    case 5:
                      title = "Community";
                      snippet = "New post: Help with Flutter project.";
                      icon = Icons.people_alt_rounded;
                      iconColor = Colors.redAccent;
                      break;
                  }

                  return Animate(
                    effects: [
                      FadeEffect(duration: 300.ms, delay: (index * 100).ms),
                      SlideEffect(begin: const Offset(0, 0.1), duration: 300.ms),
                    ],
                    child: InteractiveGlassCard(
                      onTap: () {
                        // Handle tap for each feature card
                        switch (index) {
                          case 0:
                            // Navigate to Notices
                            break;
                          case 1:
                            // Navigate to Routine
                            break;
                          case 2:
                            // Navigate to Assignments
                            break;
                          case 3:
                            // Navigate to Events
                            break;
                          case 4:
                            // Navigate to Resources
                            break;
                          case 5:
                            // Navigate to Community
                            break;
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: iconColor, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Marketing & Showcase Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "ITM Highlights",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white), 
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
              ),
              const SizedBox(height: 16),
              const BannerCarousel().animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

              const SizedBox(height: 32),

              
              Column(
                children: [
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(begin: Offset(0, 0.1), duration: Duration(milliseconds: 500)),
                    ],
                    child: InteractiveGlassCard(
                      onTap: () {
                        // Navigate to Latest Discussion details
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.forum_rounded, color: Colors.cyan, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Latest Discussion",
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "What are the best practices for secure coding in Python? - by John Doe", // Dynamic content placeholder
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(begin: Offset(0, 0.1), duration: Duration(milliseconds: 500)),
                    ],
                    child: InteractiveGlassCard(
                      onTap: () {
                        // Navigate to Quick Poll details or interact with poll
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.poll_rounded, color: Colors.lime, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Quick Poll",
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Will you join the upcoming IT Fest?", // Dynamic content placeholder
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Yes"),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("No"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 32),
              _buildHighlightsGrid(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsGrid(BuildContext context) {
    final highlights = [
      {'icon': FontAwesomeIcons.rocket, 'title': "Innovation", 'color': Colors.amber},
      {'icon': FontAwesomeIcons.userTie, 'title': "Career Focus", 'color': Colors.blueAccent},
      {'icon': FontAwesomeIcons.earthAmericas, 'title': "Global Vision", 'color': Colors.deepPurple},
      {'icon': FontAwesomeIcons.shieldHalved, 'title': "Cyber Safety", 'color': Colors.redAccent},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.3,
      ),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        final item = highlights[index];
        return Animate(
          effects: [
            FadeEffect(
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: index * 140),
            ),
            SlideEffect(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: index * 140),
            ),
          ],
          child: InteractiveGlassCard( // Using new interactive card
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.13),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (item['color'] as Color).withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FaIcon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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