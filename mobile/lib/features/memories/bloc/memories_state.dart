import 'package:equatable/equatable.dart';
import 'package:waylo/core/models/memory_photo.dart';

enum MemoryViewMode {
  timeline,
  byAttraction,
}

abstract class MemoriesState extends Equatable {
  const MemoriesState();

  @override
  List<Object?> get props => [];
}

class MemoriesInitial extends MemoriesState {
  const MemoriesInitial();
}

class MemoriesLoading extends MemoriesState {
  const MemoriesLoading();
}

class MemoriesLoaded extends MemoriesState {
  final String groupId;
  final List<MemoryPhoto> allPhotos;
  final Map<String, List<MemoryPhoto>> photosByDay; // YYYY-MM-DD -> photos
  final Map<String, List<MemoryPhoto>> photosByPoi; // poi_id or 'General' -> photos
  final MemoryViewMode viewMode;
  final Map<String, double> uploadProgress; // fileName -> 0.0..1.0

  const MemoriesLoaded({
    required this.groupId,
    required this.allPhotos,
    required this.photosByDay,
    required this.photosByPoi,
    this.viewMode = MemoryViewMode.timeline,
    this.uploadProgress = const {},
  });

  @override
  List<Object?> get props => [
        groupId,
        allPhotos,
        photosByDay,
        photosByPoi,
        viewMode,
        uploadProgress,
      ];

  MemoriesLoaded copyWith({
    String? groupId,
    List<MemoryPhoto>? allPhotos,
    Map<String, List<MemoryPhoto>>? photosByDay,
    Map<String, List<MemoryPhoto>>? photosByPoi,
    MemoryViewMode? viewMode,
    Map<String, double>? uploadProgress,
  }) {
    return MemoriesLoaded(
      groupId: groupId ?? this.groupId,
      allPhotos: allPhotos ?? this.allPhotos,
      photosByDay: photosByDay ?? this.photosByDay,
      photosByPoi: photosByPoi ?? this.photosByPoi,
      viewMode: viewMode ?? this.viewMode,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class MemoriesError extends MemoriesState {
  final String message;

  const MemoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
