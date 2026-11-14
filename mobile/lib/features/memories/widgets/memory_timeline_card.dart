import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waylo/core/models/memory_photo.dart';

class MemoryTimelineCard extends StatelessWidget {
  final MemoryPhoto photo;
  final VoidCallback? onTap;

  const MemoryTimelineCard({
    super.key,
    required this.photo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                photo.storageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              // Bottom gradient with photographer avatar and time
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeFormatter.format(photo.capturedAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (photo.latitude != null)
                        const Icon(Icons.location_on, size: 12, color: Colors.tealAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
