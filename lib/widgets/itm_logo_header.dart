import 'package:flutter/material.dart';

class ITMLogoHeader extends StatelessWidget {
  final bool centerText;

  const ITMLogoHeader({super.key, this.centerText = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: centerText ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        // Green circular background with hat logo
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/Itm_logo.png', // ✅ Your uploaded green hat logo
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // App name and optional subtitle
        Column(
          crossAxisAlignment: centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: const [
            Text(
              'ITM Connect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Department of ITM',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
