import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/features/planning/bloc/planning_bloc.dart';
import 'package:waylo/features/planning/bloc/planning_event.dart';
import 'package:waylo/features/planning/bloc/planning_state.dart';
import 'package:waylo/features/planning/widgets/affiliate_link_card.dart';
import 'package:waylo/features/planning/widgets/hotel_zone_map.dart';
import 'package:waylo/features/planning/widgets/trip_date_selector.dart';

class PlanningScreen extends StatefulWidget {
  final String? initialDestination;

  const PlanningScreen({super.key, this.initialDestination});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late final TextEditingController _destController;
  late final TextEditingController _originController;
  late DateTime _startDate;
  late DateTime _endDate;
  int _travelers = 2;

  @override
  void initState() {
    super.initState();
    _destController = TextEditingController(text: widget.initialDestination ?? 'Liverpool');
    _originController = TextEditingController(text: 'Madrid');
    _startDate = DateTime.now().add(const Duration(days: 30));
    _endDate = DateTime.now().add(const Duration(days: 35));

    // Trigger initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeSearch();
    });
  }

  void _executeSearch() {
    if (_destController.text.trim().isEmpty) return;

    context.read<PlanningBloc>().add(
          SetTripDetails(
            destination: _destController.text.trim(),
            departureCity: _originController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            travelers: _travelers,
          ),
        );
  }

  @override
  void dispose() {
    _destController.dispose();
    _originController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planeación Inteligente', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          BlocBuilder<PlanningBloc, PlanningState>(
            builder: (context, state) {
              if (state is PlanningLoaded) {
                return IconButton(
                  icon: Icon(
                    state.isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                    color: state.isSaved ? Colors.amber : null,
                  ),
                  tooltip: 'Guardar búsqueda',
                  onPressed: () {
                    context.read<PlanningBloc>().add(const SaveSearchEvent());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Búsqueda guardada con éxito')),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search form card
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad de origen',
                        prefixIcon: Icon(Icons.flight_takeoff_rounded),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destController,
                      decoration: const InputDecoration(
                        labelText: 'Destino (ej. Liverpool, Barcelona)',
                        prefixIcon: Icon(Icons.location_city_rounded),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TripDateSelector(
                      startDate: _startDate,
                      endDate: _endDate,
                      onDatesChanged: (start, end) {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Viajeros:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _travelers > 1 ? () => setState(() => _travelers--) : null,
                            ),
                            Text('$_travelers', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: _travelers < 10 ? () => setState(() => _travelers++) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Calcular Rutas y Zona Óptima', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _executeSearch,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results Section
            BlocBuilder<PlanningBloc, PlanningState>(
              builder: (context, state) {
                if (state is PlanningLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Calculando centroide ponderado de atracciones...'),
                        ],
                      ),
                    ),
                  );
                }

                if (state is PlanningError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                }

                if (state is PlanningLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel Centroid Map
                      HotelZoneMapWidget(
                        centroid: state.centroid,
                        radiusKm: state.recommendedRadiusKm,
                        pois: state.cityPois,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Enlaces Inteligentes de Afiliados (Deep Links)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tarifas y disponibilidad en tiempo real con parámetros de grupo Waylo',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      ...state.affiliateLinks.map(
                        (link) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AffiliateLinkCard(
                            link: link,
                            onBeforeLaunch: () {
                              context.read<PlanningBloc>().add(
                                    TrackAffiliateClick(
                                      provider: link.provider,
                                      category: link.category,
                                      url: link.url,
                                    ),
                                  );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
