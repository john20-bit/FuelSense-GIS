import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/news_article.dart';

class NewsRepository {
  NewsRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Duration _maximumArticleAge = Duration(days: 14);
  static const String _assetPath = 'assets/news/news_preview.json';

  Future<List<NewsArticle>> getNews({
    int limit = 10,
    String? category,
  }) async {
    if (limit <= 0) {
      throw ArgumentError('News limit must be greater than zero.');
    }

    final normalizedCategory = category?.trim().toLowerCase();

    if (normalizedCategory != null &&
        normalizedCategory.isNotEmpty &&
        normalizedCategory != 'fuel' &&
        normalizedCategory != 'vehicle') {
      throw ArgumentError(
        'News category must be fuel, vehicle, or null for both.',
      );
    }

    // Show bundled articles immediately instead of waiting for network access.
    try {
      final localArticles = await _loadLocalNews(
        category: normalizedCategory,
      );
      if (localArticles.isNotEmpty) {
        return localArticles.take(limit).toList();
      }
    } on FormatException {
      // Try Firestore if the bundled asset cannot be parsed.
    } on Exception {
      // Try Firestore if the local asset cannot be loaded.
    }

    // Network fallback is used only when local news is unavailable.
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('news');

      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        query = query.where('category', isEqualTo: normalizedCategory);
      }

      final snapshot = await query
          .orderBy('publishedAt', descending: true)
          .limit(limit * 3)
          .get()
          .timeout(const Duration(seconds: 3));

      final articles = _prepareArticles(
        snapshot.docs.map(
          (document) => _fromFirestore(document.id, document.data()),
        ),
        category: normalizedCategory,
      );

      return articles.take(limit).toList();
    } on FirebaseException {
      return [];
    } on Exception {
      return [];
    }
  }

  Future<List<NewsArticle>> getLocalNews({int limit = 10}) async {
    if (limit <= 0) {
      throw ArgumentError('News limit must be greater than zero.');
    }

    final articles = await _loadLocalNews();
    return articles.take(limit).toList();
  }

  Future<List<NewsArticle>> getRemoteNews({int limit = 10}) async {
    if (limit <= 0) {
      throw ArgumentError('News limit must be greater than zero.');
    }

    final snapshot = await _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(limit * 3)
        .get()
        .timeout(const Duration(seconds: 3));

    final articles = _prepareArticles(
      snapshot.docs.map(
        (document) => _fromFirestore(document.id, document.data()),
      ),
    );

    return articles.take(limit).toList();
  }

  Future<List<NewsArticle>> _loadLocalNews({
    String? category,
  }) async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw const FormatException(
        'Local news asset must contain a list.',
      );
    }

    final articles = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(
          (item) => NewsArticle.fromJson({
            ...item,
            'id': item['id'] ?? item['url'] ?? item['title'] ?? '',
            'imageUrl': item['imageUrl'] ?? '',
          }),
        );

    return _prepareArticles(
      articles,
      category: category,
    );
  }

  List<NewsArticle> _prepareArticles(
    Iterable<NewsArticle> input, {
    String? category,
  }) {
    final now = DateTime.now().toUtc();
    final earliest = now.subtract(_maximumArticleAge);
    final seen = <String>{};
    final result = <NewsArticle>[];

    for (final article in input) {
      if (!_isUsable(article)) {
        continue;
      }

      final normalizedCategory = article.category.trim().toLowerCase();

      if (category != null &&
          category.isNotEmpty &&
          normalizedCategory != category) {
        continue;
      }

      if (normalizedCategory != 'fuel' &&
          normalizedCategory != 'vehicle') {
        continue;
      }

      final publishedAt = article.publishedAt.toUtc();

      if (publishedAt.isBefore(earliest) || publishedAt.isAfter(now)) {
        continue;
      }

      final uri = Uri.parse(article.url.trim());
      final canonicalUrl = uri.replace(
        fragment: '',
      ).toString().toLowerCase();

      final titleKey = article.title
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');

      final normalizedTitleKey = 'title:$titleKey';

      if (seen.contains(canonicalUrl) ||
          seen.contains(normalizedTitleKey)) {
        continue;
      }

      seen.add(canonicalUrl);
      seen.add(normalizedTitleKey);
      result.add(article);
    }

    result.sort(
      (a, b) => b.publishedAt.compareTo(a.publishedAt),
    );

    return result;
  }

  bool _isUsable(NewsArticle article) {
    final uri = Uri.tryParse(article.url.trim());

    return article.title.trim().isNotEmpty &&
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        article.publishedAt.millisecondsSinceEpoch > 0;
  }

  NewsArticle _fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final publishedAt = _dateTimeFromValue(data['publishedAt']);

    return NewsArticle.fromJson({
      'id': documentId,
      'title': data['title'],
      'summary': data['summary'],
      'url': data['url'],
      'imageUrl': data['imageUrl'],
      'source': data['source'],
      'category': data['category'],
      'publishedAt': publishedAt.toIso8601String(),
    });
  }

  DateTime _dateTimeFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
