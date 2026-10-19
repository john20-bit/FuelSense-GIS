import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../shared/models/vehicle_catalog.dart';
import '../../../shared/models/vehicle.dart';
import '../providers/vehicle_catalog_provider.dart';
import '../providers/vehicle_provider.dart';
import '../repositories/vehicle_repository.dart';
import '../services/vehicle_registration_service.dart';

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
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _fuelController = TextEditingController();
  final _odometerController = TextEditingController();
  final _efficiencyController = TextEditingController();

  VehicleCatalog? _selected;
  bool _submitting = false;
  bool _lookingUpRegistration = false;
  bool _lookupFailed = false;
  bool _manualEntry = false;
  XFile? _vehicleImage;
  PlatformFile? _registrationCertificate;
  final _imagePicker = ImagePicker();
  VehicleRegistrationDetails? _registrationDetails;
  final _registrationService = VehicleRegistrationService();
  String? _error;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _nameController.text = vehicle.name;
      _regController.text = vehicle.registrationNumber;
      _makeController.text = vehicle.make ?? '';
      _modelController.text = vehicle.model ?? '';
      _fuelTypeController.text = vehicle.fuelType;
      _manualEntry = vehicle.isManuallyEntered || vehicle.catalogId == null;
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
      _makeController,
      _modelController,
      _fuelTypeController,
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
    VehicleCatalog? picked;

    try {
      picked = await showModalBottomSheet<VehicleCatalog>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
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
                  height: MediaQuery.sizeOf(sheetContext).height * 0.82,
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
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(),
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
                              ? const Center(
                                  child: Text('No matching vehicles'),
                                )
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
                                        side: BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      title: Text(item.displayName),
                                      subtitle: Text(
                                        '${item.fuelLabel} • ${item.compatibilityLabel}',
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onTap: () =>
                                          Navigator.of(sheetContext).pop(item),
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
    } finally {
      // Allow the modal route and its TextField to finish disposing.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      query.dispose();
    }

    if (picked == null || !mounted) return;

    setState(() {
      _selected = picked;
      _nameController.text = '${picked!.make} ${picked.model}'.trim();

      if (picked!.tankCapacity != null) {
        _fuelController.clear();
      }

      _efficiencyController.text =
          picked!.claimedMileage?.toStringAsFixed(1) ?? '';
    });
  }

  Future<void> _pickVehicleImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image != null && mounted) {
        setState(() {
          _vehicleImage = image;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to select the vehicle image.');
      }
    }
  }

  Future<void> _pickRegistrationCertificate() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (files.isNotEmpty && mounted) {
        final file = files.first;

        final filePath = file.path;
        if (filePath == null || filePath.isEmpty) {
          setState(() {
            _error = 'Could not access the selected certificate file.';
          });
          return;
        }

        final byteLength = await File(filePath).length();
        if (byteLength > 10 * 1024 * 1024) {
          setState(() {
            _error = 'The registration certificate must be 10 MB or smaller.';
          });
          return;
        }

        setState(() {
          _registrationCertificate = file;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to select the registration certificate.';
        });
      }
    }
  }

  void _useManualEntry() {
    setState(() {
      _manualEntry = true;
      _registrationDetails = null;
      _selected = null;
      _error = null;
    });
  }

  Future<void> _lookupRegistration() async {
    final registration = _regController.text.trim();
    if (registration.isEmpty) {
      setState(() => _error = 'Enter your registration number first.');
      return;
    }

    setState(() {
      _lookingUpRegistration = true;
      _error = null;
    });

    try {
      final details = await _registrationService.lookup(registration);
      if (!mounted) return;

      setState(() {
        _registrationDetails = details;
        _lookupFailed = false;
        _regController.text = details.registrationNumber;
        final identity = [
          details.make,
          details.model,
          details.variant,
        ].where((part) => part.trim().isNotEmpty).join(' ');
        if (identity.isNotEmpty) {
          _nameController.text = identity;
        }
        if (details.make.trim().isNotEmpty) {
          _makeController.text = details.make;
        }
        if (details.model.trim().isNotEmpty) {
          _modelController.text = details.model;
        }
        if (details.fuelType.trim().isNotEmpty) {
          _fuelTypeController.text = details.fuelType;
        }
        _selected = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _registrationDetails = null;
        _lookupFailed = true;
        _error =
            'Registration lookup failed. Try again or enter details manually.';
      });
    } finally {
      if (mounted) {
        setState(() => _lookingUpRegistration = false);
      }
    }
  }

  Future<void> _submit() async {
    final existing = widget.vehicle;
    final selected = _selected;
    final manual = _manualEntry || selected == null;

    if (manual &&
        (_makeController.text.trim().isEmpty ||
            _modelController.text.trim().isEmpty ||
            _fuelTypeController.text.trim().isEmpty)) {
      setState(() {
        _manualEntry = true;
        _error = 'Enter the make, model and fuel type.';
      });
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
      final capacity = manual ? existing?.tankCapacity : selected.tankCapacity;

      if (capacity != null && capacity > 0 && fuel > capacity) {
        throw Exception(
          'Current fuel cannot exceed the tank capacity of ${capacity.toStringAsFixed(0)} L.',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if ((_vehicleImage != null || _registrationCertificate != null) &&
          user == null) {
        throw Exception('Sign in before uploading vehicle documents.');
      }

      String? imageUrl;
      String? certificateUrl;
      final stamp = DateTime.now().millisecondsSinceEpoch;

      if (_vehicleImage != null) {
        final image = _vehicleImage!;
        final originalExtension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : '';
        final extension = originalExtension == 'jpg'
            ? 'jpg'
            : originalExtension;
        const supportedImageTypes = <String, String>{
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'webp': 'image/webp',
          'gif': 'image/gif',
          'avif': 'image/avif',
          'heic': 'image/heic',
          'heif': 'image/heif',
        };

        final contentType = supportedImageTypes[extension];
        if (contentType == null) {
          throw Exception(
            'Unsupported vehicle photo format. Choose a JPG, PNG, WEBP, AVIF or HEIC image.',
          );
        }

        final imageRef = FirebaseStorage.instance.ref(
          'users/${user!.uid}/vehicle-attachments/$stamp-vehicle.$extension',
        );
        await imageRef.putFile(
          File(image.path),
          SettableMetadata(contentType: contentType),
        );
        imageUrl = await imageRef.getDownloadURL();
      }

      if (_registrationCertificate != null) {
        final picked = _registrationCertificate!;
        final path = picked.path;
        if (path == null || path.isEmpty) {
          throw Exception('Could not read the selected certificate file.');
        }
        final ext = (picked.extension ?? '').toLowerCase();
        final contentType = ext == 'pdf'
            ? 'application/pdf'
            : 'image/${ext == 'jpg' ? 'jpeg' : ext}';
        final certificateRef = FirebaseStorage.instance.ref(
          'users/${user!.uid}/vehicle-attachments/$stamp-registration.$ext',
        );
        await certificateRef.putFile(
          File(path),
          SettableMetadata(contentType: contentType),
        );
        certificateUrl = await certificateRef.getDownloadURL();
      }

      if (existing != null) {
        final documentId = existing.documentId;
        if (documentId == null || documentId.isEmpty) {
          throw Exception(
            'Vehicle document ID is missing. Refresh the Garage and try again.',
          );
        }

        await VehicleRepository.instance.updateVehicle(
          vehicleDocumentId: documentId,
          name: _nameController.text.trim(),
          registrationNumber: _regController.text.trim(),
          fuelType: manual
              ? _fuelTypeController.text.trim()
              : selected.fuelType,
          tankCapacity: manual ? existing.tankCapacity : selected.tankCapacity,
          catalogId: manual ? null : selected.id,
          make: manual ? _makeController.text.trim() : selected.make,
          model: manual ? _modelController.text.trim() : selected.model,
          variant: manual ? null : selected.variant,
          modelYear: manual ? existing.modelYear : selected.modelYear,
          e20Compatible: manual
              ? existing.e20Compatible
              : selected.e20Compatible,
          e85Compatible: manual
              ? existing.e85Compatible
              : selected.e85Compatible,
          replaceCatalog: true,
          claimedMileage: manual ? null : selected.claimedMileage,
          recommendedFuel: manual ? null : selected.recommendedFuel,
          sourceName: manual ? null : selected.sourceName,
          sourceUrl: manual ? null : selected.sourceUrl,
          verifiedAt: manual ? null : selected.verifiedAt,
          engineDisplacement: manual ? null : selected.engineDisplacement,
          horsepower: manual ? null : selected.horsepower,
          torque: manual ? null : selected.torque,
          transmission: manual ? null : selected.transmission,
          drivetrain: manual ? null : selected.drivetrain,
          market: manual ? null : selected.market,
          country: manual ? null : selected.country,
          currentMileage: mileage,
          currentOdometer: odo,
          currentFuel: fuel,
          vehicleImageUrl: imageUrl,
          registrationCertificateUrl: certificateUrl,
          isManuallyEntered: manual,
        );
      } else {
        await VehicleRepository.instance.createVehicle(
          catalogId: manual ? null : selected.id,
          name: _nameController.text.trim(),
          registrationNumber: _regController.text.trim(),
          fuelType: manual
              ? _fuelTypeController.text.trim()
              : selected.fuelType,
          tankCapacity: manual ? null : selected.tankCapacity,
          claimedMileage: mileage,
          make: manual ? _makeController.text.trim() : selected.make,
          model: manual ? _modelController.text.trim() : selected.model,
          variant: manual ? null : selected.variant,
          modelYear: manual ? null : selected.modelYear,
          recommendedFuel: manual ? null : selected.recommendedFuel,
          e20Compatible: manual ? null : selected.e20Compatible,
          e85Compatible: manual ? null : selected.e85Compatible,
          sourceName: manual ? null : selected.sourceName,
          sourceUrl: manual ? null : selected.sourceUrl,
          verifiedAt: manual ? null : selected.verifiedAt,
          currentFuel: fuel,
          currentOdometer: odo,
          vehicleImageUrl: imageUrl,
          registrationCertificateUrl: certificateUrl,
          isManuallyEntered: manual,
        );
      }

      ref.invalidate(vehicleProvider);
      if (!mounted) return;
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
            child: Column(
              children: [
                if (catalog.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                if (catalog.hasError)
                  Material(
                    color: AppColors.surfaceElevated,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Vehicle catalogue unavailable. You can enter details manually.',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.invalidate(vehicleCatalogProvider);
                            },
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildForm(catalog.asData?.value ?? const <VehicleCatalog>[]),
                ),
              ],
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
                            '${selected.fuelLabel} â€¢ ${selected.compatibilityLabel}',
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
                                ].join(' â€¢ '),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _lookingUpRegistration ? null : _lookupRegistration,
                icon: _lookingUpRegistration
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.manage_search_rounded),
                label: Text(
                  _lookingUpRegistration
                      ? 'Checking registration...'
                      : 'Look up registration',
                ),
              ),
            ),
            if (_registrationDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Verified source: ${_registrationDetails!.source}'
                '${_registrationDetails!.manufactureYear == null ? '' : ' â€¢ ${_registrationDetails!.manufactureYear}'}',
                style: AppTextStyles.bodySecondary,
              ),
            ],
            if (_lookupFailed) ...[
              const SizedBox(height: 10),
              Text(
                'Lookup did not work. You can try again or enter the details manually.',
                style: AppTextStyles.bodySecondary,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _lookingUpRegistration
                          ? null
                          : _lookupRegistration,
                      child: const Text('TRY AGAIN'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _useManualEntry,
                      child: const Text('ENTER MANUALLY'),
                    ),
                  ),
                ],
              ),
            ],
            if (!_manualEntry) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _useManualEntry,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Enter vehicle details manually'),
                ),
              ),
            ],
            if (_manualEntry) ...[
              const SizedBox(height: 16),
              _label('MAKE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _makeController,
                decoration: _decoration('e.g. Hyundai', Icons.factory_outlined),
                validator: _manualEntry ? _required : null,
              ),
              const SizedBox(height: 12),
              _label('MODEL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modelController,
                decoration: _decoration(
                  'e.g. Creta',
                  Icons.directions_car_outlined,
                ),
                validator: _manualEntry ? _required : null,
              ),
              const SizedBox(height: 12),
              _label('FUEL TYPE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fuelTypeController,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoration(
                  'e.g. Petrol or Diesel',
                  Icons.local_gas_station_outlined,
                ),
                validator: _manualEntry ? _required : null,
              ),
            ],
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
            _label('VEHICLE PHOTO (OPTIONAL)'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickVehicleImage,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(_vehicleImage?.name ?? 'Choose vehicle photo'),
            ),
            const SizedBox(height: 12),
            _label('REGISTRATION CERTIFICATE (OPTIONAL)'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickRegistrationCertificate,
              icon: const Icon(Icons.description_outlined),
              label: Text(
                _registrationCertificate?.name ??
                    'Choose photo or PDF (max 10 MB)',
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



