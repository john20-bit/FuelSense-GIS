import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';

enum FuelHistoryFilter { all, fuel }

class EnergyHistoryScreen extends StatefulWidget {
  const EnergyHistoryScreen({super.key});

  @override
  State<EnergyHistoryScreen> createState() => _EnergyHistoryScreenState();
}

class _EnergyHistoryScreenState extends State<EnergyHistoryScreen> {
  FuelHistoryFilter _filter = FuelHistoryFilter.all;

  static const _records = <_HistoryRecord>[
    _HistoryRecord(
      type: _HistoryType.petrol,
      title: 'Petrol',
      station: 'Indian Oil',
      amount: '32.4 L',
      cost: '₹3,280',
      date: 'Today',
      time: '8:42 AM',
      accent: Color(0xFFFFC857),
    ),

    _HistoryRecord(
      type: _HistoryType.diesel,
      title: 'Diesel',
      station: 'HP',
      amount: '24.8 L',
      cost: '₹2,310',
      date: 'Aug 21',
      time: '6:03 PM',
      accent: Color(0xFFB8A7FF),
    ),
    _HistoryRecord(
      type: _HistoryType.petrol,
      title: 'Premium Petrol',
      station: 'Bharat Petroleum',
      amount: '28.6 L',
      cost: '₹3,120',
      date: 'Aug 18',
      time: '9:24 AM',
      accent: Color(0xFFFFC857),
    ),
  ];

  List<_HistoryRecord> get _filteredRecords {
    switch (_filter) {
      case FuelHistoryFilter.all:
        return _records;
      case FuelHistoryFilter.fuel:
        return _records;
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              sliver: SliverToBoxAdapter(
                child: _Header(onBack: () => context.pop()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _SummaryCard(records: _records),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
              sliver: SliverToBoxAdapter(
                child: _FilterBar(
                  selected: _filter,
                  onChanged: (value) {
                    setState(() {
                      _filter = value;
                    });
                  },
                ),
              ),
            ),
            if (records.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                sliver: SliverList.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _HistoryCard(record: records[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVITY',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: const Color(0xFF52E3D0),
                  fontSize: 8,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Fuel & energy history',
                style: AppTextStyles.displayMedium.copyWith(
                  color: const Color(0xFFE9F0F4),
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.records});

  final List<_HistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132B36), Color(0xFF0D1C25)],
        ),
        border: Border.all(color: const Color(0xFF2B4C54)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'THIS MONTH',
              value: '₹9,037',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF52E3D0),
            ),
          ),
          _Divider(),
          Expanded(
            child: _SummaryMetric(
              label: 'ACTIVITIES',
              value: '${records.length}',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF7DA7FF),
            ),
          ),
          _Divider(),
          Expanded(
            child: _SummaryMetric(
              label: 'AVERAGE',
              value: '₹2.3K',
              icon: Icons.insights_rounded,
              color: const Color(0xFFB8A7FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelTechnical.copyWith(
            color: const Color(0xFF687C87),
            fontSize: 6.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.dataValue.copyWith(color: color, fontSize: 19),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final FuelHistoryFilter selected;
  final ValueChanged<FuelHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterChip(
            label: 'ALL',
            selected: selected == FuelHistoryFilter.all,
            onTap: () => onChanged(FuelHistoryFilter.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterChip(
            label: 'FUEL',
            selected: selected == FuelHistoryFilter.fuel,
            onTap: () => onChanged(FuelHistoryFilter.fuel),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF52E3D0).withValues(alpha: 0.11)
              : const Color(0xFF0E1A23),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? const Color(0xFF52E3D0).withValues(alpha: 0.35)
                : const Color(0xFF243640),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelTechnical.copyWith(
            color: selected ? const Color(0xFF52E3D0) : const Color(0xFF93A3AC),
            fontSize: 7,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final _HistoryRecord record;

  IconData get _icon {
    switch (record.type) {
      case _HistoryType.petrol:
      case _HistoryType.diesel:
        return Icons.local_gas_station_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A23),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF21323D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: record.accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_icon, color: record.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFFE2E9ED),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.station,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF718590),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${record.date} • ${record.time}',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: const Color(0xFF637783),
                    fontSize: 6.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.cost,
                style: AppTextStyles.dataValue.copyWith(
                  color: record.accent,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.amount,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF7D909B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF607580),
              size: 48,
            ),
            SizedBox(height: 14),
            Text(
              'NO ACTIVITY YET',
              style: TextStyle(
                color: Color(0xFFD5DEE3),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your fuel activity will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF718590), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFF101D27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF263743)),
        ),
        child: Icon(icon, color: const Color(0xFFC8D2D9), size: 19),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFF263943));
  }
}

enum _HistoryType { petrol, diesel }

class _HistoryRecord {
  const _HistoryRecord({
    required this.type,
    required this.title,
    required this.station,
    required this.amount,
    required this.cost,
    required this.date,
    required this.time,
    required this.accent,
  });

  final _HistoryType type;
  final String title;
  final String station;
  final String amount;
  final String cost;
  final String date;
  final String time;
  final Color accent;
}
