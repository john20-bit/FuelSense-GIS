import 'package:flutter/material.dart';

import '../../../../shared/models/vehicle.dart';

class VehicleHealthCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleHealthCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final double fuelPercentage = vehicle.fuelPercentage;
    final double fuelLevel = vehicle.currentFuelLevel;
    final double tankCapacity = vehicle.tankCapacity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101A17), Color(0xFF09100E), Color(0xFF050706)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 25),

          Row(
            children: [
              const Icon(
                Icons.directions_car_outlined,
                size: 20,
                color: Colors.white54,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  vehicle.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            '${vehicle.registrationNumber} • ${vehicle.fuelType}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white38,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _VehicleStat(
                  icon: Icons.speed_rounded,
                  label: 'MILEAGE',
                  value: '${vehicle.currentMileage.toStringAsFixed(1)} km/L',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VehicleStat(
                  icon: Icons.local_gas_station_rounded,
                  label: 'TANK',
                  value: '${vehicle.tankCapacity.toStringAsFixed(1)} L',
                  valueColor: Colors.greenAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _VehicleStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'FUEL TYPE',
                  value: vehicle.fuelType,
                  valueColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VehicleStat(
                  icon: Icons.confirmation_number_outlined,
                  label: 'VEHICLE ID',
                  value: '#${vehicle.id}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildFuelLevel(
            fuelPercentage: fuelPercentage,
            fuelLevel: fuelLevel,
            tankCapacity: tankCapacity,
          ),

          const SizedBox(height: 18),

          _buildAiStatus(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.greenAccent, Colors.green],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.20),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.black,
            size: 25,
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VEHICLE INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.greenAccent,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Live vehicle information',
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.18),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Colors.greenAccent,
              ),
              SizedBox(width: 5),
              Text(
                'CONNECTED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFuelLevel({
    required double fuelPercentage,
    required double fuelLevel,
    required double tankCapacity,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.greenAccent.withValues(alpha: 0.055),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  size: 21,
                  color: Colors.greenAccent,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'CURRENT FUEL LEVEL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.greenAccent,
                  ),
                ),
              ),

              Text(
                '${fuelPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: fuelPercentage / 100,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fuelLevel.toStringAsFixed(1)} L remaining',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${tankCapacity.toStringAsFixed(1)} L capacity',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        color: Colors.greenAccent.withValues(alpha: 0.06),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.greenAccent.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 20,
              color: Colors.greenAccent,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VEHICLE STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.greenAccent,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Vehicle data synchronized.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 3),
                Text(
                  'Live vehicle information received from the FuelSense backend.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _VehicleStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.greenAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
