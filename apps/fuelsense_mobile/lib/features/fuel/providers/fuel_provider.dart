import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/fuel_repository.dart';

final fuelRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository();
});

final fuelRecordNotifierProvider =
    NotifierProvider<FuelRecordNotifier, AsyncValue<void>>(
      FuelRecordNotifier.new,
    );

class FuelRecordNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> submitFuelRecord(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(fuelRepositoryProvider);

      final success = await repository.addFuelRecord(data);

      if (success) {
        state = const AsyncData(null);

      } else {
        state = AsyncError('Failed to submit fuel record', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
