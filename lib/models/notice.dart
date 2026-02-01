class Notice {
  final String id; // document id like '2025-11-18_ClassCancel'
  final String title;
  final String body;
  final String date; // YYYY-MM-DD
  final String? attachment; // Optional attachment URL

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.attachment,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': date,
      'attachment': attachment,
    };
  }

  factory Notice.fromMap(String id, Map<String, dynamic>? map) {
    final m = map ?? {};
    return Notice(
      id: id,
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      date: m['date'] ?? '',
      attachment: m['attachment'],
    );
  }
}
