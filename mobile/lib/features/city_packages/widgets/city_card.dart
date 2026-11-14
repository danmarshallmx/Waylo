import 'package:flutter/material.dart';

import 'package:waylo/core/models/city_package.dart';
import 'package:waylo/features/city_packages/widgets/download_progress_indicator.dart';

class CityCard extends StatelessWidget {
  final CityPackage city;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onCancelDownload;
  final VoidCallback? onUpdate;

  const CityCard({
    super.key,
    required this.city,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.onDownload,
    this.onDelete,
    this.onCancelDownload,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // City image with overlay
          Stack(
            children: [
              // City image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  city.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.primaryContainer,
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          size: 48,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Download progress overlay
              if (isDownloading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: DownloadProgressIndicator(
                        progress: downloadProgress,
                        onCancel: onCancelDownload,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              // Version badge
              if (city.hasUpdate)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Update available',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Downloaded badge
              if (city.isDownloaded && !city.hasUpdate)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Downloaded',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Country tag
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    city.country,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // City info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and action
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(context),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                if (city.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      city.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Metadata row
                Row(
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.storage_rounded,
                      '${city.sizeMb.toStringAsFixed(1)} MB',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.place,
                      '${city.poiCount} POIs',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.headphones,
                      '${city.audioCapsuleCount} audios',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);

    if (isDownloading) {
      return const SizedBox.shrink();
    }

    if (city.hasUpdate) {
      return FilledButton.icon(
        onPressed: onUpdate ?? onDownload,
        icon: const Icon(Icons.system_update_alt, size: 18),
        label: const Text('Update'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelMedium,
        ),
      );
    }

    if (city.isDownloaded) {
      return OutlinedButton.icon(
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
        label: Text(
          'Remove',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: theme.textTheme.labelMedium,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Download'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: theme.textTheme.labelMedium,
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
