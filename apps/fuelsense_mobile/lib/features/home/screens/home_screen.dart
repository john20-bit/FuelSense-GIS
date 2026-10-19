import 'package:flutter/material.dart';
import '../services/fuel_price_service.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../features/news/widgets/news_feed.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'FUEL OVERVIEW',
          style: TextStyle(
            color: theme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Your fuel updates,\nin one place.',
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
          'News â€¢ Daily fuel prices â€¢ Station updates',
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// DAILY FUEL PRICES
// -----------------------------------------------------------------------------


class _DailyFuelPrices extends StatefulWidget {
  const _DailyFuelPrices();

  @override
  State<_DailyFuelPrices> createState() => _DailyFuelPricesState();
}

class _DailyFuelPricesState extends State<_DailyFuelPrices> {
  final FuelPriceService _service = FuelPriceService();
  late Future<FuelPrices> _prices;

  static final Uri _officialPricesUri = Uri(
    scheme: 'https',
    host: 'iocl.com',
    path: '/petrol-diesel-price',
  );

  @override
  void initState() {
    super.initState();
    _prices = _service.fetchPrices('Chennai');
  }

  void _retry() {
    setState(() {
      _prices = _service.fetchPrices('Chennai');
    });
  }

  Future<void> _openOfficialPrices() async {
    await launchUrl(
      _officialPricesUri,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

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
          'Check the latest rates before you refuel.',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Live fuel prices • API Mitra',
          style: TextStyle(color: theme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        FutureBuilder<FuelPrices>(
          future: _prices,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Row(
                children: [
                  Expanded(
                    child: _FuelPriceCard(
                      title: 'PETROL',
                      value: 'Loadingâ€¦',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _FuelPriceCard(
                      title: 'DIESEL',
                      value: 'Loadingâ€¦',
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Column(
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
                  const SizedBox(height: 8),
                  Text(
                    'Could not load prices. Check your internet connection or API Mitra.',
                    style: TextStyle(color: theme.textMuted, fontSize: 11),
                  ),
                  TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try again'),
                  ),
                ],
              );
            }

            final prices = snapshot.data!;
            final updatedAt = prices.updatedAt;
            final updatedLabel = updatedAt == null
                ? 'Update time unavailable'
                : 'Updated ${updatedAt.toLocal().toString().substring(0, 16)}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FuelPriceCard(
                        title: 'PETROL',
                        value: 'â‚¹${prices.petrol.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FuelPriceCard(
                        title: 'DIESEL',
                        value: 'â‚¹${prices.diesel.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  updatedLabel,
                  style: TextStyle(color: theme.textMuted, fontSize: 10),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh prices'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openOfficialPrices,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Check IndianOil official prices'),
          ),
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
            value.startsWith('â‚¹') ? 'per litre' : 'Live lookup',
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
        'F U E L S E N S E   â€¢   SYSTEM READY',
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

