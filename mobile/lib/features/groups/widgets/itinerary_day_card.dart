import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waylo/core/models/itinerary_item.dart';

class ItineraryDayCard extends StatelessWidget {
  final DateTime date;
  final List<ItineraryItem> items;
  final void Function(String itemId, ItineraryStatus status)? onStatusChanged;
  final void Function(String itemId)? onDelete;

  const ItineraryDayCard({
    super.key,
    required this.date,
    required this.items,
    this.onStatusChanged,
    this.onDelete,
  });

  Color _getStatusColor(ItineraryStatus status) {
    switch (status) {
      case ItineraryStatus.completed:
        return Colors.green;
      case ItineraryStatus.inProgress:
        return Colors.blue;
      case ItineraryStatus.skipped:
        return Colors.grey;
      case ItineraryStatus.planned:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFormatter = DateFormat('EEEE, d MMMM', 'es');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayFormatter.format(date).toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} paradas',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin actividades planeadas aún para este día.',
                  style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              )
            else
              ...items.map((item) {
                final isDone = item.status == ItineraryStatus.completed;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? Colors.green.shade200 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          item.scheduledTime ?? '10:00',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.poi?.name ?? item.customTitle ?? 'Parada cultural',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                item.notes!,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<ItineraryStatus>(
                        icon: Icon(
                          Icons.circle,
                          size: 14,
                          color: _getStatusColor(item.status),
                        ),
                        onSelected: (status) => onStatusChanged?.call(item.id, status),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: ItineraryStatus.planned,
                            child: Text('Planeado'),
                          ),
                          const PopupMenuItem(
                            value: ItineraryStatus.inProgress,
                            child: Text('En Curso'),
                          ),
                          const PopupMenuItem(
                            value: ItineraryStatus.completed,
                            child: Text('Completado'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
