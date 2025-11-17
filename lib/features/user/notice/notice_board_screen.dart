import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});

  // 🔧 Dummy notices (replace with Firebase later)
  List<Map<String, String>> getDummyNotices() {
    return [
      {
        'title': 'Orientation Program',
        'description':
            'Join us for the orientation of the new semester on Monday at 10 AM in Auditorium.',
        'date': '2025-07-01',
        'type': 'event',
      },
      {
        'title': 'Exam Schedule Published',
        'description':
            'Final exam schedule is published. Check your batch-wise routine.',
        'date': '2025-07-05',
        'type': 'schedule',
      },
      {
        'title': 'Holiday Notice',
        'description': 'University will remain closed on July 10th for Eid-ul-Adha.',
        'date': '2025-07-03',
        'type': 'holiday',
      },
    ];
  }

  IconData _getNoticeIcon(String type) {
    switch (type) {
      case 'event':
        return Icons.celebration_rounded; // More festive for events
      case 'schedule':
        return Icons.schedule_rounded; // Modern schedule icon
      case 'holiday':
        return Icons.park_rounded; // More professional for holidays
      default:
        return Icons.info_rounded; // General info icon
    }
  }

  Color _getNoticeColor(String type) {
    switch (type) {
      case 'event':
        return Colors.indigo;
      case 'schedule':
        return Colors.teal;
      case 'holiday':
        return Colors.deepOrange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notices = getDummyNotices();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // ✅ Matches header
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            final type = notice['type'] ?? '';
            final icon = _getNoticeIcon(type);
            final color = _getNoticeColor(type);

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: color,
                    width: 5,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notice['description'] ?? '',
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                notice['date'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fade(duration: 400.ms)
                .slide(begin: const Offset(0, 0.1), duration: 400.ms);
          },
        ),
      ),
    );
  }
}
