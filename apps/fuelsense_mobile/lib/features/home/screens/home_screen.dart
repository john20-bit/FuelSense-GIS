import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../core/design/design_tokens.dart';
import '../../../features/fuel/providers/fuel_station_provider.dart';
import '../../../features/news/widgets/news_feed.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final stationsAsync = ref.watch(fuelStationsProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _TopBar(),
                  const SizedBox(height: 26),
                  const _CommandHeader(),
                  const SizedBox(height: 20),
                  const NewsFeed(),
                  const SizedBox(height: 24),
                  _LiveMapCard(
                    stationsAsync: stationsAsync,
                    onTap: () => _tryNavigate(context, '/spatial-mapping'),
                  ),
                  const SizedBox(height: 24),
                  const _Footer(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _tryNavigate(BuildContext context, String route) {
    try {
      context.push(route);
    } catch (_) {
      // Keep Home stable if a destination route is not registered.
    }
  }
}

// -----------------------------------------------------------------------------
// TOP BAR
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          child: Icon(Icons.public_rounded, color: theme.accent, size: 22),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'F U E L S E N S E',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'FUEL & VEHICLE NETWORK',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: theme.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.success.withValues(alpha: 0.38),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// COMMAND HEADER
// -----------------------------------------------------------------------------

class _CommandHeader extends StatelessWidget {
  const _CommandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPATIAL DATA',
          style: TextStyle(
            color: theme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Your fuel network,\non the map.',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          'Fuel network • Spatial mapping • News',
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// LIVE GIS MAP
// -----------------------------------------------------------------------------

class _LiveMapCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> stationsAsync;
  final VoidCallback onTap;

  const _LiveMapCard({required this.stationsAsync, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    final stationCount = stationsAsync.when(
      data: (stations) => stations.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    final loading = stationsAsync.isLoading;

    final stationLabel = loading ? 'SCANNING' : '$stationCount NEARBY';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 235,
        decoration: BoxDecoration(
          color: FuelSenseDesignTokens.graphiteDeep,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _MapGridPainter(
                    gridColor: FuelSenseDesignTokens.graphiteSoft,
                    routeColor: FuelSenseDesignTokens.sageDeep,
                  ),
                ),
              ),
            ),

            Positioned(
              top: -80,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.accent.withValues(alpha: 0.045),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withValues(alpha: 0.06),
                        blurRadius: 90,
                        spreadRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: const _MapBadge(
                icon: Icons.radar_rounded,
                label: 'LIVE GIS',
              ),
            ),

            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: FuelSenseDesignTokens.graphiteDeep.withValues(
                    alpha: 0.88,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  stationLabel,
                  style: TextStyle(
                    color: loading ? theme.warning : theme.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 42,
              top: 105,
              child: _MapPoint(color: theme.accent),
            ),

            Positioned(
              right: 80,
              top: 80,
              child: _MapPoint(color: theme.accent),
            ),

            Positioned(
              right: 145,
              bottom: 58,
              child: _MapPoint(color: theme.accent),
            ),

            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Spatial operations map',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: FuelSenseDesignTokens.graphiteDeep,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP BADGE
// -----------------------------------------------------------------------------

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FuelSenseDesignTokens.graphiteDeep.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.accent),

          const SizedBox(width: 6),

          Text(
            label,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP POINT
// -----------------------------------------------------------------------------

class _MapPoint extends StatelessWidget {
  final Color color;

  const _MapPoint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: FuelSenseDesignTokens.graphiteDeep, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.42),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CURRENT VEHICLE
// -----------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Center(
      child: Text(
        'F U E L S E N S E   •   SYSTEM READY',
        style: TextStyle(
          color: theme.textMuted.withValues(alpha: 0.65),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP BACKGROUND PAINTER
// -----------------------------------------------------------------------------

class _MapGridPainter extends CustomPainter {
  final Color gridColor;
  final Color routeColor;

  const _MapGridPainter({required this.gridColor, required this.routeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    const spacing = 34.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = routeColor.withValues(alpha: 0.65)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width,
        size.height * 0.42,
      );

    canvas.drawPath(path, routePaint);

    final secondaryRoutePaint = Paint()
      ..color = gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final secondaryPath = Path()
      ..moveTo(size.width * 0.08, 0)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.55,
        size.width,
        size.height * 0.72,
      );

    canvas.drawPath(secondaryPath, secondaryRoutePaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor ||
        oldDelegate.routeColor != routeColor;
  }
}
