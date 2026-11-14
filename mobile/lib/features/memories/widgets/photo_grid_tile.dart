import 'package:flutter/material.dart';
import 'package:waylo/core/models/memory_photo.dart';

class PhotoGridTile extends StatelessWidget {
  final MemoryPhoto photo;
  final VoidCallback? onTap;

  const PhotoGridTile({
    super.key,
    required this.photo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.thumbnailUrl ?? photo.storageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            if (photo.poiId != null)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.place, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
