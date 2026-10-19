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

  /// Accepts a plain HTTPS URL or a Markdown link containing one.
  static String normalizeUrl(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '';

    var candidate = raw;

    final open = raw.indexOf('](');
    if (raw.startsWith('[') && open > 1 && raw.endsWith(')')) {
      candidate = raw.substring(open + 2, raw.length - 1).trim();
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      return '';
    }

    return uri.toString();
  }

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      url: normalizeUrl(json['url']),
      imageUrl: normalizeUrl(json['imageUrl']),
      source: (json['source'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      publishedAt:
          DateTime.tryParse((json['publishedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
