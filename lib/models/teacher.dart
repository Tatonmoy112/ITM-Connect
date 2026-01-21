class Teacher {
  final String id;
  final String name;
  final String email;
  final String role;
  final String imageUrl;
  // Optional: teacherInitial stored in Firestore (e.g. "TAT")
  final String teacherInitial;
  final List<String> consultingHours;
  
  // For backward compatibility
  String get consultingHour => consultingHours.isNotEmpty ? consultingHours.join(', ') : '';

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
    this.teacherInitial = '',
    this.consultingHours = const [],
  });
}
