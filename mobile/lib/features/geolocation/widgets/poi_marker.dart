import 'package:flutter/material.dart';
import 'package:waylo/core/models/poi.dart';

class PoiMarkerWidget extends StatelessWidget {
  final POI poi;
  final bool isInGeofence;
  final VoidCallback? onTap;

  const PoiMarkerWidget({
    super.key,
    required this.poi,
    this.isInGeofence = false,
    this.onTap,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'museum':
        return Colors.purple;
      case 'park':
        return Colors.green;
      case 'restaurant':
        return Colors.orange;
      case 'monument':
        return Colors.blue;
      case 'church':
        return Colors.brown;
      case 'market':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'museum':
        return Icons.museum_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'monument':
        return Icons.account_balance_rounded;
      case 'church':
        return Icons.church_rounded;
      case 'market':
        return Icons.storefront_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(poi.category);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInGeofence)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.25),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(poi.category),
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
