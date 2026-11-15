import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import 'package:waylo/config/app_config.dart';
import 'package:waylo/core/models/audio_capsule.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';
import 'package:waylo/features/geolocation/repositories/geolocation_repository.dart';
import 'package:waylo/features/geolocation/services/audio_player_service.dart';
import 'package:waylo/features/geolocation/services/geofence_service.dart';

part 'geolocation_event.dart';
part 'geolocation_state.dart';

class GeolocationBloc extends Bloc<GeolocationEvent, GeolocationState> {
  final GeolocationRepository _repository;
  final GeofenceService _geofenceService;
  final AudioPlayerService _audioPlayerService;

  StreamSubscription<dynamic>? _locationSubscription;
  StreamSubscription<dynamic>? _audioStateSubscription;

  /// All POIs being tracked in the current session.
  List<POI> _allPois = [];

  /// POI IDs that have already triggered – prevents duplicate notifications.
  final Set<String> _triggeredPoiIds = {};

  /// Last known position for Plan B distance sorting.
  double _lastLat = 0;
  double _lastLng = 0;

  GeolocationBloc({
    required GeolocationRepository repository,
    required GeofenceService geofenceService,
    required AudioPlayerService audioPlayerService,
  })  : _repository = repository,
        _geofenceService = geofenceService,
        _audioPlayerService = audioPlayerService,
        super(const GeolocationInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<StopMonitoring>(_onStopMonitoring);
    on<LocationUpdated>(_onLocationUpdated);
    on<POIProximityTriggered>(_onPOIProximityTriggered);
    on<AudioCapsuleStarted>(_onAudioCapsuleStarted);
    on<AudioCapsuleCompleted>(_onAudioCapsuleCompleted);
    on<RequestPlanB>(_onRequestPlanB);
    on<PlanBReceived>(_onPlanBReceived);
    on<WeatherUpdated>(_onWeatherUpdated);
  }

  // ─────────────────────────── Event handlers ───────────────────────────

  Future<void> _onStartMonitoring(
    StartMonitoring event,
    Emitter<GeolocationState> emit,
  ) async {
    try {
      _allPois = List.of(event.pois);
      _triggeredPoiIds.clear();

      // Register geofences with the OS.
      await _geofenceService.registerGeofences(event.pois);

      // Wire the geofence callback back into the BLoC.
      _geofenceService.onGeofenceTriggered = (POI poi) {
        if (!_triggeredPoiIds.contains(poi.id)) {
          add(POIProximityTriggered(poi: poi));
        }
      };

      // Start the location stream.
      final locationStream = _repository.startLocationStream();
      _locationSubscription = locationStream.listen(
        (position) {
          add(LocationUpdated(
            latitude: position.latitude,
            longitude: position.longitude,
          ));
        },
        onError: (Object error) {
          emit(GeolocationError(message: error.toString()));
        },
      );

      // Listen to audio player completion.
      _audioStateSubscription =
          _audioPlayerService.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          add(const AudioCapsuleCompleted());
        }
      });

      emit(GeolocationMonitoring(
        currentLat: 0,
        currentLng: 0,
        allPOIs: _allPois,
      ));
    } catch (e) {
      emit(GeolocationError(message: 'Failed to start monitoring: $e'));
    }
  }

  Future<void> _onStopMonitoring(
    StopMonitoring event,
    Emitter<GeolocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _audioStateSubscription?.cancel();
    _audioStateSubscription = null;
    _repository.stopLocationStream();
    await _geofenceService.unregisterAll();
    await _audioPlayerService.stop();
    _allPois = [];
    _triggeredPoiIds.clear();
    emit(const GeolocationInitial());
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<GeolocationState> emit,
  ) async {
    _lastLat = event.latitude;
    _lastLng = event.longitude;

    // Find POIs within the geofence radius.
    final nearby = <POI>[];
    final activeGeofenceIds = <String>{};

    for (final poi in _allPois) {
      final distance = calculateDistance(
        event.latitude,
        event.longitude,
        poi.latitude,
        poi.longitude,
      );

      if (distance <= AppConfig.geofenceRadiusMeters) {
        nearby.add(poi);
        activeGeofenceIds.add(poi.id);

        // Trigger proximity event if not already triggered.
        if (!_triggeredPoiIds.contains(poi.id)) {
          add(POIProximityTriggered(poi: poi));
        }
      }
    }

    // Sort nearby POIs by distance (closest first).
    nearby.sort((a, b) {
      final dA = calculateDistance(
        event.latitude,
        event.longitude,
        a.latitude,
        a.longitude,
      );
      final dB = calculateDistance(
        event.latitude,
        event.longitude,
        b.latitude,
        b.longitude,
      );
      return dA.compareTo(dB);
    });

    final currentState = state;
    if (currentState is GeolocationMonitoring) {
      emit(currentState.copyWith(
        currentLat: event.latitude,
        currentLng: event.longitude,
        nearbyPOIs: nearby,
        allPOIs: _allPois,
        activeGeofences: activeGeofenceIds,
      ));
    } else {
      emit(GeolocationMonitoring(
        currentLat: event.latitude,
        currentLng: event.longitude,
        nearbyPOIs: nearby,
        allPOIs: _allPois,
        activeGeofences: activeGeofenceIds,
      ));
    }
  }

  Future<void> _onPOIProximityTriggered(
    POIProximityTriggered event,
    Emitter<GeolocationState> emit,
  ) async {
    // Only send notification once per session for proximity alert
    if (!_triggeredPoiIds.contains(event.poi.id)) {
      _triggeredPoiIds.add(event.poi.id);
      await _repository.sendLocalNotification(event.poi);
    }

    // Auto-load and play the audio capsule
    try {
      final capsulePath = await _repository.getAudioCapsulePath(
            event.poi.id,
            AppConfig.defaultLanguage,
          ) ??
          event.poi.audioUrl ??
          'assets/audio/${event.poi.id}.m4a';

      final capsule = AudioCapsule(
        id: '${event.poi.id}_${AppConfig.defaultLanguage}',
        poiId: event.poi.id,
        language: AppConfig.defaultLanguage,
        title: event.poi.name,
        description: event.poi.description,
        audioUrl: capsulePath,
        localPath: capsulePath,
        duration: const Duration(seconds: 45),
        sizeBytes: 120000,
      );
      add(AudioCapsuleStarted(capsule: capsule));
    } catch (_) {
      // Audio capsule not available – notification was already sent.
    }
  }

  Future<void> _onAudioCapsuleStarted(
    AudioCapsuleStarted event,
    Emitter<GeolocationState> emit,
  ) async {
    final filePath = event.capsule.localPath ?? event.capsule.audioUrl;
    await _audioPlayerService.play(filePath);

    final currentState = state;
    if (currentState is GeolocationMonitoring) {
      emit(currentState.copyWith(
        currentAudio: event.capsule,
        isPlayingAudio: true,
      ));
    }
  }

  Future<void> _onAudioCapsuleCompleted(
    AudioCapsuleCompleted event,
    Emitter<GeolocationState> emit,
  ) async {
    await _audioPlayerService.stop();

    final currentState = state;
    if (currentState is GeolocationMonitoring) {
      emit(currentState.copyWith(
        isPlayingAudio: false,
        clearAudio: true,
      ));
    }
  }

  Future<void> _onRequestPlanB(
    RequestPlanB event,
    Emitter<GeolocationState> emit,
  ) async {
    emit(const GeolocationPlanBLoading());

    try {
      final weather = await _repository.getCurrentWeather(_lastLat, _lastLng);
      final alternatives = await _repository.getPlanBAlternatives(
        _lastLat,
        _lastLng,
        weather,
        _allPois,
      );

      emit(GeolocationPlanBLoaded(
        alternatives: alternatives,
        weatherCondition: weather,
      ));
    } catch (e) {
      emit(GeolocationError(message: 'Failed to load Plan B: $e'));
    }
  }

  Future<void> _onPlanBReceived(
    PlanBReceived event,
    Emitter<GeolocationState> emit,
  ) async {
    final currentState = state;
    final weather = currentState is GeolocationPlanBLoaded
        ? currentState.weatherCondition
        : WeatherCondition.unknown;

    emit(GeolocationPlanBLoaded(
      alternatives: event.alternatives,
      weatherCondition: weather,
    ));
  }

  Future<void> _onWeatherUpdated(
    WeatherUpdated event,
    Emitter<GeolocationState> emit,
  ) async {
    final currentState = state;
    if (currentState is GeolocationPlanBLoaded) {
      // Re-filter alternatives when weather changes.
      final alternatives = await _repository.getPlanBAlternatives(
        _lastLat,
        _lastLng,
        event.condition,
        _allPois,
      );
      emit(GeolocationPlanBLoaded(
        alternatives: alternatives,
        weatherCondition: event.condition,
      ));
    }
  }

  // ─────────────────────────── Lifecycle ─────────────────────────────

  @override
  Future<void> close() async {
    await _locationSubscription?.cancel();
    await _audioStateSubscription?.cancel();
    _repository.stopLocationStream();
    await _geofenceService.unregisterAll();
    await _audioPlayerService.dispose();
    return super.close();
  }
}
