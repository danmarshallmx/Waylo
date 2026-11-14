import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:waylo/features/city_packages/bloc/city_packages_bloc.dart';
import 'package:waylo/features/city_packages/bloc/city_packages_event.dart';
import 'package:waylo/features/city_packages/bloc/city_packages_state.dart';
import 'package:waylo/features/city_packages/widgets/city_card.dart';

class CityPackagesScreen extends StatelessWidget {
  const CityPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destinos y Paquetes Offline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Buscar actualizaciones',
            onPressed: () {
              context.read<CityPackagesBloc>().add(const CheckForUpdates());
            },
          ),
        ],
      ),
      body: BlocConsumer<CityPackagesBloc, CityPackagesState>(
        listener: (context, state) {
          if (state is CityPackageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CityPackagesLoading || state is CityPackagesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final available = state is CityPackagesLoaded
              ? state.available
              : state is CityPackageDownloading
                  ? state.available
                  : [];

          final downloaded = state is CityPackagesLoaded
              ? state.downloaded
              : state is CityPackageDownloading
                  ? state.downloaded
                  : [];

          final downloadingCityId =
              state is CityPackageDownloading ? state.cityId : null;
          final progress =
              state is CityPackageDownloading ? state.progress : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CityPackagesBloc>().add(const LoadAvailableCities());
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (downloaded.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.offline_pin_rounded, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Descargados para uso Offline (${downloaded.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...downloaded.map((city) {
                    final isDown = downloadingCityId == city.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CityCard(
                        city: city,
                        isDownloading: isDown,
                        downloadProgress: isDown ? progress : 1.0,
                        onDelete: () {
                          context
                              .read<CityPackagesBloc>()
                              .add(DeleteCityPackage(city.id));
                        },
                      ),
                    );
                  }),
                  const Divider(height: 32),
                ],
                Row(
                  children: [
                    const Icon(Icons.cloud_download_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Ciudades Disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...available.map((city) {
                  final isDown = downloadingCityId == city.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CityCard(
                      city: city,
                      isDownloading: isDown,
                      downloadProgress: isDown ? progress : 0.0,
                      onDownload: () {
                        context
                            .read<CityPackagesBloc>()
                            .add(DownloadCityPackage(city.id));
                      },
                      onCancelDownload: isDown
                          ? () {
                              context
                                  .read<CityPackagesBloc>()
                                  .add(CancelDownload(city.id));
                            }
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
