class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String url;
  final String imageUrl;
  final String source;
  final String category;
  final DateTime publishedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.category,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      publishedAt:
          DateTime.tryParse((json['publishedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
