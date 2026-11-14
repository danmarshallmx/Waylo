import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waylo/core/models/memory_photo.dart';
import 'package:waylo/features/memories/bloc/memories_bloc.dart';
import 'package:waylo/features/memories/bloc/memories_event.dart';

class PhotoDetailScreen extends StatefulWidget {
  final MemoryPhoto photo;

  const PhotoDetailScreen({super.key, required this.photo});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late final TextEditingController _captionController;
  bool _isEditingCaption = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.photo.caption ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm:ss UTC');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.photo.poiId ?? 'Recuerdo del Viaje',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              context.read<MemoriesBloc>().add(DeletePhotoEvent(widget.photo.id));
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.photo.storageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateTimeFormatter.format(widget.photo.capturedAt),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (widget.photo.latitude != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'GPS: ${widget.photo.latitude!.toStringAsFixed(4)}, ${widget.photo.longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isEditingCaption)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Añade una descripción...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          context.read<MemoriesBloc>().add(
                                UpdatePhotoCaptionEvent(
                                  photoId: widget.photo.id,
                                  caption: _captionController.text.trim(),
                                ),
                              );
                          setState(() => _isEditingCaption = false);
                        },
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isEditingCaption = true),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.photo.caption?.isNotEmpty == true
                                ? widget.photo.caption!
                                : 'Toca aquí para añadir un pie de foto...',
                            style: TextStyle(
                              color: widget.photo.caption?.isNotEmpty == true
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
