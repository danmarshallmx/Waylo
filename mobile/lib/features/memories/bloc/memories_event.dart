import 'package:equatable/equatable.dart';
import 'package:waylo/core/models/memory_photo.dart';

abstract class MemoriesEvent extends Equatable {
  const MemoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupMemoriesEvent extends MemoriesEvent {
  final String groupId;

  const LoadGroupMemoriesEvent(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class UploadPhotosEvent extends MemoriesEvent {
  final String groupId;
  final List<String> filePaths;

  const UploadPhotosEvent({required this.groupId, required this.filePaths});

  @override
  List<Object?> get props => [groupId, filePaths];
}

class PhotoUploadProgressEvent extends MemoriesEvent {
  final String fileName;
  final double progress;

  const PhotoUploadProgressEvent({required this.fileName, required this.progress});

  @override
  List<Object?> get props => [fileName, progress];
}

class PhotoUploadedSuccessEvent extends MemoriesEvent {
  final MemoryPhoto photo;

  const PhotoUploadedSuccessEvent(this.photo);

  @override
  List<Object?> get props => [photo];
}

class DeletePhotoEvent extends MemoriesEvent {
  final String photoId;

  const DeletePhotoEvent(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

class UpdatePhotoCaptionEvent extends MemoriesEvent {
  final String photoId;
  final String caption;

  const UpdatePhotoCaptionEvent({required this.photoId, required this.caption});

  @override
  List<Object?> get props => [photoId, caption];
}

class ToggleTimelineViewModeEvent extends MemoriesEvent {
  const ToggleTimelineViewModeEvent();
}

class RealtimeMemoryAddedEvent extends MemoriesEvent {
  final MemoryPhoto photo;

  const RealtimeMemoryAddedEvent(this.photo);

  @override
  List<Object?> get props => [photo];
}
