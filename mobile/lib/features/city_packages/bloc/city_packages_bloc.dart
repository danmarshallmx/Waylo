import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:waylo/core/models/city_package.dart';
import 'package:waylo/features/city_packages/bloc/city_packages_event.dart';
import 'package:waylo/features/city_packages/bloc/city_packages_state.dart';
import 'package:waylo/features/city_packages/repositories/city_packages_repository.dart';

class CityPackagesBloc extends Bloc<CityPackagesEvent, CityPackagesState> {
  final CityPackagesRepository _repository;
  StreamSubscription<double>? _downloadSubscription;

  CityPackagesBloc({required CityPackagesRepository repository})
      : _repository = repository,
        super(const CityPackagesInitial()) {
    on<LoadAvailableCities>(_onLoadAvailableCities);
    on<DownloadCityPackage>(_onDownloadCityPackage);
    on<DeleteCityPackage>(_onDeleteCityPackage);
    on<CheckForUpdates>(_onCheckForUpdates);
    on<_DownloadProgressUpdated>(_onDownloadProgressUpdated);
    on<CancelDownload>(_onCancelDownload);
  }

  Future<void> _onLoadAvailableCities(
    LoadAvailableCities event,
    Emitter<CityPackagesState> emit,
  ) async {
    emit(const CityPackagesLoading());
    try {
      final results = await Future.wait([
        _repository.fetchAvailableCities(),
        _repository.getDownloadedCities(),
      ]);

      final available = results[0];
      final downloaded = results[1];

      // Mark available cities that are already downloaded
      final downloadedIds = downloaded.map((c) => c.id).toSet();
      final mergedAvailable = available.map((city) {
        if (downloadedIds.contains(city.id)) {
          final local = downloaded.firstWhere((d) => d.id == city.id);
          return city.copyWith(
            isDownloaded: true,
            localVersion: local.version,
          );
        }
        return city;
      }).toList();

      emit(CityPackagesLoaded(
        available: mergedAvailable,
        downloaded: downloaded,
      ));
    } catch (e) {
      emit(CityPackageError(message: 'Failed to load cities: $e'));
    }
  }

  Future<void> _onDownloadCityPackage(
    DownloadCityPackage event,
    Emitter<CityPackagesState> emit,
  ) async {
    final currentState = state;
    List<CityPackage> available = [];
    List<CityPackage> downloaded = [];

    if (currentState is CityPackagesLoaded) {
      available = currentState.available;
      downloaded = currentState.downloaded;
    } else if (currentState is CityPackageDownloading) {
      available = currentState.available;
      downloaded = currentState.downloaded;
    }

    emit(CityPackageDownloading(
      cityId: event.cityId,
      progress: 0.0,
      available: available,
      downloaded: downloaded,
    ));

    try {
      final progressStream = _repository.downloadCityPackage(event.cityId);
      _downloadSubscription?.cancel();
      _downloadSubscription = progressStream.listen(
        (progress) {
          add(_DownloadProgressUpdated(event.cityId, progress));
        },
        onDone: () async {
          // Download complete — reload data
          add(const LoadAvailableCities());
        },
        onError: (error) {
          add(const LoadAvailableCities());
        },
      );
    } catch (e) {
      emit(CityPackageError(
        message: 'Failed to download: $e',
        available: available,
        downloaded: downloaded,
      ));
    }
  }

  void _onDownloadProgressUpdated(
    _DownloadProgressUpdated event,
    Emitter<CityPackagesState> emit,
  ) {
    final currentState = state;
    List<CityPackage> available = [];
    List<CityPackage> downloaded = [];

    if (currentState is CityPackageDownloading) {
      available = currentState.available;
      downloaded = currentState.downloaded;
    } else if (currentState is CityPackagesLoaded) {
      available = currentState.available;
      downloaded = currentState.downloaded;
    }

    emit(CityPackageDownloading(
      cityId: event.cityId,
      progress: event.progress,
      available: available,
      downloaded: downloaded,
    ));
  }

  Future<void> _onDeleteCityPackage(
    DeleteCityPackage event,
    Emitter<CityPackagesState> emit,
  ) async {
    try {
      await _repository.deleteCityPackage(event.cityId);
      add(const LoadAvailableCities());
    } catch (e) {
      final currentState = state;
      emit(CityPackageError(
        message: 'Failed to delete package: $e',
        available: currentState is CityPackagesLoaded
            ? currentState.available
            : const [],
        downloaded: currentState is CityPackagesLoaded
            ? currentState.downloaded
            : const [],
      ));
    }
  }

  Future<void> _onCheckForUpdates(
    CheckForUpdates event,
    Emitter<CityPackagesState> emit,
  ) async {
    try {
      final updates = await _repository.checkForUpdates();
      if (updates.isNotEmpty) {
        final currentState = state;
        if (currentState is CityPackagesLoaded) {
          // Mark packages with available updates
          final updatedAvailable = currentState.available.map((city) {
            final update = updates[city.id];
            if (update != null) {
              return city.copyWith(localVersion: city.version);
            }
            return city;
          }).toList();

          emit(currentState.copyWith(available: updatedAvailable));
        }
      }
    } catch (e) {
      // Silently fail on update check
    }
  }

  Future<void> _onCancelDownload(
    CancelDownload event,
    Emitter<CityPackagesState> emit,
  ) async {
    _downloadSubscription?.cancel();
    _downloadSubscription = null;
    add(const LoadAvailableCities());
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
