import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayHeaderWidget extends StatelessWidget {
  final String dateString;
  final int count;

  const DayHeaderWidget({
    super.key,
    required this.dateString,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    DateTime date;
    try {
      date = DateTime.parse(dateString);
    } catch (_) {
      date = DateTime.now();
    }

    final dayFormatter = DateFormat('EEEE, d MMMM', 'es');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dayFormatter.format(date).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          Text(
            '$count fotos del grupo',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
