import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/features/geolocation/bloc/geolocation_bloc.dart';
import 'package:waylo/features/geolocation/screens/plan_b_screen.dart';
import 'package:waylo/features/geolocation/services/audio_player_service.dart';
import 'package:waylo/features/geolocation/widgets/audio_player_widget.dart';
import 'package:waylo/features/geolocation/widgets/nearby_poi_card.dart';
import 'package:waylo/features/geolocation/widgets/poi_marker.dart';
import 'package:waylo/features/geolocation/widgets/weather_badge.dart';

class GeolocationScreen extends StatefulWidget {
  final List<POI> initialPois;

  const GeolocationScreen({super.key, this.initialPois = const []});

  @override
  State<GeolocationScreen> createState() => _GeolocationScreenState();
}

class _GeolocationScreenState extends State<GeolocationScreen> {
  late final AudioPlayerService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioPlayerService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPois.isNotEmpty) {
        context.read<GeolocationBloc>().add(
              StartMonitoring(pois: widget.initialPois),
            );
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  void _showPlanBModal() {
    context.read<GeolocationBloc>().add(const RequestPlanB());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<GeolocationBloc>(),
        child: const PlanBScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía en Destino y Geofencing'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: WeatherBadge(condition: WeatherCondition.rainy),
          ),
        ],
      ),
      body: BlocConsumer<GeolocationBloc, GeolocationState>(
        listener: (context, state) {
          if (state is GeolocationMonitoring && state.currentAudio != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎧 Reproduciendo: ${state.currentAudio!.title}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final lat = state is GeolocationMonitoring ? state.currentLat : 53.4000;
          final lng = state is GeolocationMonitoring ? state.currentLng : -2.9800;
          final nearby = state is GeolocationMonitoring ? state.nearbyPOIs : <POI>[];
          final currentAudio = state is GeolocationMonitoring ? state.currentAudio : null;

          return Stack(
            children: [
              // Stylized Map Canvas
              Container(
                color: const Color(0xFFE8ECEF),
                child: Stack(
                  children: [
                    // Simulated Map Roads and Parks
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapCanvasPainter(),
                      ),
                    ),
                    // User Live Location (Pulsing Blue Dot)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade600,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Tu Ubicación',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // POI Marker Sample around user
                    Positioned(
                      top: 180,
                      left: 120,
                      child: PoiMarkerWidget(
                        poi: POI(
                          id: 'sample_poi_1',
                          cityId: 'liverpool_uk',
                          name: 'Royal Albert Dock',
                          description: '',
                          latitude: 53.3992,
                          longitude: -2.9917,
                          category: 'monument',
                        ),
                        isInGeofence: true,
                        onTap: () {
                          context.read<GeolocationBloc>().add(
                                POIProximityTriggered(
                                  poi: POI(
                                    id: 'sample_poi_1',
                                    cityId: 'liverpool_uk',
                                    name: 'Royal Albert Dock',
                                    description: '',
                                    latitude: 53.3992,
                                    longitude: -2.9917,
                                    category: 'monument',
                                  ),
                                ),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Audio Capsule Floating Player (if active)
              if (currentAudio != null)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: AudioPlayerWidget(
                    capsule: currentAudio,
                    audioService: _audioService,
                    onClose: () {
                      context.read<GeolocationBloc>().add(const AudioCapsuleCompleted());
                    },
                  ),
                ),

              // Draggable Bottom Sheet for Nearby POIs
              DraggableScrollableSheet(
                initialChildSize: 0.28,
                minChildSize: 0.12,
                maxChildSize: 0.65,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Atracciones Cercanas (<40m Geocerca)',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${nearby.length} detectadas',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        if (nearby.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Camina cerca de un monumento para activar la narración guiada automática.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...nearby.map((poi) {
                            return NearbyPoiCard(
                              poi: poi,
                              distanceMeters: 28,
                              onPlayAudio: () {
                                context.read<GeolocationBloc>().add(
                                      POIProximityTriggered(poi: poi),
                                    );
                              },
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPlanBModal,
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.umbrella_rounded),
        label: const Text('Plan B Instantáneo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final parkPaint = Paint()..color = const Color(0xFFD4E7D0);
    final waterPaint = Paint()..color = const Color(0xFFC4E0E5);
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0;

    // Draw water
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.35, size.height), waterPaint);
    // Draw park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, 80, 140, 140),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    // Roads
    canvas.drawLine(Offset(size.width * 0.35, 120), Offset(size.width, 120), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 300), Offset(size.width, 300), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
