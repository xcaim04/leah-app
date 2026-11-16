import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../domain/today/look_of_the_day.dart';
import '../repositories/settings_repository.dart';

/// Current weather at the phone's location, or null when unknown.
abstract class WeatherService {
  Future<Weather?> current();
}

/// GPS (only with permission) + Open-Meteo. Any failure returns null so the
/// caller falls back to warm weather.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService(this._settings);

  static const String askedKey = 'location_permission_asked';
  static const Duration _timeout = Duration(seconds: 5);

  final SettingsRepository _settings;

  @override
  Future<Weather?> current() async {
    // Only Android is wired up; desktop preview has no usable location.
    if (!Platform.isAndroid) return null;
    try {
      final position = await _position();
      if (position == null) return null;
      return await _fetch(
        position.latitude,
        position.longitude,
      ).timeout(_timeout);
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied &&
        await _settings.get(askedKey) == null) {
      // Ask only once ever; afterwards respect her answer silently.
      await _settings.set(askedKey, '1');
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final last = await Geolocator.getLastKnownPosition(
      forceAndroidLocationManager: true,
    );
    if (last != null) return last;
    return Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.low,
        forceLocationManager: true, // works without Google Play services
        timeLimit: _timeout,
      ),
    );
  }

  Future<Weather?> _fetch(double lat, double lon) async {
    // Coarse coordinates only (~1 km).
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(2),
      'longitude': lon.toStringAsFixed(2),
      'current': 'temperature_2m,weather_code',
    });
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != 200) return null;
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      final current = (body as Map<String, dynamic>)['current'] as Map;
      return Weather(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
      );
    } finally {
      client.close(force: true);
    }
  }
}
