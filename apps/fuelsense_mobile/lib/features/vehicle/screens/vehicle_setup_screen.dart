import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../shared/models/vehicle_catalog.dart';
import '../../../shared/models/vehicle.dart';
import '../providers/vehicle_catalog_provider.dart';
import '../providers/vehicle_provider.dart';
import '../repositories/vehicle_repository.dart';

class VehicleSetupScreen extends ConsumerStatefulWidget {
  const VehicleSetupScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleSetupScreen> createState() => _VehicleSetupScreenState();
}

class _VehicleSetupScreenState extends ConsumerState<VehicleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _fuelController = TextEditingController();
  final _odometerController = TextEditingController();
  final _efficiencyController = TextEditingController();

  VehicleCatalog? _selected;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _nameController.text = vehicle.name;
      _regController.text = vehicle.registrationNumber;
      _fuelController.text = vehicle.currentFuelLevel.toString();
      _odometerController.text = vehicle.currentOdometer.toString();
      _efficiencyController.text = vehicle.currentMileage > 0
          ? vehicle.currentMileage.toString()
          : '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _regController,
      _fuelController,
      _odometerController,
      _efficiencyController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCatalog(List<VehicleCatalog> entries) async {
    final query = TextEditingController();
    final picked = await showModalBottomSheet<VehicleCatalog>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.text.trim().toLowerCase();
            final filtered = entries
                .where(
                  (e) =>
                      e.displayName.toLowerCase().contains(q) ||
                      e.fuelType.toLowerCase().contains(q),
                )
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.82,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SELECT VEHICLE',
                            style: AppTextStyles.labelTechnical,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: query,
                        autofocus: true,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search make, model or fuel',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    query.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No matching vehicles'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      side: BorderSide(color: AppColors.border),
                                    ),
                                    title: Text(item.displayName),
                                    subtitle: Text(
                                      '${item.fuelLabel} • ${item.compatibilityLabel}',
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => Navigator.pop(context, item),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    query.dispose();

    if (picked == null || !mounted) return;
    setState(() {
      _selected = picked;
      _nameController.text = '${picked.make} ${picked.model}'.trim();
      if (picked.tankCapacity != null) {
        _fuelController.clear();
      }
      _efficiencyController.text =
          picked.claimedMileage?.toStringAsFixed(1) ?? '';
    });
  }

  Future<void> _submit() async {
    final existing = widget.vehicle;
    final selected = _selected;

    if (existing == null && selected == null) {
      setState(
        () => _error = 'Select your exact vehicle from the verified catalog.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final fuel = double.tryParse(_fuelController.text.trim()) ?? 0;
      final odo = double.tryParse(_odometerController.text.trim()) ?? 0;
      final mileage =
          double.tryParse(_efficiencyController.text.trim()) ??
          existing?.currentMileage ??
          selected?.claimedMileage ??
          0;

      final capacity = selected?.tankCapacity ?? existing?.tankCapacity;
      if (capacity != null && capacity > 0 && fuel > capacity) {
        throw Exception(
          'Current fuel cannot exceed the tank capacity of '
          '${capacity.toStringAsFixed(0)} L.',
        );
      }

      if (existing != null) {
        final documentId = existing.documentId;
        if (documentId == null || documentId.isEmpty) {
          throw Exception(
            'This vehicle has no saved document ID. Refresh the Garage and try again.',
          );
        }

        await VehicleRepository.instance.updateVehicle(
          vehicleDocumentId: documentId,
          name: _nameController.text.trim(),
          registrationNumber: _regController.text.trim(),
          fuelType: selected?.fuelType ?? existing.fuelType,
          tankCapacity: selected == null
              ? existing.tankCapacity
              : selected.tankCapacity,
          catalogId: selected?.id ?? existing.catalogId,
          make: selected?.make ?? existing.make,
          model: selected?.model ?? existing.model,
          variant: selected?.variant ?? existing.variant,
          modelYear: selected?.modelYear ?? existing.modelYear,
          e20Compatible: selected?.e20Compatible ?? existing.e20Compatible,
          e85Compatible: selected?.e85Compatible ?? existing.e85Compatible,
          replaceCatalog: selected != null,
          claimedMileage: selected?.claimedMileage,
          recommendedFuel: selected?.recommendedFuel,
          sourceName: selected?.sourceName,
          sourceUrl: selected?.sourceUrl,
          verifiedAt: selected?.verifiedAt,
          engineDisplacement: selected?.engineDisplacement,
          horsepower: selected?.horsepower,
          torque: selected?.torque,
          transmission: selected?.transmission,
          drivetrain: selected?.drivetrain,
          market: selected?.market,
          country: selected?.country,
          currentMileage: mileage,
          currentOdometer: odo,
          currentFuel: fuel,
        );
      } else {
        await VehicleRepository.instance.createVehicle(
          catalogId: selected!.id,
          name: _nameController.text.trim(),
          registrationNumber: _regController.text.trim(),
          fuelType: selected.fuelType,
          tankCapacity: selected.tankCapacity,
          claimedMileage: mileage,
          make: selected.make,
          model: selected.model,
          variant: selected.variant,
          modelYear: selected.modelYear,
          recommendedFuel: selected.recommendedFuel,
          e20Compatible: selected.e20Compatible,
          e85Compatible: selected.e85Compatible,
          sourceName: selected.sourceName,
          sourceUrl: selected.sourceUrl,
          verifiedAt: selected.verifiedAt,
          currentFuel: fuel,
          currentOdometer: odo,
        );
      }

      ref.invalidate(vehicleProvider);
      if (!mounted) return;

      // Return to Garage so the updated provider data is displayed.
      context.go('/garage');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _number(String? value, {double? max}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null || n < 0) return 'Enter a valid number';
    if (max != null && n > max) return 'Maximum is ${max.toStringAsFixed(0)}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(vehicleCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(vehicleCatalogProvider),
              ),
              data: (entries) => _buildForm(entries),
            ),
          ),
        ],
      ),
    );
  }

  VehicleCatalog? _matchingCatalog(List<VehicleCatalog> entries) {
    final vehicle = widget.vehicle;
    if (vehicle == null) return null;

    // Prefer the stable catalog ID when it matches.
    for (final entry in entries) {
      if (vehicle.catalogId != null && entry.id == vehicle.catalogId) {
        return entry;
      }
    }

    // Fall back to the saved vehicle identity.
    final make = (vehicle.make ?? '').trim().toLowerCase();
    final model = (vehicle.model ?? '').trim().toLowerCase();
    final variant = (vehicle.variant ?? '').trim().toLowerCase();
    final fuel = vehicle.fuelType.trim().toLowerCase();

    if (make.isEmpty || model.isEmpty) return null;

    for (final entry in entries) {
      if (entry.make.trim().toLowerCase() == make &&
          entry.model.trim().toLowerCase() == model &&
          (entry.variant ?? '').trim().toLowerCase() == variant &&
          entry.fuelType.trim().toLowerCase() == fuel) {
        return entry;
      }
    }

    return null;
  }

  Widget _buildForm(List<VehicleCatalog> entries) {
    if (_selected == null && _isEditing) {
      _selected = _matchingCatalog(entries);
    }
    final selected = _selected;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                ),
                const Spacer(),
                Text(
                  _isEditing ? 'EDIT VEHICLE' : 'VEHICLE SETUP',
                  style: AppTextStyles.labelTechnical,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Update your vehicle' : 'Connect your vehicle',
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 7),
            Text(
              _isEditing
                  ? 'Update your saved details. Select a catalog entry only if you need to change the vehicle model.'
                  : 'Choose the exact catalog entry first. FuelSense uses verified vehicle specifications instead of guessed values.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 24),
            _label(
              _isEditing ? 'VEHICLE CATALOG (OPTIONAL)' : 'VEHICLE CATALOG',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickCatalog(entries),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: selected == null
                        ? AppColors.border
                        : AppColors.primaryCyan,
                  ),
                ),
                child: selected == null
                    ? const Row(
                        children: [
                          Icon(Icons.search_rounded),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Select make, model and variant'),
                          ),
                          Icon(Icons.chevron_right_rounded),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.displayName,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${selected.fuelLabel} • ${selected.compatibilityLabel}',
                            style: AppTextStyles.bodySecondary,
                          ),
                          if (selected.tankCapacity != null ||
                              selected.claimedMileage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                [
                                  if (selected.tankCapacity != null)
                                    '${selected.tankCapacity!.toStringAsFixed(0)} L tank',
                                  if (selected.claimedMileage != null)
                                    '${selected.claimedMileage!.toStringAsFixed(1)} km/L',
                                ].join(' • '),
                                style: AppTextStyles.labelTechnical.copyWith(
                                  color: AppColors.primaryCyan,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _label('VEHICLE NICKNAME'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _decoration(
                'e.g. My Creta',
                Icons.directions_car_outlined,
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            _label('REGISTRATION NUMBER'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regController,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration(
                'e.g. TN 45 AB 1234',
                Icons.badge_outlined,
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            _label('CURRENT ODOMETER'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _odometerController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                'Current odometer reading',
                Icons.speed_rounded,
                suffix: 'km',
              ),
              validator: _number,
            ),
            ...[
              const SizedBox(height: 16),
              _label('CURRENT FUEL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fuelController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(
                  selected?.tankCapacity == null
                      ? 'Fuel in tank'
                      : 'Fuel in tank',
                  Icons.local_gas_station_outlined,
                  suffix: 'L',
                ),
                validator: (v) {
                  final result = _number(v);
                  if (result != null) return result;
                  final n = double.parse(v!.trim());
                  final cap = selected?.tankCapacity;
                  return cap != null && n > cap
                      ? 'Cannot exceed ${cap.toStringAsFixed(0)} L tank capacity'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _label('REFERENCE MILEAGE'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _efficiencyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                'Catalog reference',
                Icons.analytics_outlined,
                suffix: 'km/L',
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) _ErrorBanner(message: _error!),
            if (_error != null) const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'SAVE CHANGES' : 'ADD VEHICLE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.labelTechnical);

  InputDecoration _decoration(String hint, IconData icon, {String? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        suffixText: suffix,
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          const Text('Unable to load vehicle catalog'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
    ),
    child: Text(message, style: AppTextStyles.bodySecondary),
  );
}
