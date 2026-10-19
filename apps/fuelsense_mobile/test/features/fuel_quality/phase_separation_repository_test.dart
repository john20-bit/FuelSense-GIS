import 'package:flutter_test/flutter_test.dart';
import 'package:fuelsense_mobile/features/fuel_quality/repositories/phase_separation_repository.dart';

void main() {
  final repository = PhaseSeparationRepository.instance;

  group('Phase separation screening', () {
    test('returns LOW for supplied low-risk conditions', () async {
      final result = await repository.analyze(
        fuelType: 'E10',
        ethanolPercent: 10,
        fuelAgeDays: 10,
        storageTemperatureC: 20,
        humidityPercent: 40,
        sealedStorage: true,
      );

      expect(result.riskLevel, 'LOW');
      expect(result.riskScore, 10);
    });

    test(
      'returns MODERATE for E20 without additional risk factors',
      () async {
        final result = await repository.analyze(
          fuelType: 'E20',
          ethanolPercent: 20,
          sealedStorage: false,
        );

        expect(result.riskLevel, 'MODERATE');
        expect(result.riskScore, 35.0);
      },
    );

    test('rejects humidity above 100', () async {
      await expectLater(
        repository.analyze(fuelType: 'E10', humidityPercent: 101),
        throwsArgumentError,
      );
    });

    test('rejects negative fuel age', () async {
      await expectLater(
        repository.analyze(fuelType: 'E10', fuelAgeDays: -1),
        throwsArgumentError,
      );
    });

    test('rejects non-finite temperature', () async {
      await expectLater(
        repository.analyze(fuelType: 'E10', storageTemperatureC: double.nan),
        throwsArgumentError,
      );
    });

    test('rejects unknown fuel type', () async {
      await expectLater(
        repository.analyze(fuelType: 'UNKNOWN'),
        throwsArgumentError,
      );
    });
  });
}
