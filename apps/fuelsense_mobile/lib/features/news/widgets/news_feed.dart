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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(height: 5),
                  Text(
                    'What’s happening now',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updates on fuel, mobility and the auto industry',
                    style: TextStyle(color: theme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.border),
              ),
              child: Icon(
                Icons.newspaper_rounded,
                color: theme.accent,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        newsAsync.when(
          loading: () => const _NewsLoading(),
          error: (_, _) => _NewsMessage(
            icon: Icons.cloud_off_rounded,
            title: 'News feed unavailable',
            message: 'Try loading the news again.',
            actionLabel: 'Retry',
            onAction: () => ref.read(newsProvider.notifier).refresh(),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return _NewsMessage(
                icon: Icons.newspaper_rounded,
                title: 'No news to display',
                message: 'Refresh to check for available articles.',
                actionLabel: 'Refresh',
                onAction: () => ref.read(newsProvider.notifier).refresh(),
              );
            }
            return _NewsCarousel(articles: articles);
          },
        ),
      ],
    );
  }
}

class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel({required this.articles});

  final List<NewsArticle> articles;

  @override
  State<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<_NewsCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void didUpdateWidget(covariant _NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.articles.length) {
      _currentPage = widget.articles.isEmpty ? 0 : widget.articles.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_currentPage);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final count = widget.articles.length;
    final visibleDots = count > 5 ? 5 : count;

    return Column(
      children: [
        SizedBox(
          height: 310,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _NewsCard(article: widget.articles[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(visibleDots, (index) {
            final dotIndex = count <= 5
                ? index
                : (_currentPage - 2 + index).clamp(0, count - 1);
            final selected = dotIndex == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? theme.accent : theme.borderStrong,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article});

  final NewsArticle article;

  Future<void> _openArticle(BuildContext context) async {
    final uri = Uri.tryParse(article.url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showLinkError(context);
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) _showLinkError(context);
    } catch (_) {
      if (context.mounted) _showLinkError(context);
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This article link could not be opened.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final imageUrl = article.imageUrl.trim();

    return Material(
      color: theme.surfaceElevated,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openArticle(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.startsWith('https://'))
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _ImageFallback(category: article.category),
                    )
                  else
                    _ImageFallback(category: article.category),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            article.category.toUpperCase() == 'VEHICLE'
                                ? 'MOBILITY'
                                : 'FUEL UPDATE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.source.trim().isEmpty
                          ? 'FuelSense News'
                          : article.source.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Text(
                        article.title.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: theme.textMuted,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
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
                        Text(
                          'READ STORY',
                          style: TextStyle(
                            color: theme.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
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
    );
  }

  String _formatPublishedAt(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();

    if (local.isAfter(now)) return 'Recently published';

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
  const _ImageFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final vehicle = category.toLowerCase() == 'vehicle';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surfaceInteractive,
            theme.surface,
            theme.accent.withValues(alpha: 0.20),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              vehicle ? Icons.directions_car_rounded : Icons.local_gas_station,
              size: 150,
              color: theme.accent.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.surfaceElevated.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: theme.accent.withValues(alpha: 0.35)),
              ),
              child: Icon(
                vehicle
                    ? Icons.directions_car_filled_outlined
                    : Icons.local_gas_station_outlined,
                color: theme.accent,
                size: 30,
              ),
            ),
          ),
          Positioned(
            left: 15,
            top: 15,
            child: Text(
              'F U E L S E N S E',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ],
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
      height: 310,
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.border),
      ),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent),
      ),
    );
  }
}

class _NewsMessage extends StatelessWidget {
  const _NewsMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.accent, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
