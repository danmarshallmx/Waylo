import 'package:equatable/equatable.dart';

abstract class CityPackagesEvent extends Equatable {
  const CityPackagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadAvailableCities extends CityPackagesEvent {
  const LoadAvailableCities();
}

class DownloadCityPackage extends CityPackagesEvent {
  final String cityId;

  const DownloadCityPackage(this.cityId);

  @override
  List<Object?> get props => [cityId];
}

class DeleteCityPackage extends CityPackagesEvent {
  final String cityId;

  const DeleteCityPackage(this.cityId);

  @override
  List<Object?> get props => [cityId];
}

class CheckForUpdates extends CityPackagesEvent {
  const CheckForUpdates();
}

class _DownloadProgressUpdated extends CityPackagesEvent {
  final String cityId;
  final double progress;

  const _DownloadProgressUpdated(this.cityId, this.progress);

  @override
  List<Object?> get props => [cityId, progress];
}

class CancelDownload extends CityPackagesEvent {
  final String cityId;

  const CancelDownload(this.cityId);

  @override
  List<Object?> get props => [cityId];
}
