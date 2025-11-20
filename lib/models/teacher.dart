class Teacher {
  final String id;
  final String name;
  final String email;
  final String role;
  final String imageUrl;
  // Optional: teacherInitial stored in Firestore (e.g. "TAT")
  final String teacherInitial;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
    this.teacherInitial = '',
  });
}
