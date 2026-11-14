import 'dart:math';

import 'package:waylo/core/models/poi.dart';

/// Top-level helper function returning distance in meters between two coordinates.
double calculateDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  return GeoUtils.distanceKm(lat1, lon1, lat2, lon2) * 1000;
}

class GeoUtils {
  /// Calculates the weighted centroid of a list of POIs.
  ///
  /// Each POI's coordinates are weighted by its [POI.weight] property.
  /// Returns a map with 'latitude' and 'longitude' keys.
  static Map<String, double> calculateWeightedCentroid(List<POI> pois) {
    if (pois.isEmpty) {
      return {'latitude': 0.0, 'longitude': 0.0};
    }

    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;

    for (final poi in pois) {
      final weight = poi.weight.toDouble();
      weightedLat += poi.latitude * weight;
      weightedLng += poi.longitude * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) {
      return {
        'latitude': pois.first.latitude,
        'longitude': pois.first.longitude,
      };
    }

    return {
      'latitude': weightedLat / totalWeight,
      'longitude': weightedLng / totalWeight,
    };
  }

  /// Calculates the distance between two coordinates in kilometers
  /// using the Haversine formula.
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculates a recommended radius (in km) that contains a percentage
  /// of the POIs from the centroid.
  static double calculateRecommendedRadius(
    List<POI> pois,
    Map<String, double> centroid, {
    double containPercentage = 0.75,
  }) {
    if (pois.isEmpty) return 2.0;

    final distances = pois.map((poi) {
      return distanceKm(
        centroid['latitude']!,
        centroid['longitude']!,
        poi.latitude,
        poi.longitude,
      );
    }).toList()
      ..sort();

    final index = ((distances.length * containPercentage) - 1).ceil().clamp(
          0,
          distances.length - 1,
        );
    final radius = distances[index];

    // Ensure minimum 0.5 km, max 15 km
    return radius.clamp(0.5, 15.0);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
