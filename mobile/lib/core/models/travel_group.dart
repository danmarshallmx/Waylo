import 'package:equatable/equatable.dart';

import 'group_member.dart';

/// Represents a collaborative travel group.
class TravelGroup extends Equatable {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final String destinationCity;
  final DateTime startDate;
  final DateTime endDate;
  final int maxMembers;
  final List<GroupMember> members;
  final DateTime createdAt;

  const TravelGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.destinationCity,
    required this.startDate,
    required this.endDate,
    this.maxMembers = 10,
    this.members = const [],
    required this.createdAt,
  });

  factory TravelGroup.fromJson(Map<String, dynamic> json) {
    return TravelGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      ownerId: json['owner_id'] as String,
      destinationCity: json['destination_city'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      maxMembers: json['max_members'] as int? ?? 10,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  GroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'owner_id': ownerId,
      'destination_city': destinationCity,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'max_members': maxMembers,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TravelGroup copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? ownerId,
    String? destinationCity,
    DateTime? startDate,
    DateTime? endDate,
    int? maxMembers,
    List<GroupMember>? members,
    DateTime? createdAt,
  }) {
    return TravelGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      destinationCity: destinationCity ?? this.destinationCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxMembers: maxMembers ?? this.maxMembers,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether the group has capacity for more members.
  bool get hasCapacity => members.length < maxMembers;

  /// Number of days in the trip.
  int get tripDays => endDate.difference(startDate).inDays;

  @override
  List<Object?> get props => [
        id,
        name,
        inviteCode,
        ownerId,
        destinationCity,
        startDate,
        endDate,
        maxMembers,
        members,
        createdAt,
      ];

  @override
  String toString() =>
      'TravelGroup(id: $id, name: $name, destination: $destinationCity, '
      'members: ${members.length}/$maxMembers)';
}
