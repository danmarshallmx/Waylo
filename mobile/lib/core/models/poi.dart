import 'package:equatable/equatable.dart';

class POI extends Equatable {
  final String id;
  final String cityId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;
  final String? imageUrl;
  final String? audioUrl;
  final int weight;
  final Map<String, String>? localizedNames;
  final List<String> tags;

  const POI({
    required this.id,
    required this.cityId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.rating = 0.0,
    this.imageUrl,
    this.audioUrl,
    this.weight = 1,
    this.localizedNames,
    this.tags = const [],
  });

  factory POI.fromJson(Map<String, dynamic> json) {
    return POI(
      id: json['id'] as String,
      cityId: json['city_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      weight: json['weight'] as int? ?? 1,
      localizedNames: json['localized_names'] != null
          ? Map<String, String>.from(json['localized_names'] as Map)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_id': cityId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'rating': rating,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'weight': weight,
      'localized_names': localizedNames,
      'tags': tags,
    };
  }

  @override
  List<Object?> get props => [
        id,
        cityId,
        name,
        description,
        latitude,
        longitude,
        category,
        rating,
        imageUrl,
        audioUrl,
        weight,
        localizedNames,
        tags,
      ];
}
