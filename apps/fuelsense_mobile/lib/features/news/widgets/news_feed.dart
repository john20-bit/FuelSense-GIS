import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/app_theme_extension.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';

class NewsFeed extends ConsumerWidget {
  const NewsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final newsAsync = ref.watch(newsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NewsHeader(theme: theme),
        const SizedBox(height: 12),
        newsAsync.when(
          loading: () => const _NewsLoading(),
          error: (_, _) => _NewsError(
            onRetry: () => ref.read(newsProvider.notifier).refresh(),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return _NewsEmpty(
                onRetry: () => ref.read(newsProvider.notifier).refresh(),
              );
            }

            return SizedBox(
              height: 244,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: articles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _NewsCard(article: articles[index]);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewsHeader extends StatelessWidget {
  final dynamic theme;

  const _NewsHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUEL & VEHICLE NEWS',
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What’s happening now',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Updates on fuel, mobility and the auto industry',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: theme.border),
          ),
          child: Icon(
            Icons.rss_feed_rounded,
            color: theme.accent,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;

  const _NewsCard({required this.article});

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(article.url.trim());

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showLinkError(context);
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This article link could not be opened.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return SizedBox(
      width: 286,
      child: Material(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openArticle(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                width: double.infinity,
                child: article.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _ImageFallback(theme: theme),
                      )
                    : _ImageFallback(theme: theme),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            article.category.toLowerCase() == 'vehicle'
                                ? Icons.directions_car_filled_outlined
                                : Icons.local_gas_station_outlined,
                            color: theme.accent,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              article.source.trim().isEmpty
                                  ? 'FuelSense News'
                                  : article.source.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          article.title.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: theme.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatPublishedAt(article.publishedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: theme.accent,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPublishedAt(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();

    if (local.isAfter(now)) {
      return 'Recently published';
    }

    final difference = now.difference(local);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes <= 1 ? 'Just now' : '$minutes min ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hr${hours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _ImageFallback extends StatelessWidget {
  final dynamic theme;

  const _ImageFallback({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.article_outlined,
        color: theme.textMuted,
        size: 34,
      ),
    );
  }
}

class _NewsLoading extends StatelessWidget {
  const _NewsLoading();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      height: 244,
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading the latest updates',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _NewsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return _NewsMessagePanel(
      theme: theme,
      icon: Icons.cloud_off_rounded,
      title: 'News feed unavailable',
      message: 'Try loading the news again.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _NewsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _NewsEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return _NewsMessagePanel(
      theme: theme,
      icon: Icons.newspaper_rounded,
      title: 'No news to display',
      message: 'Refresh the feed to check for available articles.',
      actionLabel: 'Refresh',
      onAction: onRetry,
    );
  }
}

class _NewsMessagePanel extends StatelessWidget {
  final dynamic theme;
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _NewsMessagePanel({
    required this.theme,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.accent, size: 28),
          const SizedBox(height: 9),
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
