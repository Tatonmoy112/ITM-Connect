class News {
  final String id;
  final String title;
  final String body;
  final String date;
  final String imageUrl;
  final String facebookUrl;

  News({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.imageUrl,
    this.facebookUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'date': date,
      'imageUrl': imageUrl,
      'facebookUrl': facebookUrl,
    };
  }

  factory News.fromMap(Map<String, dynamic> map, String id) {
    return News(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      facebookUrl: map['facebookUrl'] ?? '',
    );
  }
}
