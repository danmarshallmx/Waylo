import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:waylo/config/app_config.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';
import 'package:waylo/features/geolocation/bloc/geolocation_bloc.dart';
import 'package:waylo/features/geolocation/services/geofence_service.dart';

class GeolocationRepository {
  final GeofenceService _geofenceService;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final http.Client _httpClient;

  StreamSubscription<Position>? _positionSubscription;
  StreamController<Position>? _positionController;

  /// Cache for weather data to avoid repeated API calls.
  WeatherCondition? _cachedWeather;
  DateTime? _weatherCacheTime;
  static const _weatherCacheDuration = Duration(minutes: 15);

  GeolocationRepository({
    required GeofenceService geofenceService,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    http.Client? httpClient,
  })  : _geofenceService = geofenceService,
        _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _httpClient = httpClient ?? http.Client() {
    _initNotifications();
  }

  // ──────────────────── Notifications Setup ────────────────────

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }

  // ──────────────────── Location Stream ────────────────────

  /// Returns a broadcast stream of [Position] updates using high accuracy.
  Stream<Position> startLocationStream() {
    _positionController = StreamController<Position>.broadcast();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConfig.locationDistanceFilter.toInt(),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        _positionController?.add(position);
      },
      onError: (Object error) {
        _positionController?.addError(error);
      },
    );

    return _positionController!.stream;
  }

  /// Stops the location stream and cleans up.
  void stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _positionController?.close();
    _positionController = null;
  }

  // ──────────────────── Geofences ────────────────────

  /// Register geofence regions for the given POIs.
  Future<void> setupGeofences(List<POI> pois) async {
    await _geofenceService.registerGeofences(pois);
  }

  // ──────────────────── Weather ────────────────────

  /// Fetches the current weather condition. Falls back to cached data if
  /// the network request fails.
  Future<WeatherCondition> getCurrentWeather(
    double lat,
    double lng,
  ) async {
    // Return cached weather if still fresh.
    if (_cachedWeather != null &&
        _weatherCacheTime != null &&
        DateTime.now().difference(_weatherCacheTime!) < _weatherCacheDuration) {
      return _cachedWeather!;
    }

    try {
      final uri = Uri.parse(
        '${AppConfig.openWeatherBaseUrl}/weather'
        '?lat=$lat&lon=$lng'
        '&appid=${AppConfig.openWeatherApiKey}'
        '&units=metric',
      );

      final response = await _httpClient.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final condition = _parseWeatherCondition(data);
        _cachedWeather = condition;
        _weatherCacheTime = DateTime.now();
        return condition;
      }
    } catch (_) {
      // Fall through to cached / unknown.
    }

    return _cachedWeather ?? WeatherCondition.unknown;
  }

  WeatherCondition _parseWeatherCondition(Map<String, dynamic> data) {
    final weatherList = data['weather'] as List<dynamic>?;
    if (weatherList == null || weatherList.isEmpty) {
      return WeatherCondition.unknown;
    }

    final main =
        (weatherList[0] as Map<String, dynamic>)['main'] as String? ?? '';
    final temp =
        ((data['main'] as Map<String, dynamic>?)?['temp'] as num?)
            ?.toDouble() ??
        20.0;

    switch (main.toLowerCase()) {
      case 'thunderstorm':
        return WeatherCondition.stormy;
      case 'drizzle':
      case 'rain':
        return WeatherCondition.rainy;
      case 'snow':
        return WeatherCondition.snowy;
      case 'clouds':
        return WeatherCondition.cloudy;
      case 'clear':
        return temp > 35 ? WeatherCondition.hot : WeatherCondition.clear;
      default:
        if (temp < 0) return WeatherCondition.cold;
        if (temp > 35) return WeatherCondition.hot;
        return WeatherCondition.clear;
    }
  }

  // ──────────────────── Plan B ────────────────────

  /// Filters and sorts POIs based on the current weather and distance from
  /// the user.
  Future<List<POI>> getPlanBAlternatives(
    double lat,
    double lng,
    WeatherCondition weatherCondition,
    List<POI> allPois,
  ) async {
    List<POI> filtered;

    switch (weatherCondition) {
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
      case WeatherCondition.snowy:
        // Bad weather → prefer indoor POIs.
        filtered = allPois.where((poi) => _isIndoor(poi)).toList();
        break;
      case WeatherCondition.hot:
        // Hot weather → prefer indoor or water-related / shaded POIs.
        filtered = allPois.where((poi) {
          return _isIndoor(poi) ||
              poi.tags.any((t) =>
                  t.toLowerCase().contains('water') ||
                  t.toLowerCase().contains('shade'));
        }).toList();
        break;
      case WeatherCondition.clear:
      case WeatherCondition.cloudy:
        // Good weather → prefer outdoor POIs.
        filtered = allPois.where((poi) => _isOutdoor(poi)).toList();
        break;
      case WeatherCondition.cold:
        filtered = allPois.where((poi) => _isIndoor(poi)).toList();
        break;
      case WeatherCondition.unknown:
        filtered = List.of(allPois);
        break;
    }

    // Fall back to all POIs if filtering yields nothing.
    if (filtered.isEmpty) {
      filtered = List.of(allPois);
    }

    // Sort by distance from the user.
    filtered.sort((a, b) {
      final dA = calculateDistance(lat, lng, a.latitude, a.longitude);
      final dB = calculateDistance(lat, lng, b.latitude, b.longitude);
      return dA.compareTo(dB);
    });

    return filtered;
  }

  bool _isIndoor(POI poi) {
    const indoorCategories = {
      'museum',
      'restaurant',
      'church',
      'market',
      'cafe',
      'gallery',
      'theater',
    };
    return indoorCategories.contains(poi.category.toLowerCase());
  }

  bool _isOutdoor(POI poi) {
    const outdoorCategories = {
      'park',
      'monument',
      'garden',
      'plaza',
      'beach',
      'viewpoint',
    };
    return outdoorCategories.contains(poi.category.toLowerCase());
  }

  // ──────────────────── Audio Capsule ────────────────────

  /// Returns the local file path for a POI's audio capsule, or falls back to
  /// bundled asset path if not yet downloaded to the documents directory.
  Future<String?> getAudioCapsulePath(String poiId, String language) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/audio_capsules/${poiId}_$language.mp3';

      // Check if the file exists on disk.
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }
      return 'assets/audio/$poiId.m4a';
    } catch (_) {
      return 'assets/audio/$poiId.m4a';
    }
  }

  // ──────────────────── Local Notifications ────────────────────

  /// Sends a local notification alerting the user they are near a POI.
  Future<void> sendLocalNotification(POI poi) async {
    const androidDetails = AndroidNotificationDetails(
      'waylo_poi_proximity',
      'POI Proximity Alerts',
      channelDescription: 'Notifications when you are near a point of interest',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      poi.id.hashCode,
      'You\'re near ${poi.name}!',
      'Tap to listen to the audio guide for this ${poi.category}.',
      details,
      payload: poi.id,
    );
  }

  /// Clean up resources.
  void dispose() {
    stopLocationStream();
    _httpClient.close();
  }
}
