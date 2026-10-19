import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/vehicle.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/phase_separation_assessment.dart';
import '../providers/phase_separation_provider.dart';
import '../../telemetry/screens/telemetry_screen.dart';
import '../widgets/phase_separation_weather_card.dart';

const _black = Color(0xFF050708);
const _panel = Color(0xFF0D1214);
const _panelRaised = Color(0xFF121A1D);
const _cyan = Color(0xFF39E6F2);
const _green = Color(0xFF9BFF65);
const _text = Color(0xFFEAF2F3);
const _muted = Color(0xFF89999D);
const _border = Color(0xFF263438);
const _red = Color(0xFFFF6B78);
const _amber = Color(0xFFFFC857);

class FuelQualityScreen extends ConsumerStatefulWidget {
  const FuelQualityScreen({super.key});

  @override
  ConsumerState<FuelQualityScreen> createState() =>
      _FuelQualityScreenState();
}

class _FuelQualityScreenState extends ConsumerState<FuelQualityScreen> {
  Vehicle? _selectedVehicle;
  int _selectedModule = 0;

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              sliver: SliverToBoxAdapter(
                child: _Header(onBack: () => context.pop()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              sliver: SliverToBoxAdapter(
                child: _ModuleSwitcher(
                  selectedIndex: _selectedModule,
                  onChanged: (index) {
                    setState(() => _selectedModule = index);
                  },
                ),
              ),
            ),
            if (_selectedModule == 1)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: TelemetryScreen(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                sliver: SliverToBoxAdapter(
                  child: vehiclesAsync.when(
                    loading: () => const _LoadingCard(),
                    error: (error, _) => _ErrorCard(
                      message: error.toString(),
                    ),
                    data: (vehicles) {
                      if (vehicles.isEmpty) {
                        return const _EmptyCard();
                      }

                      final selected = _selectedVehicle;
                      final vehicleExists = selected != null &&
                          vehicles.any(
                            (vehicle) =>
                                vehicle.documentId == selected.documentId,
                          );

                      final activeVehicle =
                          vehicleExists ? selected : vehicles.first;

                      if (!vehicleExists) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              _selectedVehicle?.documentId !=
                                  activeVehicle.documentId) {
                            _selectVehicle(activeVehicle);
                          }
                        });
                      }

                      return _AssessmentSection(
                        key: ValueKey(activeVehicle.documentId),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUELSENSE GIS  /  MONITORING',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: _cyan,
                  fontSize: 9,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Phase separation',
                style: TextStyle(
                  color: _text,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Environmental risk screening',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _panelRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: const Icon(
            Icons.water_drop_outlined,
            color: _cyan,
            size: 21,
          ),
        ),
      ],
    );
  }
}

class _ModuleSwitcher extends StatelessWidget {
  const _ModuleSwitcher({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Phase separation', 'Telemetry'];
    const icons = [
      Icons.water_drop_outlined,
      Icons.sensors_outlined,
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _cyan.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? _cyan.withValues(alpha: 0.32)
                        : Colors.transparent,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _cyan.withValues(alpha: 0.045),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: selected ? _cyan : _muted,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? _cyan : _muted,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AssessmentSection extends ConsumerStatefulWidget {
  const _AssessmentSection({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle> onVehicleChanged;

  @override
  ConsumerState<_AssessmentSection> createState() =>
      _AssessmentSectionState();
}

class _AssessmentSectionState
    extends ConsumerState<_AssessmentSection> {
  final _fuelAgeController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  String? _lastAutoTemperature;
  String? _lastAutoHumidity;

  late String _selectedBaseFuel;
  String _selectedBlend = 'E10';
  bool _sealedStorage = true;

  AsyncValue<PhaseSeparationAssessment>? _assessment;
  PhaseSeparationWeather? _weather;

  @override
  void initState() {
    super.initState();
    _selectedBaseFuel = _baseFuelForVehicle(
      widget.selectedVehicle.normalizedFuelType,
    );
    _updateBlendForFuel();
  }

  String _baseFuelForVehicle(String? fuelType) {
    final normalized = (fuelType ?? '').trim().toUpperCase();

    if (normalized.contains('DIESEL')) {
      return 'DIESEL';
    }

    return 'PETROL';
  }

  void _updateBlendForFuel() {
    if (_selectedBaseFuel == 'DIESEL') {
      _selectedBlend = 'NONE';
    } else if (_selectedBlend == 'NONE') {
      _selectedBlend = 'E10';
    }
  }

  @override
  void didUpdateWidget(covariant _AssessmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedVehicle.documentId !=
        widget.selectedVehicle.documentId) {
      _selectedBaseFuel = _baseFuelForVehicle(
        widget.selectedVehicle.normalizedFuelType,
      );
      _updateBlendForFuel();

      _fuelAgeController.clear();
      _temperatureController.clear();
      _humidityController.clear();

      _weather = null;
      _assessment = null;
      _sealedStorage = true;
    }
  }

  @override
  void dispose() {
    _fuelAgeController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  double? _parseNonNegative(String value) {
    final parsed = double.tryParse(value.trim());

    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return null;
    }

    return parsed;
  }

  Future<void> _analyze() async {
    final vehicle = widget.selectedVehicle;
    final fuelType = _selectedBaseFuel;

    final ethanolPercent = switch (_selectedBlend) {
      'E10' => 10.0,
      'E20' => 20.0,
      'E85' => 85.0,
      _ => 0.0,
    };

    if (fuelType != 'PETROL' && fuelType != 'DIESEL') {
      _showMessage('Select a valid fuel type.');
      return;
    }

    if (fuelType == 'DIESEL' && ethanolPercent > 0) {
      _showMessage('Ethanol blends cannot be selected for this diesel assessment.');
      return;
    }

    if (_selectedBlend == 'E20' && vehicle.e20Compatible != true) {
      _showMessage('E20 compatibility is not confirmed for this vehicle.');
      return;
    }

    if (_selectedBlend == 'E85' && vehicle.e85Compatible != true) {
      _showMessage('E85 compatibility is not confirmed for this vehicle.');
      return;
    }

    final fuelAgeText = _fuelAgeController.text.trim();
    final temperatureText = _temperatureController.text.trim();
    final humidityText = _humidityController.text.trim();

    final fuelAge = _parseNonNegative(fuelAgeText);

    final manualTemperature = temperatureText.isEmpty
        ? null
        : double.tryParse(temperatureText);

    final manualHumidity = humidityText.isEmpty
        ? null
        : _parseNonNegative(humidityText);

    if (fuelAgeText.isNotEmpty &&
        (fuelAge == null || fuelAge > 3650)) {
      _showMessage('Enter a valid fuel age between 0 and 3650 days.');
      return;
    }

    if (temperatureText.isNotEmpty &&
        (manualTemperature == null ||
            !manualTemperature.isFinite ||
            manualTemperature < -50 ||
            manualTemperature > 100)) {
      _showMessage('Enter a temperature between -50 and 100 Â°C.');
      return;
    }

    if (humidityText.isNotEmpty &&
        (manualHumidity == null || manualHumidity > 100)) {
      _showMessage('Enter humidity between 0 and 100%.');
      return;
    }

    // Manual values take priority. Current local weather is used only
    // when the corresponding manual field is empty.
    final temperature =
        temperatureText.isNotEmpty
            ? manualTemperature
            : _weather?.temperatureC;

    final humidity =
        humidityText.isNotEmpty
            ? manualHumidity
            : _weather?.humidityPercent;

    setState(() {
      _assessment = const AsyncValue.loading();
    });

    try {
      final controller = ref.read(
        phaseSeparationControllerProvider,
      );

      final result = await controller.analyze(
        vehicleDocumentId: vehicle.documentId,
        fuelType: fuelType,
        ethanolPercent: ethanolPercent,
        fuelAgeDays: fuelAge,
        storageTemperatureC: temperature,
        humidityPercent: humidity,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

        PhaseSeparationWeatherCard(
          onWeatherChanged: (weather) {
            if (!mounted || weather == null) return;

            final temperature = weather.temperatureC.toStringAsFixed(1);
            final humidity = weather.humidityPercent.toStringAsFixed(0);

            setState(() {
              _weather = weather;
        _assessment = null;

              final currentTemperature = _temperatureController.text.trim();
        if (currentTemperature.isEmpty ||
            currentTemperature == _lastAutoTemperature) {
          _temperatureController.text = temperature;
          _lastAutoTemperature = temperature;
        }

              final currentHumidity = _humidityController.text.trim();
        if (currentHumidity.isEmpty ||
            currentHumidity == _lastAutoHumidity) {
          _humidityController.text = humidity;
          _lastAutoHumidity = humidity;
        }
            });
          },
        ),

        const SizedBox(height: 14),
        _InputCard(
          selectedBaseFuel: _selectedBaseFuel,
          selectedBlend: _selectedBlend,
          e20Compatible: vehicle.e20Compatible,
          e85Compatible: vehicle.e85Compatible,
          onFuelChanged: (value) {
            setState(() {
              _selectedBaseFuel = value;
              _updateBlendForFuel();
              _assessment = null;
            });
          },
          onBlendChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedBlend = value;
              _assessment = null;
            });
          },
          fuelAgeController: _fuelAgeController,
          temperatureController: _temperatureController,
          humidityController: _humidityController,
          sealedStorage: _sealedStorage,
          onSealedStorageChanged: (value) {
            setState(() {
              _sealedStorage = value;
              _assessment = null;
            });
          },
          onAnalyze: _analyze,
        ),

        if (_assessment != null) ...[
          const SizedBox(height: 14),
          _assessment!.when(
            loading: () => const _LoadingCard(),
            error: (error, _) => _ErrorCard(
              message: error.toString(),
            ),
            data: (result) => _AssessmentResultCard(
              assessment: result,
            ),
          ),
        ],

        const SizedBox(height: 12),
        const _Disclaimer(),
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
      eyebrow: 'ACTIVE VEHICLE',
      icon: Icons.directions_car_outlined,
      child: DropdownButtonFormField<Vehicle>(
        key: ValueKey(selectedVehicle.documentId),
        initialValue: selectedVehicle,
        dropdownColor: _panelRaised,
        iconEnabledColor: _cyan,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          labelText: 'Select vehicle',
          labelStyle: TextStyle(color: _muted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        items: vehicles.map((vehicle) {
          return DropdownMenuItem<Vehicle>(
            value: vehicle,
            child: Text(
              vehicle.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (vehicle) {
          if (vehicle != null) onChanged(vehicle);
        },
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.selectedBaseFuel,
    required this.selectedBlend,
    required this.e20Compatible,
    required this.e85Compatible,
    required this.onFuelChanged,
    required this.onBlendChanged,
    required this.fuelAgeController,
    required this.temperatureController,
    required this.humidityController,
    required this.sealedStorage,
    required this.onSealedStorageChanged,
    required this.onAnalyze,
  });

  final String selectedBaseFuel;
  final String selectedBlend;
  final bool? e20Compatible;
  final bool? e85Compatible;
  final ValueChanged<String> onFuelChanged;
  final ValueChanged<String?> onBlendChanged;
  final TextEditingController fuelAgeController;
  final TextEditingController temperatureController;
  final TextEditingController humidityController;
  final bool sealedStorage;
  final ValueChanged<bool> onSealedStorageChanged;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return _Card(
      eyebrow: 'ASSESSMENT PARAMETERS',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('FUEL CONFIGURATION'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('base-$selectedBaseFuel'),
            initialValue: selectedBaseFuel,
            dropdownColor: _panelRaised,
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Fuel type',
              labelStyle: TextStyle(color: _muted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _cyan),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'PETROL',
                child: Text('Petrol'),
              ),
              DropdownMenuItem(
                value: 'DIESEL',
                child: Text('Diesel'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onFuelChanged(value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('blend-$selectedBlend-$selectedBaseFuel'),
            initialValue: selectedBlend,
            dropdownColor: _panelRaised,
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Ethanol blend',
              labelStyle: TextStyle(color: _muted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _cyan),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: 'NONE',
                child: Text('No ethanol blend'),
              ),
              const DropdownMenuItem(
                value: 'E10',
                child: Text('E10 â€¢ 10%'),
              ),
              DropdownMenuItem(
                value: 'E20',
                enabled: e20Compatible == true,
                child: Text(
                  e20Compatible == true
                      ? 'E20 â€¢ 20%'
                      : 'E20 â€¢ compatibility unconfirmed',
                ),
              ),
              DropdownMenuItem(
                value: 'E85',
                enabled: e85Compatible == true,
                child: Text(
                  e85Compatible == true
                      ? 'E85 â€¢ 85%'
                      : 'E85 â€¢ compatibility unconfirmed',
                ),
              ),
            ],
            onChanged: selectedBaseFuel == 'DIESEL'
                ? null
                : onBlendChanged,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('STORAGE CONDITIONS'),
          const SizedBox(height: 12),
          _Field(
            controller: fuelAgeController,
            label: 'Fuel age',
            suffix: 'days',
            icon: Icons.schedule_rounded,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 11),
          _Field(
            controller: temperatureController,
            label: 'Storage temperature',
            suffix: 'Â°C',
            icon: Icons.thermostat_rounded,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Leave blank to use local ambient temperature when available.',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 11),
          _Field(
            controller: humidityController,
            label: 'Relative humidity',
            suffix: '%',
            icon: Icons.water_drop_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 5),
          const Text(
            'Leave blank to use local weather humidity when available.',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: _border, height: 20),
          _ToggleRow(
            icon: Icons.lock_outline_rounded,
            title: 'Storage tank sealed',
            subtitle: 'Tank is assumed to be properly sealed',
            value: sealedStorage,
            onChanged: onSealedStorageChanged,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.08),
                    blurRadius: 18,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.radar_rounded, size: 20),
                label: const Text(
                  'Analyze risk',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Leave a field empty when its value is unknown.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _panelRaised,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _border),
          ),
          child: Icon(
            icon,
            color: value ? _green : _muted,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: _green.withValues(alpha: 0.45),
          activeThumbColor: _green,
          inactiveTrackColor: _panelRaised,
          inactiveThumbColor: _muted,
        ),
      ],
    );
  }
}

class _AssessmentResultCard extends StatelessWidget {
  const _AssessmentResultCard({required this.assessment});

  final PhaseSeparationAssessment assessment;

  Color _riskColor() {
    switch (assessment.riskLevel.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return _red;
      case 'MODERATE':
        return _amber;
      case 'LOW':
        return _green;
      default:
        return _cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();
    final score = (assessment.riskScore / 100).clamp(0.0, 1.0);

    return _Card(
      eyebrow: 'SCREENING RESULTS',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Risk assessment',
                  style: TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  assessment.riskLevel,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 106,
                height: 106,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 25,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        value: score,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _border,
                        color: color,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          assessment.riskScore.toStringAsFixed(0),
                          style: TextStyle(
                            color: color,
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECOMMENDATION',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment.recommendation,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _panelRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _cyan,
                  size: 17,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This is a rule-based screening score, not a '
                    'probability. It cannot confirm actual fuel '
                    'phase separation.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (assessment.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel('CONTRIBUTING FACTORS'),
            const SizedBox(height: 12),
            ...assessment.contributingFactors.map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            factor.label,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            factor.detail,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            'Source: ${assessment.dataSource}',
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_outlined,
            color: _muted,
            size: 15,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Environmental readings indicate screening conditions only. '
              'Ambient weather is not a direct measurement of tank conditions. '
              'Inspect or test the fuel to confirm contamination.',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _cyan,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.25,
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
          padding: EdgeInsets.all(22),
          child: CircularProgressIndicator(
            color: _cyan,
            strokeWidth: 2.5,
          ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _red,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message.replaceFirst('Exception: ', ''),
              style: const TextStyle(
                color: _red,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      icon: Icons.directions_car_outlined,
      eyebrow: 'NO VEHICLES',
      child: Text(
        'Add a vehicle to begin a phase-separation screening.',
        style: TextStyle(
          color: _muted,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.eyebrow,
    this.icon,
  });

  final Widget child;
  final String? eyebrow;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: _cyan, size: 15),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    eyebrow!,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.15,
                    ),
                  ),
                ),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.icon,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final IconData icon;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _cyan,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: _cyan,
          size: 19,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: _muted,
          fontSize: 11,
        ),
        filled: true,
        fillColor: _panelRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: _cyan,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Icon(
            icon,
            color: _text,
            size: 19,
          ),
        ),
      ),
    );
  }
}
