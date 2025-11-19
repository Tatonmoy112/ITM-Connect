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
  final String teacherInitial; // Teacher initial at routine document level
  final List<RoutineClass> classes;

  Routine({
    required this.id,
    required this.batch,
    required this.day,
    required this.teacherInitial,
    required this.classes,
  });

  factory Routine.fromMap(String id, Map<String, dynamic>? map) {
    if (map == null) {
      return Routine(
        id: id,
        batch: '',
        day: '',
        teacherInitial: '',
        classes: [],
      );
    }

    final rawClasses = map['classes'];
    List<RoutineClass> classes = [];

    if (rawClasses != null && rawClasses is List) {
      try {
        classes = rawClasses.map((e) {
          if (e is Map<String, dynamic>) {
            return RoutineClass.fromMap(e);
          } else if (e is Map) {
            return RoutineClass.fromMap(Map<String, dynamic>.from(e));
          }
          return null;
        }).whereType<RoutineClass>().toList();
      } catch (e) {
        print('Error parsing classes: $e');
        classes = [];
      }
    }

    return Routine(
      id: id,
      batch: map['batch'] ?? '',
      day: map['day'] ?? '',
      teacherInitial: map['teacherInitial'] ?? '',
      classes: classes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'batch': batch,
      'day': day,
      'teacherInitial': teacherInitial,
      'classes': classes.map((c) => c.toMap()).toList(),
    };
  }
}
