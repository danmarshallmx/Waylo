import 'package:equatable/equatable.dart';

import 'package:waylo/core/models/city_package.dart';

abstract class CityPackagesState extends Equatable {
  const CityPackagesState();

  @override
  List<Object?> get props => [];
}

class CityPackagesInitial extends CityPackagesState {
  const CityPackagesInitial();
}

class CityPackagesLoading extends CityPackagesState {
  const CityPackagesLoading();
}

class CityPackagesLoaded extends CityPackagesState {
  final List<CityPackage> available;
  final List<CityPackage> downloaded;

  const CityPackagesLoaded({
    required this.available,
    required this.downloaded,
  });

  @override
  List<Object?> get props => [available, downloaded];

  CityPackagesLoaded copyWith({
    List<CityPackage>? available,
    List<CityPackage>? downloaded,
  }) {
    return CityPackagesLoaded(
      available: available ?? this.available,
      downloaded: downloaded ?? this.downloaded,
    );
  }
}

class CityPackageDownloading extends CityPackagesState {
  final String cityId;
  final double progress;
  final List<CityPackage> available;
  final List<CityPackage> downloaded;

  const CityPackageDownloading({
    required this.cityId,
    required this.progress,
    required this.available,
    required this.downloaded,
  });

  @override
  List<Object?> get props => [cityId, progress, available, downloaded];
}

class CityPackageError extends CityPackagesState {
  final String message;
  final List<CityPackage> available;
  final List<CityPackage> downloaded;

  const CityPackageError({
    required this.message,
    this.available = const [],
    this.downloaded = const [],
  });

  @override
  List<Object?> get props => [message, available, downloaded];
}
