class RoutineClass {
  final String courseName;
  final String courseCode;
  final String teacherName;
  final String teacherInitial;
  final String room;
  final String time;

  RoutineClass({
    required this.courseName,
    required this.courseCode,
    required this.teacherName,
    required this.teacherInitial,
    required this.room,
    required this.time,
  });

  factory RoutineClass.fromMap(Map<String, dynamic> map) {
    return RoutineClass(
      courseName: map['courseName'] ?? '',
      courseCode: map['courseCode'] ?? '',
      teacherName: map['teacherName'] ?? '',
      teacherInitial: map['teacherInitial'] ?? '',
      room: map['room'] ?? '',
      time: map['time'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'courseCode': courseCode,
      'teacherName': teacherName,
      'teacherInitial': teacherInitial,
      'room': room,
      'time': time,
    };
  }
}

class Routine {
  final String id; // document id e.g. "6_Sat" or "56th_Sat"
  final String batch;
  final String day;
  final List<RoutineClass> classes;

  Routine({
    required this.id,
    required this.batch,
    required this.day,
    required this.classes,
  });

  factory Routine.fromMap(String id, Map<String, dynamic>? map) {
    final rawClasses = (map?['classes'] as List<dynamic>?) ?? [];
    final classes = rawClasses.map((e) => RoutineClass.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    return Routine(
      id: id,
      batch: map?['batch'] ?? '',
      day: map?['day'] ?? '',
      classes: classes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'batch': batch,
      'day': day,
      'classes': classes.map((c) => c.toMap()).toList(),
    };
  }
}
