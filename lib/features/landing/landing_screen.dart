import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itm_connect/features/admin/login/admin_login_screen.dart';
import 'package:itm_connect/features/user/home/user_home_screen.dart';
import 'package:itm_connect/widgets/app_layout.dart';
 

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _cardController;
  late final AnimationController _buttonController;
  late final AnimationController _3dController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonController.forward();
    });

    _3dController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _cardController.dispose();
    _buttonController.dispose();
    _3dController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFF43cea2), const Color(0xFF185a9d), _bgController.value)!,
                Color.lerp(const Color(0xFFf5f5f5), const Color(0xFFe0f7fa), 1 - _bgController.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingLogo() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
          ],
        ),
        child: CircleAvatar(
          radius: 44,
          backgroundColor: Colors.white.withOpacity(0.85),
          child: Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.teal.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return FadeTransition(
      opacity: _cardController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.teal.withOpacity(0.18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _cardController,
                      child: Text(
                        'Information Technology & Management',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Colors.teal.shade900,
                          shadows: [
                            Shadow(
                              color: Colors.tealAccent.withOpacity(0.18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _cardController,
                      child: Text(
                        'One place for ITM information',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _cardController,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified, color: Colors.teal.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Empowering Students',
                            style: TextStyle(
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return FadeTransition(
      opacity: _buttonController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            splashColor: Colors.tealAccent.withOpacity(0.3),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserHomeScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 150,
                    child: const Text(
                      'GET STARTED',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      showAppBar: false,
      showBottomNavBar: false,
      currentIndex: -1,
      onBottomNavTap: (_) {},
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _3dController,
                      builder: (context, child) {
                              final angle = math.sin(_3dController.value * math.pi * 2) * 0.18; // subtle rocking
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                          alignment: Alignment.center,
                                child: child,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGlowingLogo(),
                          const SizedBox(height: 22),
                          _buildGlassCard(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 38),
                  child: Center(
                    child: _buildAnimatedButton().animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
                  ),
                ),
              ],
            ),
          ),
          // Floating admin button
          Positioned(
            top: 36,
            right: 18,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              color: Colors.indigo,
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                tooltip: 'Admin Login',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
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
