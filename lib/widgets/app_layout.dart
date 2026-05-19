import 'package:flutter/material.dart';

import 'package:itm_connect/theme/app_colors.dart';

class AppLayout extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNavBar;
  final bool showFloatingActionButton;
  final int currentIndex;
  final Widget body;
  final void Function(int index) onBottomNavTap;
  final Widget? leading;
  final bool hasNewNotification;
  final VoidCallback? onNotificationTap;

  const AppLayout({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.showFloatingActionButton = true,
    this.currentIndex = -1,
    required this.onBottomNavTap,
    this.leading,
    this.hasNewNotification = false,
    this.onNotificationTap,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _floatingAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.08),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: isDark ? ITMColors.darkAppBar : ITMColors.lightAppBar,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: widget.leading ??
                  IconButton(
                    icon: Icon(
                      Icons.home,
                      color: isDark ? ITMColors.gradientEnd : ITMColors.gradientStart,
                      size: 26.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false);
                    },
                  ),
              title: SlideTransition(
                position: _floatingAnimation,
                child: _buildLogo(isDark),
              ),
              centerTitle: true,
              actions: [
                // Notification Bell Icon with Badge
                Stack(
                  children: [
                    IconButton(
                      icon: _buildBellIcon(
                        size: 24.0,
                        color: widget.hasNewNotification
                            ? ITMColors.warning
                            : (isDark
                                ? ITMColors.gradientEnd
                                : ITMColors.gradientStart),
                        isActive: widget.hasNewNotification,
                      ),
                      tooltip: 'Notifications',
                      onPressed: widget.onNotificationTap,
                    ),
                    if (widget.hasNewNotification)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ITMColors.error,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: isDark ? ITMColors.gradientEnd : ITMColors.gradientStart,
                  ),
                  tooltip: 'Admin Login',
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          SafeArea(child: widget.body),
          if (widget.showBottomNavBar)
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 480;
                final isMediumScreen =
                    constraints.maxWidth >= 480 && constraints.maxWidth < 750;

                late double iconSize;
                late double fontSize;
                late double navBarHeight;
                late double calendarPadding;
                late double calendarIconSize;

                if (isSmallScreen) {
                  iconSize = 18.0;
                  fontSize = 10.0;
                  navBarHeight = 65.0;
                  calendarPadding = 6.0;
                  calendarIconSize = 18.0;
                } else if (isMediumScreen) {
                  iconSize = 20.0;
                  fontSize = 11.0;
                  navBarHeight = 70.0;
                  calendarPadding = 8.0;
                  calendarIconSize = 20.0;
                } else {
                  iconSize = 24.0;
                  fontSize = 12.0;
                  navBarHeight = 80.0;
                  calendarPadding = 10.0;
                  calendarIconSize = 24.0;
                }

                final unselectedColor = isDark
                    ? ITMColors.navUnselectedDark
                    : ITMColors.navUnselectedLight;

                final navBarBgColor = isDark
                    ? ITMColors.darkNavBar
                    : Colors.white;

                final navBarBorderColor = isDark
                    ? ITMColors.darkCardBorder
                    : ITMColors.lightCardBorder;

                return SafeArea(
                  child: Container(
                    height: navBarHeight,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: 10.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: navBarBgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: navBarBorderColor,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.08,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 0 — Faculty
                        _buildNavItem(
                          index: 0,
                          icon: Icon(Icons.person_rounded, size: iconSize, color: widget.currentIndex == 0 ? ITMColors.gradientStart : unselectedColor),
                          label: "Faculty",
                          selectedColor: ITMColors.gradientStart,
                          isSelected: widget.currentIndex == 0,
                          fontSize: fontSize,
                          onTap: () => widget.onBottomNavTap(0),
                        ),
                        // 1 — Notices
                        _buildNavItem(
                          index: 1,
                          icon: Icon(Icons.notifications_rounded, size: iconSize, color: widget.currentIndex == 1 ? ITMColors.gradientEnd : unselectedColor),
                          label: "Notices",
                          selectedColor: ITMColors.gradientEnd,
                          isSelected: widget.currentIndex == 1,
                          fontSize: fontSize,
                          onTap: () => widget.onBottomNavTap(1),
                        ),
                        // 2 — Routine (special gradient circle when unselected)
                        _buildNavItem(
                          index: 2,
                          icon: widget.currentIndex == 2
                              ? Icon(Icons.calendar_month_rounded, size: iconSize, color: ITMColors.gradientStart)
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: ITMColors.brandGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: ITMColors.gradientEnd.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(calendarPadding),
                                  child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: calendarIconSize),
                                ),
                          label: "Routine",
                          selectedColor: ITMColors.gradientStart,
                          isSelected: widget.currentIndex == 2,
                          fontSize: fontSize,
                          onTap: () => widget.onBottomNavTap(2),
                        ),
                        // 3 — Contact
                        _buildNavItem(
                          index: 3,
                          icon: Icon(Icons.contact_mail_rounded, size: iconSize, color: widget.currentIndex == 3 ? ITMColors.gradientEnd : unselectedColor),
                          label: "Contact",
                          selectedColor: ITMColors.gradientEnd,
                          isSelected: widget.currentIndex == 3,
                          fontSize: fontSize,
                          onTap: () => widget.onBottomNavTap(3),
                        ),
                        // 4 — Settings (custom drawn icon — bypasses all icon fonts)
                        _buildNavItem(
                          index: 4,
                          icon: _buildSettingsIcon(
                            size: iconSize,
                            color: widget.currentIndex == 4 ? ITMColors.gradientStart : unselectedColor,
                          ),
                          label: "Settings",
                          selectedColor: ITMColors.gradientStart,
                          isSelected: widget.currentIndex == 4,
                          fontSize: fontSize,
                          onTap: () => widget.onBottomNavTap(4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget icon,
    required String label,
    required Color selectedColor,
    required bool isSelected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: isSelected
                ? const EdgeInsets.symmetric(vertical: 6, horizontal: 10)
                : const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: selectedColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Vertical 3-dot settings icon — no icon font dependency.
  Widget _buildSettingsIcon({required double size, required Color color}) {
    final dotSize = size * 0.22;
    final spacing = size * 0.12;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: dotSize, height: dotSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(height: spacing),
          Container(width: dotSize, height: dotSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(height: spacing),
          Container(width: dotSize, height: dotSize, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  /// Custom notification bell icon — no icon font dependency.
  Widget _buildBellIcon({required double size, required Color color, bool isActive = false}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BellIconPainter(color: color, isActive: isActive),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ITMColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: ITMColors.gradientEnd.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isDark ? ITMColors.darkSurface : Colors.white,
        child: ShaderMask(
          shaderCallback: (bounds) =>
              ITMColors.brandGradient.createShader(bounds),
          child: const Icon(
            Icons.school,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Draws a notification bell icon using Canvas paths — no icon font needed.
class _BellIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  const _BellIconPainter({required this.color, this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Bell body path
    final path = Path();
    // Start from bottom-left of bell opening
    path.moveTo(w * 0.15, h * 0.72);
    // Left side curve up
    path.quadraticBezierTo(w * 0.15, h * 0.35, w * 0.30, h * 0.25);
    // Left shoulder to top
    path.quadraticBezierTo(w * 0.38, h * 0.15, w * 0.50, h * 0.12);
    // Top to right shoulder
    path.quadraticBezierTo(w * 0.62, h * 0.15, w * 0.70, h * 0.25);
    // Right side curve down
    path.quadraticBezierTo(w * 0.85, h * 0.35, w * 0.85, h * 0.72);
    // Bottom bar
    path.lineTo(w * 0.15, h * 0.72);
    path.close();

    canvas.drawPath(path, paint);

    // Bottom bar (the rim)
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.70, w * 0.80, h * 0.08),
      Radius.circular(h * 0.04),
    );
    canvas.drawRRect(rimRect, paint);

    // Clapper (small circle at bottom center)
    canvas.drawCircle(Offset(w * 0.50, h * 0.88), w * 0.08, paint);

    // Handle nub at top
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), w * 0.05, paint);
  }

  @override
  bool shouldRepaint(covariant _BellIconPainter old) =>
      old.color != color || old.isActive != isActive;
}
