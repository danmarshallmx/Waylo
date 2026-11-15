import 'package:equatable/equatable.dart';

import 'poi.dart';

/// Status of an itinerary item within a group's plan.
enum ItineraryStatus {
  planned,
  inProgress,
  completed,
  skipped;

  static ItineraryStatus fromString(String value) {
    switch (value) {
      case 'planned':
        return ItineraryStatus.planned;
      case 'in_progress':
        return ItineraryStatus.inProgress;
      case 'completed':
        return ItineraryStatus.completed;
      case 'skipped':
        return ItineraryStatus.skipped;
      default:
        return ItineraryStatus.planned;
    }
  }

  String toJsonString() {
    switch (this) {
      case ItineraryStatus.planned:
        return 'planned';
      case ItineraryStatus.inProgress:
        return 'in_progress';
      case ItineraryStatus.completed:
        return 'completed';
      case ItineraryStatus.skipped:
        return 'skipped';
    }
  }
}

/// Represents a single stop/activity in a group's travel itinerary.
class ItineraryItem extends Equatable {
  final String id;
  final String groupId;
  final String poiId;
  final String addedBy;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final int durationMinutes;
  final String? customTitle;
  final ItineraryStatus status;
  final String? notes;
  final int sortOrder;
  final DateTime updatedAt;

  /// Optional joined POI data.
  final POI? poi;

  const ItineraryItem({
    required this.id,
    required this.groupId,
    required this.poiId,
    required this.addedBy,
    required this.scheduledDate,
    this.scheduledTime,
    this.customTitle,
    this.durationMinutes = 60,
    this.status = ItineraryStatus.planned,
    this.notes,
    this.sortOrder = 0,
    required this.updatedAt,
    this.poi,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      poiId: json['poi_id'] as String,
      addedBy: json['added_by'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      customTitle: json['custom_title'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      status: ItineraryStatus.fromString(
          json['status'] as String? ?? 'planned'),
      notes: json['notes'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      poi: json['poi'] != null
          ? POI.fromJson(json['poi'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'poi_id': poiId,
      'added_by': addedBy,
      'scheduled_date': scheduledDate.toIso8601String().split('T').first,
      'scheduled_time': scheduledTime,
      'custom_title': customTitle,
      'duration_minutes': durationMinutes,
      'status': status.toJsonString(),
      'notes': notes,
      'sort_order': sortOrder,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ItineraryItem copyWith({
    String? id,
    String? groupId,
    String? poiId,
    String? addedBy,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? customTitle,
    int? durationMinutes,
    ItineraryStatus? status,
    String? notes,
    int? sortOrder,
    DateTime? updatedAt,
    POI? poi,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      poiId: poiId ?? this.poiId,
      addedBy: addedBy ?? this.addedBy,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      customTitle: customTitle ?? this.customTitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      poi: poi ?? this.poi,
    );
  }

  /// Whether this item is actionable (not yet completed or skipped).
  bool get isActionable =>
      status == ItineraryStatus.planned ||
      status == ItineraryStatus.inProgress;

  @override
  List<Object?> get props => [
        id,
        groupId,
        poiId,
        addedBy,
        scheduledDate,
        scheduledTime,
        customTitle,
        durationMinutes,
        status,
        notes,
        sortOrder,
        updatedAt,
        poi,
      ];

  @override
  String toString() =>
      'ItineraryItem(id: $id, poi: $poiId, date: $scheduledDate, '
      'status: ${status.name})';
}
