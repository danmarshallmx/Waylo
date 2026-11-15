import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waylo/config/app_config.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';

typedef GeofenceCallback = void Function(POI poi);

/// Low-power native background geofence coordinator
class GeofenceService {
  final Set<String> _registeredPoiIds = {};
  final List<POI> _activePois = [];
  GeofenceCallback? _onGeofenceTriggered;
  StreamSubscription<Position>? _positionStream;

  set onGeofenceTriggered(GeofenceCallback? callback) {
    _onGeofenceTriggered = callback;
  }

  void setCallback(GeofenceCallback callback) {
    _onGeofenceTriggered = callback;
  }

  /// Register geofences for a list of POIs with battery-efficient location settings
  Future<void> registerGeofences(List<POI> pois) async {
    _activePois.clear();
    _activePois.addAll(pois);
    _registeredPoiIds.clear();
    for (final p in pois) {
      _registeredPoiIds.add(p.id);
    }

    await _startBackgroundMonitoring();
  }

  Future<void> _startBackgroundMonitoring() async {
    await _positionStream?.cancel();

    // High accuracy with distance filter of 15 meters to minimize battery drain
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _checkProximity(position.latitude, position.longitude);
    }, onError: (err) {
      debugPrint('GeofenceService position error: $err');
    });
  }

  void _checkProximity(double lat, double lng) {
    for (final poi in _activePois) {
      final distance = GeoUtils.distanceKm(lat, lng, poi.latitude, poi.longitude) * 1000;
      if (distance <= AppConfig.geofenceRadiusMeters) {
        _onGeofenceTriggered?.call(poi);
      }
    }
  }

  /// Unregister all active geofences
  Future<void> unregisterAll() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _activePois.clear();
    _registeredPoiIds.clear();
  }

  bool isRegistered(String poiId) => _registeredPoiIds.contains(poiId);
}
