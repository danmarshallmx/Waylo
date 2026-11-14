import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/core/models/memory_photo.dart';
import 'package:waylo/features/memories/bloc/memories_event.dart';
import 'package:waylo/features/memories/bloc/memories_state.dart';
import 'package:waylo/features/memories/repositories/memories_repository.dart';

class MemoriesBloc extends Bloc<MemoriesEvent, MemoriesState> {
  final MemoriesRepository _repository;

  MemoriesBloc({required MemoriesRepository repository})
      : _repository = repository,
        super(const MemoriesInitial()) {
    on<LoadGroupMemoriesEvent>(_onLoadGroupMemories);
    on<UploadPhotosEvent>(_onUploadPhotos);
    on<PhotoUploadProgressEvent>(_onPhotoUploadProgress);
    on<PhotoUploadedSuccessEvent>(_onPhotoUploadedSuccess);
    on<DeletePhotoEvent>(_onDeletePhoto);
    on<UpdatePhotoCaptionEvent>(_onUpdatePhotoCaption);
    on<ToggleTimelineViewModeEvent>(_onToggleTimelineViewMode);
    on<RealtimeMemoryAddedEvent>(_onRealtimeMemoryAdded);
  }

  Map<String, List<MemoryPhoto>> _groupByDay(List<MemoryPhoto> photos) {
    final map = <String, List<MemoryPhoto>>{};
    for (final p in photos) {
      final key = p.capturedAt.toIso8601String().split('T')[0];
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  Map<String, List<MemoryPhoto>> _groupByPoi(List<MemoryPhoto> photos) {
    final map = <String, List<MemoryPhoto>>{};
    for (final p in photos) {
      final key = p.poiId ?? 'General';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  Future<void> _onLoadGroupMemories(
      LoadGroupMemoriesEvent event, Emitter<MemoriesState> emit) async {
    emit(const MemoriesLoading());
    try {
      final photos = await _repository.getGroupPhotos(event.groupId);

      // Start Realtime WebSockets for new photos from peers
      _repository.subscribeToGroupPhotos(
        event.groupId,
        (photo) => add(RealtimeMemoryAddedEvent(photo)),
      );

      emit(MemoriesLoaded(
        groupId: event.groupId,
        allPhotos: photos,
        photosByDay: _groupByDay(photos),
        photosByPoi: _groupByPoi(photos),
      ));
    } catch (e) {
      emit(MemoriesError('Error cargando recuerdos: $e'));
    }
  }

  Future<void> _onUploadPhotos(
      UploadPhotosEvent event, Emitter<MemoriesState> emit) async {
    final current = state;
    if (current is! MemoriesLoaded) return;

    for (final path in event.filePaths) {
      final fileName = path.split('/').last;
      try {
        final photo = await _repository.uploadPhoto(
          groupId: event.groupId,
          filePath: path,
          onProgress: (p) => add(PhotoUploadProgressEvent(fileName: fileName, progress: p)),
        );
        add(PhotoUploadedSuccessEvent(photo));
      } catch (e) {
        emit(MemoriesError('Error subiendo foto $fileName: $e'));
      }
    }
  }

  void _onPhotoUploadProgress(
      PhotoUploadProgressEvent event, Emitter<MemoriesState> emit) {
    final current = state;
    if (current is MemoriesLoaded) {
      final updated = Map<String, double>.from(current.uploadProgress);
      if (event.progress >= 1.0) {
        updated.remove(event.fileName);
      } else {
        updated[event.fileName] = event.progress;
      }
      emit(current.copyWith(uploadProgress: updated));
    }
  }

  void _onPhotoUploadedSuccess(
      PhotoUploadedSuccessEvent event, Emitter<MemoriesState> emit) {
    final current = state;
    if (current is MemoriesLoaded) {
      final updatedPhotos = [event.photo, ...current.allPhotos];
      emit(current.copyWith(
        allPhotos: updatedPhotos,
        photosByDay: _groupByDay(updatedPhotos),
        photosByPoi: _groupByPoi(updatedPhotos),
      ));
    }
  }

  Future<void> _onDeletePhoto(
      DeletePhotoEvent event, Emitter<MemoriesState> emit) async {
    final current = state;
    if (current is! MemoriesLoaded) return;

    try {
      await _repository.deletePhoto(event.photoId);
      final updated = current.allPhotos.where((p) => p.id != event.photoId).toList();
      emit(current.copyWith(
        allPhotos: updated,
        photosByDay: _groupByDay(updated),
        photosByPoi: _groupByPoi(updated),
      ));
    } catch (_) {}
  }

  Future<void> _onUpdatePhotoCaption(
      UpdatePhotoCaptionEvent event, Emitter<MemoriesState> emit) async {
    final current = state;
    if (current is! MemoriesLoaded) return;

    try {
      await _repository.updateCaption(event.photoId, event.caption);
      final updated = current.allPhotos.map((p) {
        if (p.id == event.photoId) {
          return p.copyWith(caption: event.caption);
        }
        return p;
      }).toList();
      emit(current.copyWith(
        allPhotos: updated,
        photosByDay: _groupByDay(updated),
        photosByPoi: _groupByPoi(updated),
      ));
    } catch (_) {}
  }

  void _onToggleTimelineViewMode(
      ToggleTimelineViewModeEvent event, Emitter<MemoriesState> emit) {
    final current = state;
    if (current is MemoriesLoaded) {
      final newMode = current.viewMode == MemoryViewMode.timeline
          ? MemoryViewMode.byAttraction
          : MemoryViewMode.timeline;
      emit(current.copyWith(viewMode: newMode));
    }
  }

  void _onRealtimeMemoryAdded(
      RealtimeMemoryAddedEvent event, Emitter<MemoriesState> emit) {
    final current = state;
    if (current is MemoriesLoaded) {
      if (!current.allPhotos.any((p) => p.id == event.photo.id)) {
        final updated = [event.photo, ...current.allPhotos];
        emit(current.copyWith(
          allPhotos: updated,
          photosByDay: _groupByDay(updated),
          photosByPoi: _groupByPoi(updated),
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _repository.unsubscribe();
    return super.close();
  }
}
