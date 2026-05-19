class ExamRoutine {
  final String id;
  final String examTitle; // e.g. "Mid Term Spring 2026"
  final String batch;
  final String courseName;
  final String courseCode;
  final String date; // YYYY-MM-DD
  final String time; // e.g. "10:00 AM - 12:00 PM"
  final String room;

  ExamRoutine({
    required this.id,
    required this.examTitle,
    required this.batch,
    required this.courseName,
    required this.courseCode,
    required this.date,
    required this.time,
    required this.room,
  });

  Map<String, dynamic> toMap() {
    return {
      'examTitle': examTitle,
      'batch': batch,
      'courseName': courseName,
      'courseCode': courseCode,
      'date': date,
      'time': time,
      'room': room,
    };
  }

  factory ExamRoutine.fromMap(String id, Map<String, dynamic>? map) {
    final m = map ?? {};
    return ExamRoutine(
      id: id,
      examTitle: m['examTitle'] ?? '',
      batch: m['batch'] ?? '',
      courseName: m['courseName'] ?? '',
      courseCode: m['courseCode'] ?? '',
      date: m['date'] ?? '',
      time: m['time'] ?? '',
      room: m['room'] ?? '',
    );
  }
}
