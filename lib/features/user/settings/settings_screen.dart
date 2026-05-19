import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itm_connect/theme/app_colors.dart';
import 'package:itm_connect/theme/theme_provider.dart';
import 'package:itm_connect/features/user/feedback/feedback_screen.dart';
import 'package:itm_connect/features/landing/role_setup_screen.dart';
import 'package:itm_connect/services/schedule_service.dart';
import 'package:itm_connect/widgets/notification_schedule_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth =
        isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              horizontalPadding, horizontalPadding, horizontalPadding, horizontalPadding + 90),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: containerMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: ITMColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ITMColors.gradientStart.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CustomPaint(
                              painter: _GearIconPainter(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: isMobile ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Customize your experience',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 24),

                  // ─── Appearance Section ───
                  _buildSectionLabel('Appearance', theme),
                  const SizedBox(height: 12),
                  _buildThemeToggleCard(context, theme, isDark),

                  const SizedBox(height: 24),

                  // ─── General Section ───
                  _buildSectionLabel('General', theme),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    icon: Icon(Icons.feedback_rounded, color: ITMColors.accentOrange, size: 22),
                    iconColor: ITMColors.accentOrange,
                    title: 'Feedback',
                    subtitle: 'Share your thoughts and suggestions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FeedbackScreen()),
                      );
                    },
                    delay: 200,
                  ),
                  const SizedBox(height: 10),
                  _buildSettingsTile(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    icon: Icon(Icons.notifications_rounded, color: ITMColors.info, size: 22),
                    iconColor: ITMColors.info,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () {
                      NotificationScheduleDialog.show(context);
                    },
                    delay: 300,
                  ),
                  const SizedBox(height: 10),
                  _buildSettingsTile(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    icon: SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _BadgeIconPainter(color: ITMColors.gradientEnd),
                      ),
                    ),
                    iconColor: ITMColors.gradientEnd,
                    title: 'Edit Your Status',
                    subtitle: 'Update your Role and Batch/Initial',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoleSetupScreen(isFromSettings: true),
                        ),
                      );
                    },
                    delay: 400,
                  ),
                  const SizedBox(height: 10),
                  _buildSettingsTile(
                    context: context,
                    theme: theme,
                    isDark: isDark,
                    icon: SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(
                        painter: _SilentBellIconPainter(color: ITMColors.error),
                      ),
                    ),
                    iconColor: ITMColors.error,
                    title: 'Clear Notification Status',
                    subtitle: 'Remove your role info and stop notifications',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Status?'),
                          content: const Text(
                            'This will remove your saved role and batch/initial, and cancel all scheduled class notifications. You can set it up again anytime.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ITMColors.error,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        await ScheduleService().clearNotifications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('Status cleared. Notifications disabled.'),
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    delay: 500,
                  ),

                  const SizedBox(height: 24),

                  // ─── About Section ───
                  _buildSectionLabel('About', theme),
                  const SizedBox(height: 12),
                  _buildAboutCard(context, theme, isDark),

                  const SizedBox(height: 24),

                  // ─── App Info Footer ───
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ITMColors.gradientStart.withOpacity(0.1),
                                ITMColors.gradientEnd.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Made with ❤️ for ITM Students',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? ITMColors.darkTextTertiary
                                  : ITMColors.lightTextTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© ${DateTime.now().year} Department of ITM, DIU',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? ITMColors.darkTextTertiary
                                : ITMColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? ITMColors.darkTextTertiary : ITMColors.lightTextTertiary,
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildThemeToggleCard(
      BuildContext context, ThemeData theme, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ITMColors.darkCard : ITMColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : ITMColors.gradientStart)
                .withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animated icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        colors: [
                          Colors.indigo.shade900,
                          Colors.deepPurple.shade900,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.amber.shade100,
                          Colors.orange.shade100,
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: SizedBox(
                  key: ValueKey(isDark),
                  width: 26,
                  height: 26,
                  child: CustomPaint(
                    painter: _ThemeIconPainter(
                      color: isDark ? Colors.amber.shade200 : Colors.orange.shade700,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? ITMColors.darkTextPrimary
                          : ITMColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDark
                        ? 'Easy on the eyes at night'
                        : 'Clean and bright interface',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? ITMColors.darkTextSecondary
                          : ITMColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Theme switch
            Transform.scale(
              scale: 1.1,
              child: Switch.adaptive(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: ITMColors.gradientEnd,
                activeTrackColor: ITMColors.gradientEnd.withOpacity(0.3),
                inactiveThumbColor: Colors.orange.shade400,
                inactiveTrackColor: Colors.orange.shade100,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.1);
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Widget icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int delay = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ITMColors.darkCard : ITMColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ITMColors.darkTextPrimary
                            : ITMColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ITMColors.darkTextSecondary
                            : ITMColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? ITMColors.darkTextTertiary
                    : ITMColors.lightTextTertiary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: delay.ms).slideX(begin: 0.1);
  }

  Widget _buildAboutCard(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ITMColors.darkCard : ITMColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ITMColors.darkCardBorder : ITMColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ITMColors.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: ITMColors.gradientStart.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'ITM Connect',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? ITMColors.darkTextPrimary
                  : ITMColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ITMColors.gradientEnd.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ITMColors.gradientEnd,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? ITMColors.darkDivider : ITMColors.lightDivider,
          ),
          const SizedBox(height: 12),
          _aboutInfoRow(
            Icons.business_rounded,
            'Department of Information Technology & Management',
            isDark,
          ),
          const SizedBox(height: 10),
          _aboutInfoRow(
            Icons.location_city_rounded,
            'Daffodil International University',
            isDark,
          ),
          const SizedBox(height: 10),
          _aboutInfoRow(
            Icons.location_on_rounded,
            'Daffodil Smart City (DSC), Birulia, Savar, Dhaka',
            isDark,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _aboutInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? ITMColors.darkTextTertiary : ITMColors.lightTextTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ITMColors.darkTextSecondary
                  : ITMColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _GearIconPainter extends CustomPainter {
  final Color color;
  const _GearIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;

    // 1. Draw the teeth (8 spokes)
    final toothPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int i = 0; i < 8; i++) {
      final double angle = i * (2 * math.pi / 8);
      final double cosVal = math.cos(angle);
      final double sinVal = math.sin(angle);
      // Spokes radiating from 0.40 * cx to 0.80 * cx
      canvas.drawLine(
        Offset(cx + cx * 0.40 * cosVal, cy + cy * 0.40 * sinVal),
        Offset(cx + cx * 0.80 * cosVal, cy + cy * 0.80 * sinVal),
        toothPaint,
      );
    }

    // 2. Outer rim (thick circle stroke for a hollow cylinder body)
    final rimPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.14
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(cx, cy), w * 0.28, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _GearIconPainter old) => old.color != color;
}

class _ThemeIconPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  const _ThemeIconPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    if (isDark) {
      // Draw Crescent Moon
      final path = Path();
      path.moveTo(w * 0.65, h * 0.20);
      path.quadraticBezierTo(w * 0.25, h * 0.35, w * 0.35, h * 0.75);
      path.quadraticBezierTo(w * 0.60, h * 0.85, w * 0.80, h * 0.60);
      path.quadraticBezierTo(w * 0.48, h * 0.52, w * 0.65, h * 0.20);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      // Draw Sun
      final cx = w * 0.5;
      final cy = h * 0.5;
      // Center circle
      canvas.drawCircle(Offset(cx, cy), w * 0.25, paint);

      // 8 rays
      final rayPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      for (int i = 0; i < 8; i++) {
        final double angle = i * (2 * math.pi / 8);
        final double cosVal = math.cos(angle);
        final double sinVal = math.sin(angle);
        canvas.drawLine(
          Offset(cx + cx * 0.42 * cosVal, cy + cy * 0.42 * sinVal),
          Offset(cx + cx * 0.76 * cosVal, cy + cy * 0.76 * sinVal),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeIconPainter old) =>
      old.color != color || old.isDark != isDark;
}

class _BadgeIconPainter extends CustomPainter {
  final Color color;
  const _BadgeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Draw outer card outline
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(card, strokePaint);

    // 2. Draw card clip attachment at the top (horizontal slot)
    final slotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.02, w * 0.20, h * 0.06),
        Radius.circular(w * 0.02),
      ),
      slotPaint,
    );

    // 3. User Avatar inside
    // Head circle:
    canvas.drawCircle(Offset(w * 0.50, h * 0.38), w * 0.12, paint);

    // Shoulders:
    final shoulders = Path();
    shoulders.moveTo(w * 0.28, h * 0.74);
    shoulders.quadraticBezierTo(w * 0.28, h * 0.54, w * 0.50, h * 0.54);
    shoulders.quadraticBezierTo(w * 0.72, h * 0.54, w * 0.72, h * 0.74);
    shoulders.close();
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _BadgeIconPainter old) => old.color != color;
}

class _SilentBellIconPainter extends CustomPainter {
  final Color color;
  const _SilentBellIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Bell body path
    final path = Path();
    path.moveTo(w * 0.15, h * 0.72);
    path.quadraticBezierTo(w * 0.15, h * 0.35, w * 0.30, h * 0.25);
    path.quadraticBezierTo(w * 0.38, h * 0.15, w * 0.50, h * 0.12);
    path.quadraticBezierTo(w * 0.62, h * 0.15, w * 0.70, h * 0.25);
    path.quadraticBezierTo(w * 0.85, h * 0.35, w * 0.85, h * 0.72);
    path.lineTo(w * 0.15, h * 0.72);
    path.close();
    canvas.drawPath(path, paint);

    // 2. Rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.70, w * 0.80, h * 0.08),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(rimRect, paint);

    // 3. Clapper
    canvas.drawCircle(Offset(w * 0.50, h * 0.88), w * 0.08, paint);

    // 4. Handle nub
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), w * 0.05, paint);

    // 5. Diagonal Slash line with visual spacing
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());

    final slashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final bgSlashPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.16
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawLine(Offset(w * 0.10, h * 0.15), Offset(w * 0.90, h * 0.85), bgSlashPaint);
    canvas.drawLine(Offset(w * 0.10, h * 0.15), Offset(w * 0.90, h * 0.85), slashPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SilentBellIconPainter old) => old.color != color;
}
