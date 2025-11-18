class Feedback {
  final String id; // document id like '2025-11-18_tonmoy@gmail.com'
  final String name;
  final String email;
  final String feedbackType;
  final String message;
  final String date; // YYYY-MM-DD
  final String time; // HH:MM:SS or timestamp

  Feedback({
    required this.id,
    required this.name,
    required this.email,
    required this.feedbackType,
    required this.message,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'feedbackType': feedbackType,
      'message': message,
      'date': date,
      'time': time,
    };
  }

  factory Feedback.fromMap(String id, Map<String, dynamic>? map) {
    final m = map ?? {};
    return Feedback(
      id: id,
      name: m['name'] ?? '',
      email: m['email'] ?? '',
      feedbackType: m['feedbackType'] ?? '',
      message: m['message'] ?? '',
      date: m['date'] ?? '',
      time: m['time'] ?? '',
    );
  }
}
