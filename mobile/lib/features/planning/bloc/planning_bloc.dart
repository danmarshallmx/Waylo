import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/features/planning/bloc/planning_event.dart';
import 'package:waylo/features/planning/bloc/planning_state.dart';
import 'package:waylo/features/planning/repositories/planning_repository.dart';

class PlanningBloc extends Bloc<PlanningEvent, PlanningState> {
  final PlanningRepository _repository;

  PlanningBloc({required PlanningRepository repository})
      : _repository = repository,
        super(const PlanningInitial()) {
    on<SetTripDetails>(_onSetTripDetails);
    on<GenerateAffiliateLinksEvent>(_onGenerateAffiliateLinks);
    on<LoadHotelZoneRecommendation>(_onLoadHotelZoneRecommendation);
    on<SaveSearchEvent>(_onSaveSearch);
    on<TrackAffiliateClick>(_onTrackAffiliateClick);
  }

  Future<void> _onSetTripDetails(
    SetTripDetails event,
    Emitter<PlanningState> emit,
  ) async {
    emit(const PlanningLoading());
    try {
      final links = await _repository.generateAffiliateLinks(
        destination: event.destination,
        departureCity: event.departureCity,
        startDate: event.startDate,
        endDate: event.endDate,
        travelers: event.travelers,
      );

      // Map common destination name to city package id
      final cityId = event.destination.toLowerCase().contains('liverpool')
          ? 'liverpool_uk'
          : 'barcelona_es';

      final zoneData = await _repository.calculateOptimalHotelZone(cityId);

      emit(PlanningLoaded(
        destination: event.destination,
        departureCity: event.departureCity,
        startDate: event.startDate,
        endDate: event.endDate,
        travelers: event.travelers,
        affiliateLinks: links,
        centroid: zoneData['centroid'] as Map<String, double>,
        recommendedRadiusKm: (zoneData['radius_km'] as num).toDouble(),
        cityPois: zoneData['pois'] ?? [],
      ));
    } catch (e) {
      emit(PlanningError('Error configurando la planeación: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateAffiliateLinks(
    GenerateAffiliateLinksEvent event,
    Emitter<PlanningState> emit,
  ) async {
    final current = state;
    if (current is! PlanningLoaded) return;

    try {
      final links = await _repository.generateAffiliateLinks(
        destination: current.destination,
        departureCity: current.departureCity,
        startDate: current.startDate,
        endDate: current.endDate,
        travelers: current.travelers,
      );
      emit(current.copyWith(affiliateLinks: links));
    } catch (e) {
      emit(PlanningError('Error actualizando afiliados: $e'));
    }
  }

  Future<void> _onLoadHotelZoneRecommendation(
    LoadHotelZoneRecommendation event,
    Emitter<PlanningState> emit,
  ) async {
    final current = state;
    if (current is! PlanningLoaded) return;

    try {
      final zoneData = await _repository.calculateOptimalHotelZone(event.cityId);
      emit(current.copyWith(
        centroid: zoneData['centroid'] as Map<String, double>,
        recommendedRadiusKm: (zoneData['radius_km'] as num).toDouble(),
        cityPois: zoneData['pois'],
      ));
    } catch (_) {}
  }

  Future<void> _onSaveSearch(
    SaveSearchEvent event,
    Emitter<PlanningState> emit,
  ) async {
    final current = state;
    if (current is! PlanningLoaded) return;

    try {
      await _repository.saveSearch(
        destination: current.destination,
        departureCity: current.departureCity,
        startDate: current.startDate,
        endDate: current.endDate,
        travelers: current.travelers,
        centroid: current.centroid,
      );
      emit(current.copyWith(isSaved: true));
    } catch (_) {}
  }

  Future<void> _onTrackAffiliateClick(
    TrackAffiliateClick event,
    Emitter<PlanningState> emit,
  ) async {
    final current = state;
    final dest = current is PlanningLoaded ? current.destination : 'Unknown';

    await _repository.trackClick(
      provider: event.provider,
      category: event.category,
      destination: dest,
      url: event.url,
    );
  }
}
