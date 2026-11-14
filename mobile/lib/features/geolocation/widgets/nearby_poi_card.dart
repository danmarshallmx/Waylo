import 'package:flutter/material.dart';
import 'package:waylo/core/models/poi.dart';

class NearbyPoiCard extends StatelessWidget {
  final POI poi;
  final double distanceMeters;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onTap;

  const NearbyPoiCard({
    super.key,
    required this.poi,
    required this.distanceMeters,
    this.onPlayAudio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: poi.imageUrl != null
                  ? Image.network(
                      poi.imageUrl!,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 55,
                        height: 55,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.location_on, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.location_on, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          poi.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'a ${distanceMeters.toStringAsFixed(0)} m',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onPlayAudio != null)
              IconButton.filledTonal(
                icon: const Icon(Icons.play_arrow_rounded),
                onPressed: onPlayAudio,
                tooltip: 'Escuchar audio cápsula',
              ),
          ],
        ),
      ),
    );
  }
}
