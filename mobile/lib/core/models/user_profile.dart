import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String preferredLanguage;
  final List<String> downloadedCityIds;
  final List<String> favoritePoiIds;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.downloadedCityIds = const [],
    this.favoritePoiIds = const [],
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      downloadedCityIds: json['downloaded_city_ids'] != null
          ? List<String>.from(json['downloaded_city_ids'] as List)
          : const [],
      favoritePoiIds: json['favorite_poi_ids'] != null
          ? List<String>.from(json['favorite_poi_ids'] as List)
          : const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'preferred_language': preferredLanguage,
      'downloaded_city_ids': downloadedCityIds,
      'favorite_poi_ids': favoritePoiIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        preferredLanguage,
        downloadedCityIds,
        favoritePoiIds,
        createdAt,
      ];
}
