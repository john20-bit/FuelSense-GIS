import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/location_service.dart';

class PhaseSeparationWeatherCard extends StatefulWidget {
  const PhaseSeparationWeatherCard({
    super.key,
    required this.onWeatherChanged,
  });

  final ValueChanged<PhaseSeparationWeather?> onWeatherChanged;

  @override
  State<PhaseSeparationWeatherCard> createState() =>
      _PhaseSeparationWeatherCardState();
}

class PhaseSeparationWeather {
  const PhaseSeparationWeather({
    required this.temperatureC,
    required this.humidityPercent,
    required this.precipitationMm,
    required this.source,
    required this.observedAt,
  });

  final double temperatureC;
  final double humidityPercent;
  final double? precipitationMm;
  final String? source;
  final String? observedAt;

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static PhaseSeparationWeather? fromJson(Map<String, dynamic> data) {
    final temperature = _number(data['temperature_c']);
    final humidity = _number(data['relative_humidity_percent']);

    if (temperature == null ||
        !temperature.isFinite ||
        temperature < -50 ||
        temperature > 100 ||
        humidity == null ||
        !humidity.isFinite ||
        humidity < 0 ||
        humidity > 100) {
      return null;
    }

    final precipitation = _number(data['precipitation_mm']);

    return PhaseSeparationWeather(
      temperatureC: temperature,
      humidityPercent: humidity,
      precipitationMm: precipitation != null &&
              precipitation.isFinite &&
              precipitation >= 0
          ? precipitation
          : null,
      source: data['source']?.toString(),
      observedAt: data['observed_at']?.toString(),
    );
  }
}

class _PhaseSeparationWeatherCardState
    extends State<PhaseSeparationWeatherCard> {
  static const _baseUrl =
      'https://api.open-meteo.com/v1/forecast';

  static const _muted = Color(0xFF9EADB5);
  static const _accent = Color(0xFF52E3D0);
  static const _panel = Color(0xFF101D27);
  static const _border = Color(0xFF263944);

  bool _loading = false;
  String? _error;
  PhaseSeparationWeather? _weather;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Position position =
          await LocationService.getCurrentLocation()
              .timeout(const Duration(seconds: 18));

      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'current':
              'temperature_2m,relative_humidity_2m,precipitation',
          'timezone': 'auto',
        },
      );

      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Weather request failed (${response.statusCode}). Please retry.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['current'] is! Map) {
        throw const FormatException(
          'Weather provider returned an unexpected response.',
        );
      }

      final current =
          Map<String, dynamic>.from(decoded['current'] as Map);

      final weather = PhaseSeparationWeather.fromJson({
        'temperature_c': current['temperature_2m'],
        'relative_humidity_percent':
            current['relative_humidity_2m'],
        'precipitation_mm': current['precipitation'],
        'source': 'Open-Meteo',
        'observed_at': current['time'],
      });

      if (weather == null) {
        throw const FormatException(
          'Weather provider returned invalid temperature or humidity.',
        );
      }

      if (!mounted) return;

      setState(() {
        _weather = weather;
        _loading = false;
        _error = null;
      });

      widget.onWeatherChanged(weather);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });

      widget.onWeatherChanged(null);
    }
  }

  @override
  void didUpdateWidget(covariant PhaseSeparationWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                color: _accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'LOCAL WEATHER CONTEXT',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Refresh weather',
                  onPressed: _loadWeather,
                  icon: const Icon(
                    Icons.refresh,
                    color: _accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ambient conditions near your phone location. '
            'These values do not measure water inside a fuel tank.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading && weather == null)
            const Text(
              'Loading local weather…',
              style: TextStyle(color: _muted),
            )
          else if (_error != null && weather == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFFF9D8F),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loadWeather,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry weather'),
                ),
              ],
            )
          else if (weather != null) ...[
            Row(
              children: [
                Expanded(
                  child: _WeatherValue(
                    label: 'TEMPERATURE',
                    value: '${weather.temperatureC.toStringAsFixed(1)} °C',
                  ),
                ),
                Expanded(
                  child: _WeatherValue(
                    label: 'HUMIDITY',
                    value:
                        '${weather.humidityPercent.toStringAsFixed(0)}%',
                  ),
                ),
                Expanded(
                  child: _WeatherValue(
                    label: 'PRECIPITATION',
                    value: weather.precipitationMm == null
                        ? 'N/A'
                        : '${weather.precipitationMm!.toStringAsFixed(1)} mm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Source: ${weather.source ?? 'Weather provider'}'
              '${weather.observedAt == null ? '' : ' • ${weather.observedAt}'}',
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Refresh failed: $_error',
                style: const TextStyle(
                  color: Color(0xFFFF9D8F),
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh weather'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WeatherValue extends StatelessWidget {
  const _WeatherValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9EADB5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
