class Feedback {
  final String id;
  final String name;
  final String email;
  final String feedbackType;
  final String message;
  final String date;
  final String time;

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
      'date': date,
      'time': time,
      'email': email,
      'name': name,
      'feedbackType': feedbackType,
      'message': message,
    };
  }

  factory Feedback.fromMap(String id, Map<String, dynamic> map) {
    return Feedback(
      id: id,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      feedbackType: (map['feedbackType'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      time: (map['time'] ?? '').toString(),
    );
  }
}

