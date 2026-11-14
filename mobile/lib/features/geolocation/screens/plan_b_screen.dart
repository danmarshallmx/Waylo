import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/features/geolocation/bloc/geolocation_bloc.dart';
import 'package:waylo/features/geolocation/widgets/nearby_poi_card.dart';

class PlanBScreen extends StatelessWidget {
  const PlanBScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: BlocBuilder<GeolocationBloc, GeolocationState>(
        builder: (context, state) {
          if (state is GeolocationPlanBLoading) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analizando clima y calculando Plan B instantáneo...'),
                  ],
                ),
              ),
            );
          }

          if (state is GeolocationPlanBLoaded) {
            final isRain = state.weatherCondition == WeatherCondition.rainy ||
                state.weatherCondition == WeatherCondition.stormy;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRain ? Colors.blue.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isRain ? Icons.umbrella_rounded : Icons.wb_sunny_rounded,
                          color: isRain ? Colors.blue : Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Plan B Instantáneo Waylo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              isRain
                                  ? 'Lluvia detectada: alternativas bajo techo'
                                  : 'Alternativas optimizadas según el clima',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Lugares recomendados a poca distancia a pie:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                if (state.alternatives.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No hay alternativas directas en este radio.')),
                  )
                else
                  ...state.alternatives.map((poi) {
                    return NearbyPoiCard(
                      poi: poi,
                      distanceMeters: 180, // estimated
                      onPlayAudio: () {
                        Navigator.pop(context);
                        context.read<GeolocationBloc>().add(
                              POIProximityTriggered(poi: poi),
                            );
                      },
                      onTap: () {
                        Navigator.pop(context);
                      },
                    );
                  }),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
