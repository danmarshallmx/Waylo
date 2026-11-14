import 'package:equatable/equatable.dart';

abstract class PlanningEvent extends Equatable {
  const PlanningEvent();

  @override
  List<Object?> get props => [];
}

class SetTripDetails extends PlanningEvent {
  final String destination;
  final String? departureCity;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;

  const SetTripDetails({
    required this.destination,
    this.departureCity,
    required this.startDate,
    required this.endDate,
    this.travelers = 1,
  });

  @override
  List<Object?> get props => [destination, departureCity, startDate, endDate, travelers];
}

class GenerateAffiliateLinksEvent extends PlanningEvent {
  const GenerateAffiliateLinksEvent();
}

class LoadHotelZoneRecommendation extends PlanningEvent {
  final String cityId;

  const LoadHotelZoneRecommendation(this.cityId);

  @override
  List<Object?> get props => [cityId];
}

class SaveSearchEvent extends PlanningEvent {
  const SaveSearchEvent();
}

class TrackAffiliateClick extends PlanningEvent {
  final String provider;
  final String category;
  final String url;

  const TrackAffiliateClick({
    required this.provider,
    required this.category,
    required this.url,
  });

  @override
  List<Object?> get props => [provider, category, url];
}
