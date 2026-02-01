class BatchInfo {
  final String id; // This will be the batch number/name, e.g., "61" or "61st"
  final String session; // e.g., "Fall 2025"
  final String advisorName; // e.g., "Dr. Smith"
  final String totalStudents; // e.g., "45"
  final String department; // e.g., "ITM"
  final String section; // Optional, if needed

  BatchInfo({
    required this.id,
    this.session = '',
    this.advisorName = '',
    this.totalStudents = '',
    this.department = 'ITM',
    this.section = '',
  });

  factory BatchInfo.fromMap(String id, Map<String, dynamic>? map) {
    final m = map ?? {};
    return BatchInfo(
      id: id,
      session: m['session'] ?? '',
      advisorName: m['advisorName'] ?? '',
      totalStudents: (m['totalStudents'] ?? '').toString(),
      department: m['department'] ?? 'ITM',
      section: m['section'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session': session,
      'advisorName': advisorName,
      'totalStudents': totalStudents,
      'department': department,
      'section': section,
    };
  }
}
