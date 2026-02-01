import 'package:flutter/material.dart';

class UniversalHeader extends StatelessWidget {
  final bool showBackButton;
  final bool showDrawerButton; // ✅ New optional param
  final String? title;

  const UniversalHeader({
    super.key,
    this.showBackButton = false,
    this.showDrawerButton = true, // ✅ Default true to maintain old behavior
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 🍔 Back / Menu Button / Empty
            if (showDrawerButton)
              showBackButton
                  ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.green),
                onPressed: () => Navigator.of(context).pop(),
              )
                  : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.green),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            else
              const SizedBox(width: 48), // ✅ Keep layout balanced if no button

            const Spacer(),

            // 🧢 Icon + Title
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text(
                  title ?? 'ITM Connect',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const Spacer(),
            const SizedBox(width: 48), // Balance right side
          ],
        ),
      ),
    );
  }
}
