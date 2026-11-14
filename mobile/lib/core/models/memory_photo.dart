import 'package:equatable/equatable.dart';

/// Represents a photo memory captured during a trip.
class MemoryPhoto extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String? poiId;
  final String storageUrl;
  final String? thumbnailUrl;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final DateTime uploadedAt;
  final String? caption;
  final Map<String, dynamic> exifData;

  const MemoryPhoto({
    required this.id,
    required this.groupId,
    required this.userId,
    this.poiId,
    required this.storageUrl,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    required this.uploadedAt,
    this.caption,
    this.exifData = const {},
  });

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) {
    return MemoryPhoto(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      poiId: json['poi_id'] as String?,
      storageUrl: json['storage_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['captured_at'] as String),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      caption: json['caption'] as String?,
      exifData: json['exif_data'] is Map<String, dynamic>
          ? json['exif_data'] as Map<String, dynamic>
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'poi_id': poiId,
      'storage_url': storageUrl,
      'thumbnail_url': thumbnailUrl,
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      'caption': caption,
      'exif_data': exifData,
    };
  }

  MemoryPhoto copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? poiId,
    String? storageUrl,
    String? thumbnailUrl,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
    DateTime? uploadedAt,
    String? caption,
    Map<String, dynamic>? exifData,
  }) {
    return MemoryPhoto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      poiId: poiId ?? this.poiId,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      caption: caption ?? this.caption,
      exifData: exifData ?? this.exifData,
    );
  }

  /// Whether this photo has GPS coordinates.
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        poiId,
        storageUrl,
        thumbnailUrl,
        latitude,
        longitude,
        capturedAt,
        uploadedAt,
        caption,
        exifData,
      ];

  @override
  String toString() =>
      'MemoryPhoto(id: $id, group: $groupId, poi: $poiId, '
      'captured: $capturedAt)';
}
