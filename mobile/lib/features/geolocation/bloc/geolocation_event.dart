part of 'geolocation_bloc.dart';

abstract class GeolocationEvent extends Equatable {
  const GeolocationEvent();

  @override
  List<Object?> get props => [];
}

/// Start monitoring POI proximity for the given list of POIs.
class StartMonitoring extends GeolocationEvent {
  final List<POI> pois;

  const StartMonitoring({required this.pois});

  @override
  List<Object?> get props => [pois];
}

/// Stop all location monitoring and geofence tracking.
class StopMonitoring extends GeolocationEvent {
  const StopMonitoring();
}

/// Fired whenever the device location changes.
class LocationUpdated extends GeolocationEvent {
  final double latitude;
  final double longitude;

  const LocationUpdated({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Fired when the user enters a POI's geofence radius.
class POIProximityTriggered extends GeolocationEvent {
  final POI poi;

  const POIProximityTriggered({required this.poi});

  @override
  List<Object?> get props => [poi];
}

/// Fired when an audio capsule begins playback.
class AudioCapsuleStarted extends GeolocationEvent {
  final AudioCapsule capsule;

  const AudioCapsuleStarted({required this.capsule});

  @override
  List<Object?> get props => [capsule];
}

/// Fired when the current audio capsule finishes playing.
class AudioCapsuleCompleted extends GeolocationEvent {
  const AudioCapsuleCompleted();
}

/// User requests Plan B alternatives (e.g. weather changed).
class RequestPlanB extends GeolocationEvent {
  const RequestPlanB();
}

/// Plan B alternatives have been received from the repository.
class PlanBReceived extends GeolocationEvent {
  final List<POI> alternatives;

  const PlanBReceived({required this.alternatives});

  @override
  List<Object?> get props => [alternatives];
}

/// Weather conditions have been refreshed.
class WeatherUpdated extends GeolocationEvent {
  final WeatherCondition condition;

  const WeatherUpdated({required this.condition});

  @override
  List<Object?> get props => [condition];
}
