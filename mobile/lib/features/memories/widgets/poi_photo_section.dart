import 'package:flutter/material.dart';
import 'package:waylo/core/models/memory_photo.dart';
import 'package:waylo/features/memories/widgets/photo_grid_tile.dart';

class PoiPhotoSection extends StatelessWidget {
  final String poiName;
  final List<MemoryPhoto> photos;
  final void Function(MemoryPhoto photo)? onPhotoTap;

  const PoiPhotoSection({
    super.key,
    required this.poiName,
    required this.photos,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.place_rounded, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poiName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                '${photos.length} fotos',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return PhotoGridTile(
              photo: photo,
              onTap: () => onPhotoTap?.call(photo),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
