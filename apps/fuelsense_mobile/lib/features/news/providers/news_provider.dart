import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article.dart';
import '../repositories/news_repository.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository();
});

final newsProvider =
    AsyncNotifierProvider<NewsFeedNotifier, List<NewsArticle>>(
  NewsFeedNotifier.new,
);

class NewsFeedNotifier extends AsyncNotifier<List<NewsArticle>> {
  @override
  Future<List<NewsArticle>> build() async {
    final repository = ref.watch(newsRepositoryProvider);

    // Load the local snapshot first so the initial feed is fast.
    final localArticles = await repository.getLocalNews(limit: 10);

    // Refresh from Firestore without delaying the initial result.
    unawaited(_refreshInBackground(repository));

    return localArticles;
  }

  Future<void> _refreshInBackground(NewsRepository repository) async {
    try {
      final freshArticles = await repository.getRemoteNews(limit: 10);
      if (freshArticles.isNotEmpty) {
        state = AsyncData(freshArticles);
      }
    } catch (_) {
      // Keep the already visible local articles if refresh fails.
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(newsRepositoryProvider);
    final previous = state;
    state = const AsyncLoading<List<NewsArticle>>();

    try {
      final freshArticles = await repository.getRemoteNews(limit: 10);

      if (freshArticles.isNotEmpty) {
        state = AsyncData(freshArticles);
      } else if (previous.hasValue) {
        state = previous;
      } else {
        state = AsyncData(await repository.getLocalNews(limit: 10));
      }
    } catch (error, stackTrace) {
      if (previous.hasValue) {
        state = previous;
      } else {
        try {
          state = AsyncData(await repository.getLocalNews(limit: 10));
        } catch (_) {
          state = AsyncError(error, stackTrace);
        }
      }
    }
  }
}

final fuelNewsProvider = FutureProvider<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).getNews(
        limit: 10,
        category: 'fuel',
      );
});

final vehicleNewsProvider = FutureProvider<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).getNews(
        limit: 10,
        category: 'vehicle',
      );
});
