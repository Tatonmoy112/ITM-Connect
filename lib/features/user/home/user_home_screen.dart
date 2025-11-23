import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
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
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerPadding = isMobile ? 10.0 : (isTablet ? 12.0 : 14.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
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
                                color: Colors.teal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            const Text(
                              'Ms. Nusrat Jahan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2c3e50),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Welcome message
                            Text(
                              'Welcome to the Department of Information and Technology Management. We are committed to providing excellent education and nurturing the next generation of IT professionals with cutting-edge knowledge and practical skills.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
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
                            'assets/images/Ms. Nusrat Jahan.jfif',
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
                          color: const Color(0xFF2c3e50),
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
                  const SizedBox(height: 32),
                  
                  // ============ FOOTER SECTION WITH SOCIAL ICONS ============
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.05),
                          Colors.blue.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.teal.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Connect With Us',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2c3e50),
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
                              url: '',
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              icon: Icons.language,
                              color: Color(0xFF0EA5E9),
                              label: 'Twitter',
                              url: '',
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              icon: Icons.photo_camera_rounded,
                              color: Color(0xFFE4405F),
                              label: 'Instagram',
                              url: '',
                            ),
                            const SizedBox(width: 20),
                            _buildSocialIcon(
                              icon: Icons.linked_camera,
                              color: Color(0xFF0A66C2),
                              label: 'LinkedIn',
                              url: '',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Department of Information & Technology Management',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2024 Daffodil International University',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
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
    ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0);
  }
  
  // Helper method to build social media icons
  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: url.isNotEmpty
          ? () async {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
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