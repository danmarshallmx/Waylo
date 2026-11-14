import 'package:equatable/equatable.dart';

class AudioCapsule extends Equatable {
  final String id;
  final String poiId;
  final String language;
  final String title;
  final String? description;
  final String audioUrl;
  final String? localPath;
  final Duration duration;
  final int sizeBytes;

  const AudioCapsule({
    required this.id,
    required this.poiId,
    required this.language,
    required this.title,
    this.description,
    required this.audioUrl,
    this.localPath,
    required this.duration,
    required this.sizeBytes,
  });

  bool get isDownloaded => localPath != null;

  factory AudioCapsule.fromJson(Map<String, dynamic> json) {
    return AudioCapsule(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      language: json['language'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      audioUrl: json['audio_url'] as String,
      localPath: json['local_path'] as String?,
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
      sizeBytes: json['size_bytes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poi_id': poiId,
      'language': language,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'local_path': localPath,
      'duration_seconds': duration.inSeconds,
      'size_bytes': sizeBytes,
    };
  }

  AudioCapsule copyWith({String? localPath}) {
    return AudioCapsule(
      id: id,
      poiId: poiId,
      language: language,
      title: title,
      description: description,
      audioUrl: audioUrl,
      localPath: localPath ?? this.localPath,
      duration: duration,
      sizeBytes: sizeBytes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        poiId,
        language,
        title,
        description,
        audioUrl,
        localPath,
        duration,
        sizeBytes,
      ];
}
