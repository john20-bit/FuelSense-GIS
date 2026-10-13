import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../features/news/widgets/news_feed.dart';
import '../../../features/fuel_prices/providers/daily_fuel_price_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;

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
                  const SizedBox(height: 26),
                  const _DailyFuelPrices(),
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

class _DailyFuelPrices extends ConsumerWidget {
  const _DailyFuelPrices();

  static const String city = 'Madurai';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final prices = ref.watch(dailyFuelPricesProvider(city));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY FUEL PRICES',
          style: TextStyle(
            color: theme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Know the rate before you refuel.',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$city · ₹ per litre',
          style: TextStyle(color: theme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        prices.when(
          loading: () => const Row(
            children: [
              Expanded(
                child: _FuelPriceCard(title: 'PETROL', value: 'Loading...'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FuelPriceCard(title: 'DIESEL', value: 'Loading...'),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: _FuelPriceCard(
                      title: 'PETROL',
                      value: 'Unavailable',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _FuelPriceCard(
                      title: 'DIESEL',
                      value: 'Unavailable',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Verified prices could not be loaded. Please try again later.',
                style: TextStyle(color: theme.textMuted, fontSize: 10),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(dailyFuelPricesProvider(city)),
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (data) {
            final updated = data.updatedAt;
            final updatedLabel = updated == null
                ? 'Update time not supplied by provider'
                : 'Updated ${updated.toLocal().toString().substring(0, 16)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FuelPriceCard(
                        title: 'PETROL',
                        value: '₹${data.petrol.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FuelPriceCard(
                        title: 'DIESEL',
                        value: '₹${data.diesel.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$updatedLabel · Source: ${data.source}',
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FuelPriceCard extends StatelessWidget {
  const _FuelPriceCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.startsWith('₹') ? 'per litre' : 'Live lookup',
            style: TextStyle(color: theme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

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
