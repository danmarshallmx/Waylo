import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';

void main() {
  group('GeoUtils Unit Tests', () {
    test('calculateWeightedCentroid should return (0,0) for empty POI list', () {
      final centroid = GeoUtils.calculateWeightedCentroid([]);
      expect(centroid['latitude'], 0.0);
      expect(centroid['longitude'], 0.0);
    });

    test('calculateWeightedCentroid should return exact coordinates for single POI', () {
      const poi = POI(
        id: 'poi_1',
        cityId: 'liverpool_uk',
        name: 'The Cavern Club',
        description: '',
        latitude: 53.4063,
        longitude: -2.9878,
        category: 'monument',
        weight: 5,
      );

      final centroid = GeoUtils.calculateWeightedCentroid([poi]);
      expect(centroid['latitude'], closeTo(53.4063, 0.0001));
      expect(centroid['longitude'], closeTo(-2.9878, 0.0001));
    });

    test('calculateWeightedCentroid pulls center towards heavier attractions in Liverpool', () {
      // Light attraction (weight 1)
      const lightAttraction = POI(
        id: 'light',
        cityId: 'liverpool_uk',
        name: 'Periphery Park',
        description: '',
        latitude: 53.3800,
        longitude: -2.9300,
        category: 'park',
        weight: 1,
      );

      // Heavy iconic cluster (weight 9 total) near Albert Dock
      const heavyPoi1 = POI(
        id: 'dock',
        cityId: 'liverpool_uk',
        name: 'Royal Albert Dock',
        description: '',
        latitude: 53.3992,
        longitude: -2.9917,
        category: 'monument',
        weight: 5,
      );

      const heavyPoi2 = POI(
        id: 'beatles',
        cityId: 'liverpool_uk',
        name: 'The Beatles Story',
        description: '',
        latitude: 53.3990,
        longitude: -2.9919,
        category: 'museum',
        weight: 4,
      );

      final pois = [lightAttraction, heavyPoi1, heavyPoi2];
      final centroid = GeoUtils.calculateWeightedCentroid(pois);

      // Total weight = 1 + 5 + 4 = 10
      // Weighted Lat = (53.3800 * 1 + 53.3992 * 5 + 53.3990 * 4) / 10 = 53.3972
      // Weighted Lng = (-2.9300 * 1 + -2.9917 * 5 + -2.9919 * 4) / 10 = -2.9856
      expect(centroid['latitude']!, closeTo(53.3972, 0.001));
      expect(centroid['longitude']!, closeTo(-2.9856, 0.001));

      // The centroid should be closer to the heavy cluster than unweighted average
      final unweightedLat = (53.3800 + 53.3992 + 53.3990) / 3; // 53.3927
      expect(centroid['latitude']! > unweightedLat, isTrue);
    });

    test('Haversine distanceKm calculates distance between Liverpool landmarks accurately', () {
      // Royal Albert Dock coordinates
      const albertDockLat = 53.3992;
      const albertDockLng = -2.9917;

      // The Cavern Club coordinates
      const cavernLat = 53.4063;
      const cavernLng = -2.9878;

      final distance = GeoUtils.distanceKm(
        albertDockLat,
        albertDockLng,
        cavernLat,
        cavernLng,
      );

      // Distance should be approximately 0.83 km (~830 meters)
      expect(distance, closeTo(0.83, 0.08));

      // Top-level calculateDistance should return value in meters
      final distanceMeters = calculateDistance(
        albertDockLat,
        albertDockLng,
        cavernLat,
        cavernLng,
      );
      expect(distanceMeters, closeTo(830, 80));
    });

    test('calculateRecommendedRadius covers cluster without expanding to far outskirts', () {
      const p1 = POI(id: '1', cityId: 'c', name: 'P1', description: '', latitude: 53.400, longitude: -2.990, category: 'm', weight: 1);
      const p2 = POI(id: '2', cityId: 'c', name: 'P2', description: '', latitude: 53.402, longitude: -2.992, category: 'm', weight: 1);
      const p3 = POI(id: '3', cityId: 'c', name: 'P3', description: '', latitude: 53.398, longitude: -2.988, category: 'm', weight: 1);
      // Far outlier (Sefton Park)
      const p4 = POI(id: '4', cityId: 'c', name: 'P4', description: '', latitude: 53.350, longitude: -2.900, category: 'm', weight: 1);

      final centroid = GeoUtils.calculateWeightedCentroid([p1, p2, p3, p4]);
      final radius = GeoUtils.calculateRecommendedRadius([p1, p2, p3, p4], centroid, containPercentage: 0.75);

      // Recommended radius should cover majority but stay within reasonable bounds
      expect(radius >= 0.5, isTrue);
      expect(radius <= 5.0, isTrue);
    });
  });
}
