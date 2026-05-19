class FeedbackEntry {
  final String id;
  final String date;
  final String time;
  final String email;
  final String name;
  final String feedbackType;
  final String message;

  FeedbackEntry({
    required this.id,
    required this.date,
    required this.time,
    required this.email,
    required this.name,
    required this.feedbackType,
    required this.message,
  });

  factory FeedbackEntry.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackEntry(
      id: id,
      date: (map['date'] ?? '').toString(),
      time: (map['time'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      feedbackType: (map['feedbackType'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
    );
  }
}
