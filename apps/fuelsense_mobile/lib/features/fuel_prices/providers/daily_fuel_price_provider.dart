import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_fuel_prices.dart';
import '../repositories/daily_fuel_price_repository.dart';

final dailyFuelPriceRepositoryProvider = Provider<DailyFuelPriceRepository>((
  ref,
) {
  final repository = DailyFuelPriceRepository();
  ref.onDispose(repository.close);
  return repository;
});

final dailyFuelPricesProvider = FutureProvider.family<DailyFuelPrices, String>((
  ref,
  city,
) {
  return ref.watch(dailyFuelPriceRepositoryProvider).fetchCityPrices(city);
});
