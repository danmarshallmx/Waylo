import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/core/data/default_pois.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final poisToMonitor = widget.initialPois.isNotEmpty
          ? widget.initialPois
          : defaultGuadalajaraPois;
      context.read<GeolocationBloc>().add(
            StartMonitoring(pois: poisToMonitor),
          );
    });
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
    final audioService = context.read<AudioPlayerService>();

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
                content: Row(
                  children: [
                    const Icon(Icons.headphones_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reproduciendo: ${state.currentAudio!.title}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final nearby =
              state is GeolocationMonitoring ? state.nearbyPOIs : <POI>[];
          final allPois = state is GeolocationMonitoring && state.allPOIs.isNotEmpty
              ? state.allPOIs
              : (widget.initialPois.isNotEmpty
                  ? widget.initialPois
                  : defaultGuadalajaraPois);
          final currentAudio =
              state is GeolocationMonitoring ? state.currentAudio : null;
          final isPlayingAudio =
              state is GeolocationMonitoring ? state.isPlayingAudio : false;

          return Stack(
            children: [
              // Stylized Map Canvas with Interactive Markers
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Tu Ubicación',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Render Markers on Map for each POI
                    ..._buildMapMarkers(context, allPois, nearby),
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
                    audioService: audioService,
                    onClose: () {
                      context
                          .read<GeolocationBloc>()
                          .add(const AudioCapsuleCompleted());
                    },
                  ),
                ),

              // Draggable Bottom Sheet for Audioguides Catalogue & Nearby POIs
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.15,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2))
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

                        // Header Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Audioguías y Geocercas',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${allPois.length} disponibles',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),

                        // Section 1: Nearby Geofence (<40m) if detected
                        if (nearby.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.near_me_rounded,
                                    color: Colors.green, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Cerca de ti (<40m Geocerca Activa)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...nearby.map((poi) {
                            return NearbyPoiCard(
                              poi: poi,
                              distanceMeters: 25,
                              onPlayAudio: () {
                                context.read<GeolocationBloc>().add(
                                      POIProximityTriggered(poi: poi),
                                    );
                              },
                            );
                          }),
                          const Divider(),
                        ],

                        // Section 2: Full Audioguides Catalogue
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.headphones_rounded,
                                      color: Colors.deepPurple, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Catálogo de Audioguías Offline',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Toca "Escuchar" para oír la narración guiada o "Simular" para probar la geocerca.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // List of all POI Audio Guides
                        ...allPois.map((poi) {
                          final isThisPlaying = isPlayingAudio &&
                              currentAudio != null &&
                              currentAudio.poiId == poi.id;

                          return _buildPoiAudioCard(
                            context: context,
                            poi: poi,
                            isPlaying: isThisPlaying,
                            audioService: audioService,
                          );
                        }),
                        const SizedBox(height: 70), // Bottom padding for FAB
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
        label: const Text('Plan B Instantáneo',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Builds a rich card for each POI with play controls and geofence simulation
  Widget _buildPoiAudioCard({
    required BuildContext context,
    required POI poi,
    required bool isPlaying,
    required AudioPlayerService audioService,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlaying ? theme.colorScheme.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying ? theme.colorScheme.primary : Colors.grey.shade200,
          width: isPlaying ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POI Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: poi.imageUrl != null
                      ? Image.network(
                          poi.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.place_rounded,
                                color: theme.colorScheme.primary),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.place_rounded,
                              color: theme.colorScheme.primary),
                        ),
                ),
                const SizedBox(width: 12),

                // POI Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              poi.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '• 45s offline',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (poi.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          poi.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Simulate Proximity Button (Tests Geofence on device)
                TextButton.icon(
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text('Simular Llegada', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    context.read<GeolocationBloc>().add(
                          LocationUpdated(
                            latitude: poi.latitude,
                            longitude: poi.longitude,
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Simulando llegada a ${poi.name} (<40m)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Play / Pause Audio Button
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isPlaying
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    foregroundColor: isPlaying
                        ? Colors.white
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isPlaying ? 'Pausar' : 'Escuchar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      audioService.pause();
                    } else {
                      context
                          .read<GeolocationBloc>()
                          .add(POIProximityTriggered(poi: poi));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds interactive markers spread across the stylized map
  List<Widget> _buildMapMarkers(
      BuildContext context, List<POI> pois, List<POI> nearby) {
    // Relative coordinates across the 2D canvas for visualization
    final markerPositions = [
      {'top': 120.0, 'left': 190.0},
      {'top': 170.0, 'left': 130.0},
      {'top': 160.0, 'left': 240.0},
      {'top': 230.0, 'left': 90.0},
      {'top': 100.0, 'left': 260.0},
      {'top': 260.0, 'left': 180.0},
      {'top': 80.0, 'left': 120.0},
    ];

    final widgets = <Widget>[];

    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final pos = markerPositions[i % markerPositions.length];
      final isInNearby = nearby.any((n) => n.id == poi.id);

      widgets.add(
        Positioned(
          top: pos['top'],
          left: pos['left'],
          child: Tooltip(
            message: '${poi.name} (${poi.category})',
            child: PoiMarkerWidget(
              poi: poi,
              isInGeofence: isInNearby,
              onTap: () {
                context.read<GeolocationBloc>().add(
                      POIProximityTriggered(poi: poi),
                    );
              },
            ),
          ),
        ),
      );
    }

    return widgets;
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
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * 0.35, size.height), waterPaint);
    // Draw park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, 80, 140, 140),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    // Roads
    canvas.drawLine(
        Offset(size.width * 0.35, 120), Offset(size.width, 120), roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.35, 300), Offset(size.width, 300), roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.6, 0), Offset(size.width, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
