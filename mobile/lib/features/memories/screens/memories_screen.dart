import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waylo/core/models/memory_photo.dart';
import 'package:waylo/features/memories/bloc/memories_bloc.dart';
import 'package:waylo/features/memories/bloc/memories_event.dart';
import 'package:waylo/features/memories/bloc/memories_state.dart';
import 'package:waylo/features/memories/screens/photo_detail_screen.dart';
import 'package:waylo/features/memories/widgets/day_header_widget.dart';
import 'package:waylo/features/memories/widgets/memory_timeline_card.dart';
import 'package:waylo/features/memories/widgets/poi_photo_section.dart';
import 'package:waylo/features/memories/widgets/upload_progress_widget.dart';

class MemoriesScreen extends StatefulWidget {
  final String groupId;

  const MemoriesScreen({super.key, required this.groupId});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<MemoriesBloc>().add(LoadGroupMemoriesEvent(widget.groupId));
  }

  Future<void> _pickAndUploadPhotos() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final paths = images.map((e) => e.path).toList();
      if (!mounted) return;
      context.read<MemoriesBloc>().add(
            UploadPhotosEvent(groupId: widget.groupId, filePaths: paths),
          );
    }
  }

  void _openDetail(MemoryPhoto photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MemoriesBloc>(),
          child: PhotoDetailScreen(photo: photo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bóveda de Recuerdos'),
        actions: [
          BlocBuilder<MemoriesBloc, MemoriesState>(
            builder: (context, state) {
              final isTimeline = state is MemoriesLoaded && state.viewMode == MemoryViewMode.timeline;
              return IconButton(
                icon: Icon(isTimeline ? Icons.grid_view_rounded : Icons.timeline_rounded),
                tooltip: isTimeline ? 'Ver por Atracción' : 'Ver por Timeline',
                onPressed: () {
                  context.read<MemoriesBloc>().add(const ToggleTimelineViewModeEvent());
                },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<MemoriesBloc, MemoriesState>(
        listener: (context, state) {
          if (state is MemoriesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is MemoriesLoading || state is MemoriesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MemoriesLoaded) {
            return Column(
              children: [
                // Realtime background upload progress widget
                UploadProgressWidget(progressMap: state.uploadProgress),

                Expanded(
                  child: state.allPhotos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aún no hay fotos en este viaje',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sube fotos grupales. Waylo extraerá el EXIF (GPS y hora) para ordenarlas automáticamente por atracción visitada.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _pickAndUploadPhotos,
                                  icon: const Icon(Icons.add_a_photo_rounded),
                                  label: const Text('Subir Primeras Fotos'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<MemoriesBloc>().add(LoadGroupMemoriesEvent(widget.groupId));
                          },
                          child: state.viewMode == MemoryViewMode.timeline
                              ? ListView(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  children: state.photosByDay.entries.map((entry) {
                                    final dayKey = entry.key;
                                    final photos = entry.value;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        DayHeaderWidget(dateString: dayKey, count: photos.length),
                                        SizedBox(
                                          height: 180,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            itemCount: photos.length,
                                            itemBuilder: (context, idx) {
                                              final photo = photos[idx];
                                              return MemoryTimelineCard(
                                                photo: photo,
                                                onTap: () => _openDetail(photo),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }).toList(),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  children: state.photosByPoi.entries.map((entry) {
                                    return PoiPhotoSection(
                                      poiName: entry.key == 'General' ? 'Fotos Generales / En Tránsito' : entry.key,
                                      photos: entry.value,
                                      onPhotoTap: _openDetail,
                                    );
                                  }).toList(),
                                ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadPhotos,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Subir Fotos'),
      ),
    );
  }
}
