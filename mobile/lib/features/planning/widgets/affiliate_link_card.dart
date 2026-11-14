import 'package:flutter/material.dart';
import 'package:waylo/core/models/affiliate_link.dart';
import 'package:waylo/core/utils/url_utils.dart';

class AffiliateLinkCard extends StatelessWidget {
  final AffiliateLink link;
  final VoidCallback? onBeforeLaunch;

  const AffiliateLinkCard({
    super.key,
    required this.link,
    this.onBeforeLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFlight = link.category == 'flight';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    isFlight ? Icons.flight_takeoff_rounded : Icons.hotel_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.provider,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (link.priceEstimate != null)
                        Text(
                          link.priceEstimate!,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Verificado',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (link.description != null) ...[
              const SizedBox(height: 12),
              Text(
                link.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('Reservar en ${link.provider}'),
                onPressed: () async {
                  onBeforeLaunch?.call();
                  await UrlUtils.launchExternalUrl(link.url);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
