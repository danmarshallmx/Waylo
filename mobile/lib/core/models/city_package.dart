import 'package:equatable/equatable.dart';

class CityPackage extends Equatable {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  final String description;
  final double sizeMb;
  final int version;
  final int poiCount;
  final int audioCapsuleCount;
  final DateTime updatedAt;
  final bool isDownloaded;
  final int? localVersion;

  const CityPackage({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.sizeMb,
    required this.version,
    required this.poiCount,
    required this.audioCapsuleCount,
    required this.updatedAt,
    this.isDownloaded = false,
    this.localVersion,
  });

  bool get hasUpdate =>
      isDownloaded && localVersion != null && localVersion! < version;

  CityPackage copyWith({
    String? id,
    String? name,
    String? country,
    String? imageUrl,
    String? description,
    double? sizeMb,
    int? version,
    int? poiCount,
    int? audioCapsuleCount,
    DateTime? updatedAt,
    bool? isDownloaded,
    int? localVersion,
  }) {
    return CityPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      sizeMb: sizeMb ?? this.sizeMb,
      version: version ?? this.version,
      poiCount: poiCount ?? this.poiCount,
      audioCapsuleCount: audioCapsuleCount ?? this.audioCapsuleCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localVersion: localVersion ?? this.localVersion,
    );
  }

  factory CityPackage.fromJson(Map<String, dynamic> json) {
    return CityPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String? ?? '',
      sizeMb: (json['size_mb'] as num).toDouble(),
      version: json['version'] as int,
      poiCount: json['poi_count'] as int? ?? 0,
      audioCapsuleCount: json['audio_capsule_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'image_url': imageUrl,
      'description': description,
      'size_mb': sizeMb,
      'version': version,
      'poi_count': poiCount,
      'audio_capsule_count': audioCapsuleCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        country,
        imageUrl,
        description,
        sizeMb,
        version,
        poiCount,
        audioCapsuleCount,
        updatedAt,
        isDownloaded,
        localVersion,
      ];
}
