class Teacher {
  final String id; // Document ID (teacher initial, e.g., 'TAT', 'MIH')
  final String name;
  final String email;
  final String role;
  final String imageUrl;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
  });

  // Convert Teacher to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
    };
  }

  // Create Teacher from Firestore Map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // Copy with changes
  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? imageUrl,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() =>
      'Teacher(id: $id, name: $name, email: $email, role: $role, imageUrl: $imageUrl)';
}
