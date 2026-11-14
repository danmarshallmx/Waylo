import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripDateSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onDatesChanged;

  const TripDateSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDatesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM yyyy', 'es');

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: DateTimeRange(start: startDate, end: endDate),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          onDatesChanged(picked.start, picked.end);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fechas del viaje',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatter.format(startDate)} — ${formatter.format(endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
