import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waylo/config/app_config.dart';
import 'package:waylo/core/models/affiliate_link.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';
import 'package:waylo/core/utils/url_utils.dart';

class PlanningRepository {
  final SupabaseClient _supabase;
  final Dio _dio;

  PlanningRepository({
    SupabaseClient? supabase,
    Dio? dio,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _dio = dio ?? Dio();

  /// Generates deep linking affiliate URLs for Flights & Hotels
  Future<List<AffiliateLink>> generateAffiliateLinks({
    required String destination,
    String? departureCity,
    DateTime? startDate,
    DateTime? endDate,
    int travelers = 1,
  }) async {
    final sDate = startDate ?? DateTime.now().add(const Duration(days: 14));
    final eDate = endDate ?? DateTime.now().add(const Duration(days: 21));
    final sDateStr = "${sDate.year}-${sDate.month.toString().padLeft(2, '0')}-${sDate.day.toString().padLeft(2, '0')}";
    final eDateStr = "${eDate.year}-${eDate.month.toString().padLeft(2, '0')}-${eDate.day.toString().padLeft(2, '0')}";

    final destEncoded = Uri.encodeComponent(destination);
    final originEncoded = departureCity != null ? Uri.encodeComponent(departureCity) : '';

    return [
      AffiliateLink(
        id: 'skyscanner_${destination.toLowerCase()}',
        provider: 'Skyscanner',
        providerLogoUrl: 'https://logos-world.net/wp-content/uploads/2021/08/Skyscanner-Logo.png',
        url: UrlUtils.buildAffiliateUrl(
          baseUrl: 'https://www.skyscanner.com/transport/flights/$originEncoded/$destEncoded',
          affiliateId: AppConfig.skyscannerAffiliateId,
          extraParams: {
            'adultsv2': travelers.toString(),
            'inboundDate': eDateStr,
            'outboundDate': sDateStr,
          },
        ),
        destination: destination,
        departureCity: departureCity,
        startDate: sDate,
        endDate: eDate,
        travelers: travelers,
        category: 'flight',
        priceEstimate: 'Desde €49 i/v',
        description: 'Vuelos más rápidos y directos recomendados con alerta de precio.',
      ),
      AffiliateLink(
        id: 'booking_${destination.toLowerCase()}',
        provider: 'Booking.com',
        providerLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/b/be/Booking.com_logo.svg',
        url: UrlUtils.buildAffiliateUrl(
          baseUrl: 'https://www.booking.com/searchresults.html',
          affiliateId: AppConfig.bookingAffiliateId,
          extraParams: {
            'ss': destination,
            'checkin': sDateStr,
            'checkout': eDateStr,
            'group_adults': travelers.toString(),
          },
        ),
        destination: destination,
        startDate: sDate,
        endDate: eDate,
        travelers: travelers,
        category: 'hotel',
        priceEstimate: 'Hoteles desde €65/noche',
        description: 'En el centroide turístico sugerido para minimizar desplazamientos a pie.',
      ),
      AffiliateLink(
        id: 'kayak_${destination.toLowerCase()}',
        provider: 'Kayak',
        providerLogoUrl: 'https://logos-world.net/wp-content/uploads/2023/04/Kayak-Logo.png',
        url: UrlUtils.buildAffiliateUrl(
          baseUrl: 'https://www.kayak.com/packages/$destEncoded',
          affiliateId: AppConfig.kayakAffiliateId,
          extraParams: {
            'checkin': sDateStr,
            'checkout': eDateStr,
            'adults': travelers.toString(),
          },
        ),
        destination: destination,
        startDate: sDate,
        endDate: eDate,
        travelers: travelers,
        category: 'package',
        priceEstimate: 'Paquete Vuelo+Hotel hasta -25%',
        description: 'Ahorro conjunto ideal para estancias planificadas de fin de semana.',
      ),
    ];
  }

  /// Calculates the weighted centroid of destination POIs for optimal lodging
  Future<Map<String, dynamic>> calculateOptimalHotelZone(String cityId) async {
    try {
      final res = await _supabase.from('pois').select('*').eq('city_id', cityId);
      final pois = (res as List).map((e) => POI.fromJson(e as Map<String, dynamic>)).toList();

      final centroid = GeoUtils.calculateWeightedCentroid(pois);

      return {
        'centroid': centroid,
        'radius_km': 1.8,
        'pois': pois,
      };
    } catch (_) {
      // Default to city center coordinates (Liverpool example fallback)
      return {
        'centroid': {'latitude': 53.4045, 'longitude': -2.9850},
        'radius_km': 2.0,
        'pois': <POI>[],
      };
    }
  }

  /// Saves search in backend
  Future<void> saveSearch({
    required String destination,
    String? departureCity,
    DateTime? startDate,
    DateTime? endDate,
    int travelers = 1,
    Map<String, double>? centroid,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('saved_searches').insert({
      'user_id': userId,
      'destination': destination,
      'departure_city': departureCity,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'travelers': travelers,
      'recommended_zone_lat': centroid?['latitude'],
      'recommended_zone_lng': centroid?['longitude'],
      'recommended_radius_km': 2.0,
    });
  }

  /// Tracks affiliate click
  Future<void> trackClick({
    required String provider,
    required String category,
    required String destination,
    required String url,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('affiliate_clicks').insert({
        'user_id': userId,
        'provider': provider,
        'category': category,
        'destination': destination,
        'generated_url': url,
      });
    } catch (_) {}
  }
}
