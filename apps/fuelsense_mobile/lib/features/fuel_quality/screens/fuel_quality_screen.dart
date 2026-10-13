import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/vehicle.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/phase_separation_assessment.dart';
import '../providers/phase_separation_provider.dart';

class FuelQualityScreen extends ConsumerStatefulWidget {
  const FuelQualityScreen({super.key});

  @override
  ConsumerState<FuelQualityScreen> createState() => _FuelQualityScreenState();
}

class _FuelQualityScreenState extends ConsumerState<FuelQualityScreen> {
  Vehicle? _selectedVehicle;

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

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
                child: vehiclesAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (error, _) => _ErrorCard(message: error.toString()),
                  data: (vehicles) {
                    if (vehicles.isEmpty) {
                      return const _EmptyCard();
                    }

                    final selected = _selectedVehicle;

                    if (selected == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedVehicle == null) {
                          _selectVehicle(vehicles.first);
                        }
                      });
                    }

                    final activeVehicle = selected ?? vehicles.first;

                    return _AssessmentSection(
                      vehicles: vehicles,
                      selectedVehicle: activeVehicle,
                      onVehicleChanged: _selectVehicle,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSection extends ConsumerStatefulWidget {
  const _AssessmentSection({
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle> onVehicleChanged;

  @override
  ConsumerState<_AssessmentSection> createState() => _AssessmentSectionState();
}

class _AssessmentSectionState extends ConsumerState<_AssessmentSection> {
  final _fuelAgeController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();

  bool _waterExposure = false;
  bool _sealedStorage = true;

  AsyncValue<PhaseSeparationAssessment>? _assessment;

  @override
  void dispose() {
    _fuelAgeController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  double? _parse(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  double? _ethanolPercent(String fuelType) {
    switch (fuelType) {
      case 'E10':
        return 10;
      case 'E20':
        return 20;
      case 'E85':
        return 85;
      default:
        return null;
    }
  }

  Future<void> _analyze() async {
    final vehicle = widget.selectedVehicle;
    final fuelType = vehicle.normalizedFuelType;

    if (fuelType.isEmpty || fuelType == 'UNKNOWN') {
      _showMessage('The selected vehicle does not have a verified fuel type.');
      return;
    }

    final fuelAge = _parse(_fuelAgeController.text);
    final temperature = double.tryParse(_temperatureController.text.trim());
    final humidity = _parse(_humidityController.text);

    if (_fuelAgeController.text.trim().isNotEmpty && fuelAge == null) {
      _showMessage('Enter a valid non-negative fuel age.');
      return;
    }

    if (_temperatureController.text.trim().isNotEmpty && temperature == null) {
      _showMessage('Enter a valid storage temperature.');
      return;
    }

    if (_humidityController.text.trim().isNotEmpty && humidity == null) {
      _showMessage('Enter a valid non-negative humidity value.');
      return;
    }

    setState(() {
      _assessment = const AsyncValue.loading();
    });

    try {
      final controller = ref.read(phaseSeparationControllerProvider);

      final result = await controller.analyze(
        vehicleDocumentId: vehicle.documentId,
        fuelType: fuelType,
        ethanolPercent: _ethanolPercent(fuelType),
        fuelAgeDays: fuelAge,
        storageTemperatureC: temperature,
        humidityPercent: humidity,
        waterExposure: _waterExposure,
        sealedStorage: _sealedStorage,
      );

      if (!mounted) return;

      setState(() {
        _assessment = AsyncValue.data(result);
      });
    } catch (error, stackTrace) {
      if (!mounted) return;

      setState(() {
        _assessment = AsyncValue.error(error, stackTrace);
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.selectedVehicle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VehicleSelector(
          vehicles: widget.vehicles,
          selectedVehicle: vehicle,
          onChanged: widget.onVehicleChanged,
        ),
        const SizedBox(height: 14),
        _InputCard(
          fuelType: vehicle.normalizedFuelType,
          fuelAgeController: _fuelAgeController,
          temperatureController: _temperatureController,
          humidityController: _humidityController,
          waterExposure: _waterExposure,
          sealedStorage: _sealedStorage,
          onWaterExposureChanged: (value) {
            setState(() => _waterExposure = value);
          },
          onSealedStorageChanged: (value) {
            setState(() => _sealedStorage = value);
          },
          onAnalyze: _analyze,
        ),
        if (_assessment != null) ...[
          const SizedBox(height: 16),
          _assessment!.when(
            loading: () => const _LoadingCard(),
            error: (error, _) => _ErrorCard(message: error.toString()),
            data: (result) => _AssessmentResultCard(assessment: result),
          ),
        ],
      ],
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
                'FUEL INSIGHTS',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: const Color(0xFF52E3D0),
                  fontSize: 8,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Fuel quality',
                style: AppTextStyles.displayMedium.copyWith(
                  color: const Color(0xFFE9F0F4),
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
  });

  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: DropdownButtonFormField<Vehicle>(
        initialValue: selectedVehicle,
        dropdownColor: const Color(0xFF101D27),
        style: const TextStyle(color: Color(0xFFE1E8EC), fontSize: 14),
        decoration: const InputDecoration(
          labelText: 'Vehicle',
          labelStyle: TextStyle(color: Color(0xFF718590)),
          border: InputBorder.none,
        ),
        items: vehicles
            .map(
              (vehicle) => DropdownMenuItem(
                value: vehicle,
                child: Text(vehicle.displayName),
              ),
            )
            .toList(),
        onChanged: (vehicle) {
          if (vehicle != null) {
            onChanged(vehicle);
          }
        },
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.fuelType,
    required this.fuelAgeController,
    required this.temperatureController,
    required this.humidityController,
    required this.waterExposure,
    required this.sealedStorage,
    required this.onWaterExposureChanged,
    required this.onSealedStorageChanged,
    required this.onAnalyze,
  });

  final String fuelType;
  final TextEditingController fuelAgeController;
  final TextEditingController temperatureController;
  final TextEditingController humidityController;
  final bool waterExposure;
  final bool sealedStorage;
  final ValueChanged<bool> onWaterExposureChanged;
  final ValueChanged<bool> onSealedStorageChanged;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SCREENING INPUTS',
            style: AppTextStyles.labelTechnical.copyWith(
              color: const Color(0xFF6F8490),
              fontSize: 8,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Fuel: $fuelType',
            style: const TextStyle(
              color: Color(0xFFE1E8EC),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _Field(
            controller: fuelAgeController,
            label: 'Fuel age (days)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          _Field(
            controller: temperatureController,
            label: 'Storage temperature (°C)',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 10),
          _Field(
            controller: humidityController,
            label: 'Humidity (%)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Possible water exposure',
              style: TextStyle(color: Color(0xFFD0DBE0)),
            ),
            value: waterExposure,
            onChanged: onWaterExposureChanged,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Storage tank sealed',
              style: TextStyle(color: Color(0xFFD0DBE0)),
            ),
            value: sealedStorage,
            onChanged: onSealedStorageChanged,
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Analyze phase separation risk'),
          ),
        ],
      ),
    );
  }
}

class _AssessmentResultCard extends StatelessWidget {
  const _AssessmentResultCard({required this.assessment});

  final PhaseSeparationAssessment assessment;

  Color _riskColor() {
    switch (assessment.riskLevel) {
      case 'CRITICAL':
        return const Color(0xFFFF6B6B);
      case 'HIGH':
        return const Color(0xFFFFA94D);
      case 'MEDIUM':
        return const Color(0xFFFFC857);
      case 'LOW':
        return const Color(0xFF52E3D0);
      default:
        return const Color(0xFF7DA7FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PHASE SEPARATION ASSESSMENT',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: const Color(0xFF6F8490),
                    fontSize: 8,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                assessment.riskLevel,
                style: AppTextStyles.labelTechnical.copyWith(
                  color: color,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (assessment.riskScore / 100).clamp(0, 1),
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFF243640),
                      color: color,
                    ),
                    Text(
                      assessment.riskScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  assessment.recommendation,
                  style: const TextStyle(
                    color: Color(0xFFD0DBE0),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Confidence ${(assessment.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Color(0xFF9DAAFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...assessment.contributingFactors.map(
            (factor) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${factor.label}: ${factor.detail}',
                      style: const TextStyle(
                        color: Color(0xFF9EADB5),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Source: ${assessment.dataSource}',
            style: const TextStyle(color: Color(0xFF60737E), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Text(
        message.replaceFirst('Exception: ', ''),
        style: const TextStyle(color: Color(0xFFFF8A8A), fontSize: 13),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Text(
        'No vehicles are available for a fuel-quality assessment.',
        style: TextStyle(color: Color(0xFFD0DBE0), fontSize: 13),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A23),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF21323D)),
      ),
      child: child,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFE1E8EC)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF718590)),
        filled: true,
        fillColor: const Color(0xFF101D27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF263743)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF263743)),
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
