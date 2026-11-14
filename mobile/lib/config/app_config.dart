class AppConfig {
  AppConfig._();

  // ==========================================
  // Supabase Configuration
  // ==========================================
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ojylufnutaqjkgzkicbd.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_BGLd6YFGiMJ42jOWSfEa6g__UyT8mU3',
  );

  // ==========================================
  // Mapbox & Vectors
  // ==========================================
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'pk.eyJ1Ijoid2F5bG8iLCJhIjoiY2x0ZXN0MDExMDAwMDFwZjB0ZXN0In0.demo',
  );

  static const String defaultMapStyle = String.fromEnvironment(
    'MAPBOX_STYLE_URL',
    defaultValue: 'mapbox://styles/mapbox/outdoors-v12',
  );

  static const double defaultMapZoom = 15.0;
  static const double poiMapZoom = 17.0;

  // ==========================================
  // Geofencing & Location
  // ==========================================
  static const double geofenceRadiusMeters = 40.0;
  static const int locationUpdateIntervalMs = 3000;
  static const double locationDistanceFilter = 15.0; // Optimized battery filter
  static const double avgWalkingSpeedMpm = 80.0; // ~4.8 km/h

  // ==========================================
  // Audio Playback
  // ==========================================
  static const String defaultLanguage = 'es';

  // ==========================================
  // Weather API (Plan B Instantáneo)
  // ==========================================
  static const String openWeatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPEN_WEATHER_API_KEY',
    defaultValue: '',
  );

  // ==========================================
  // Affiliate Partner IDs (Deep Linking)
  // ==========================================
  static const String skyscannerAffiliateId = String.fromEnvironment(
    'SKYSCANNER_AFFILIATE_ID',
    defaultValue: 'waylo_partner_pro',
  );

  static const String bookingAffiliateId = String.fromEnvironment(
    'BOOKING_AFFILIATE_ID',
    defaultValue: 'waylo_travel_pro',
  );

  static const String kayakAffiliateId = String.fromEnvironment(
    'KAYAK_AFFILIATE_ID',
    defaultValue: 'waylo_pkg_affiliate',
  );

  static const String hostelworldAffiliateId = String.fromEnvironment(
    'HOSTELWORLD_AFFILIATE_ID',
    defaultValue: 'waylo_social_stays',
  );
}
