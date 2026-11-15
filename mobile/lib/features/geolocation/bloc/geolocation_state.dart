part of 'geolocation_bloc.dart';

/// Weather conditions used for Plan B filtering.
enum WeatherCondition {
  clear,
  cloudy,
  rainy,
  stormy,
  hot,
  cold,
  snowy,
  unknown,
}

abstract class GeolocationState extends Equatable {
  const GeolocationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before monitoring has started.
class GeolocationInitial extends GeolocationState {
  const GeolocationInitial();
}

/// Active monitoring state – tracks position, nearby POIs, all monitored POIs, and audio playback.
class GeolocationMonitoring extends GeolocationState {
  final double currentLat;
  final double currentLng;
  final List<POI> nearbyPOIs;
  final List<POI> allPOIs;
  final Set<String> activeGeofences;
  final AudioCapsule? currentAudio;
  final bool isPlayingAudio;

  const GeolocationMonitoring({
    required this.currentLat,
    required this.currentLng,
    this.nearbyPOIs = const [],
    this.allPOIs = const [],
    this.activeGeofences = const {},
    this.currentAudio,
    this.isPlayingAudio = false,
  });

  GeolocationMonitoring copyWith({
    double? currentLat,
    double? currentLng,
    List<POI>? nearbyPOIs,
    List<POI>? allPOIs,
    Set<String>? activeGeofences,
    AudioCapsule? currentAudio,
    bool? isPlayingAudio,
    bool clearAudio = false,
  }) {
    return GeolocationMonitoring(
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      nearbyPOIs: nearbyPOIs ?? this.nearbyPOIs,
      allPOIs: allPOIs ?? this.allPOIs,
      activeGeofences: activeGeofences ?? this.activeGeofences,
      currentAudio: clearAudio ? null : (currentAudio ?? this.currentAudio),
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
    );
  }

  @override
  List<Object?> get props => [
        currentLat,
        currentLng,
        nearbyPOIs,
        allPOIs,
        activeGeofences,
        currentAudio,
        isPlayingAudio,
      ];
}

/// Loading Plan B alternatives.
class GeolocationPlanBLoading extends GeolocationState {
  const GeolocationPlanBLoading();
}

/// Plan B alternatives loaded.
class GeolocationPlanBLoaded extends GeolocationState {
  final List<POI> alternatives;
  final WeatherCondition weatherCondition;

  const GeolocationPlanBLoaded({
    required this.alternatives,
    required this.weatherCondition,
  });

  @override
  List<Object?> get props => [alternatives, weatherCondition];
}

/// Error state.
class GeolocationError extends GeolocationState {
  final String message;

  const GeolocationError({required this.message});

  @override
  List<Object?> get props => [message];
}
