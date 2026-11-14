import 'package:flutter/material.dart';
import 'package:waylo/features/geolocation/bloc/geolocation_bloc.dart';

class WeatherBadge extends StatelessWidget {
  final WeatherCondition condition;
  final double? temperature;

  const WeatherBadge({
    super.key,
    required this.condition,
    this.temperature,
  });

  IconData _getIcon() {
    switch (condition) {
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
        return Icons.water_drop_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.clear:
      case WeatherCondition.hot:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.snowy:
      case WeatherCondition.cold:
        return Icons.ac_unit_rounded;
      case WeatherCondition.unknown:
        return Icons.cloud_queue_rounded;
    }
  }

  Color _getColor() {
    switch (condition) {
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
        return Colors.blue;
      case WeatherCondition.clear:
      case WeatherCondition.hot:
        return Colors.amber.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 16, color: _getColor()),
          const SizedBox(width: 6),
          Text(
            condition.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }
}
