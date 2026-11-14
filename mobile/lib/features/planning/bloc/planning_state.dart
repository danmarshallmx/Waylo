import 'package:equatable/equatable.dart';
import 'package:waylo/core/models/affiliate_link.dart';
import 'package:waylo/core/models/poi.dart';

abstract class PlanningState extends Equatable {
  const PlanningState();

  @override
  List<Object?> get props => [];
}

class PlanningInitial extends PlanningState {
  const PlanningInitial();
}

class PlanningLoading extends PlanningState {
  const PlanningLoading();
}

class PlanningLoaded extends PlanningState {
  final String destination;
  final String? departureCity;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final List<AffiliateLink> affiliateLinks;
  final Map<String, double> centroid; // 'latitude', 'longitude'
  final double recommendedRadiusKm;
  final List<POI> cityPois;
  final bool isSaved;

  const PlanningLoaded({
    required this.destination,
    this.departureCity,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.affiliateLinks,
    required this.centroid,
    this.recommendedRadiusKm = 2.0,
    this.cityPois = const [],
    this.isSaved = false,
  });

  @override
  List<Object?> get props => [
        destination,
        departureCity,
        startDate,
        endDate,
        travelers,
        affiliateLinks,
        centroid,
        recommendedRadiusKm,
        cityPois,
        isSaved,
      ];

  PlanningLoaded copyWith({
    String? destination,
    String? departureCity,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    List<AffiliateLink>? affiliateLinks,
    Map<String, double>? centroid,
    double? recommendedRadiusKm,
    List<POI>? cityPois,
    bool? isSaved,
  }) {
    return PlanningLoaded(
      destination: destination ?? this.destination,
      departureCity: departureCity ?? this.departureCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelers: travelers ?? this.travelers,
      affiliateLinks: affiliateLinks ?? this.affiliateLinks,
      centroid: centroid ?? this.centroid,
      recommendedRadiusKm: recommendedRadiusKm ?? this.recommendedRadiusKm,
      cityPois: cityPois ?? this.cityPois,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class PlanningError extends PlanningState {
  final String message;

  const PlanningError(this.message);

  @override
  List<Object?> get props => [message];
}
