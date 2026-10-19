import 'dart:async';

import '../../fuel_prices/models/daily_fuel_prices.dart';
import '../../fuel_prices/repositories/daily_fuel_price_repository.dart';

class FuelPrices {
  const FuelPrices({
    required this.city,
    required this.petrol,
    required this.diesel,
    required this.updatedAt,
  });

  final String city;
  final double petrol;
  final double diesel;
  final DateTime? updatedAt;

  factory FuelPrices.fromDailyPrices(DailyFuelPrices prices) {
    return FuelPrices(
      city: prices.city,
      petrol: prices.petrol,
      diesel: prices.diesel,
      updatedAt: prices.updatedAt,
    );
  }
}

class FuelPriceService {
  FuelPriceService({DailyFuelPriceRepository? repository})
      : _repository = repository ?? DailyFuelPriceRepository();

  final DailyFuelPriceRepository _repository;

  Future<FuelPrices> fetchPrices(String city) async {
    final prices = await _repository.fetchCityPrices(city);
    return FuelPrices.fromDailyPrices(prices);
  }

  void close() => _repository.close();
}
