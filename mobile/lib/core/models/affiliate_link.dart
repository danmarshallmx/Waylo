import 'package:equatable/equatable.dart';

class AffiliateLink extends Equatable {
  final String id;
  final String provider;
  final String providerLogoUrl;
  final String url;
  final String destination;
  final String? departureCity;
  final DateTime? startDate;
  final DateTime? endDate;
  final int travelers;
  final String category; // 'flight', 'hotel', 'activity', 'car_rental'
  final String? priceEstimate;
  final String? description;

  const AffiliateLink({
    required this.id,
    required this.provider,
    required this.providerLogoUrl,
    required this.url,
    required this.destination,
    this.departureCity,
    this.startDate,
    this.endDate,
    this.travelers = 1,
    required this.category,
    this.priceEstimate,
    this.description,
  });

  factory AffiliateLink.fromJson(Map<String, dynamic> json) {
    return AffiliateLink(
      id: json['id'] as String,
      provider: json['provider'] as String,
      providerLogoUrl: json['provider_logo_url'] as String? ?? '',
      url: json['url'] as String,
      destination: json['destination'] as String,
      departureCity: json['departure_city'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      travelers: json['travelers'] as int? ?? 1,
      category: json['category'] as String,
      priceEstimate: json['price_estimate'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'provider_logo_url': providerLogoUrl,
      'url': url,
      'destination': destination,
      'departure_city': departureCity,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'travelers': travelers,
      'category': category,
      'price_estimate': priceEstimate,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
        id,
        provider,
        providerLogoUrl,
        url,
        destination,
        departureCity,
        startDate,
        endDate,
        travelers,
        category,
        priceEstimate,
        description,
      ];
}
