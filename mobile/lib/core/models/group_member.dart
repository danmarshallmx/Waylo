import 'package:equatable/equatable.dart';

import 'user_profile.dart';

/// Role of a member within a travel group.
enum GroupMemberRole {
  owner,
  admin,
  member;

  static GroupMemberRole fromString(String value) {
    return GroupMemberRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GroupMemberRole.member,
    );
  }
}

/// Represents a single member within a [TravelGroup].
class GroupMember extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final bool locationSharing;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastLocationAt;
  final DateTime joinedAt;
  final UserProfile? userProfile;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = GroupMemberRole.member,
    this.locationSharing = false,
    this.lastLat,
    this.lastLng,
    this.lastLocationAt,
    required this.joinedAt,
    this.userProfile,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: GroupMemberRole.fromString(json['role'] as String? ?? 'member'),
      locationSharing: json['location_sharing'] as bool? ?? false,
      lastLat: (json['last_lat'] as num?)?.toDouble(),
      lastLng: (json['last_lng'] as num?)?.toDouble(),
      lastLocationAt: json['last_location_at'] != null
          ? DateTime.parse(json['last_location_at'] as String)
          : null,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userProfile: json['user_profile'] != null
          ? UserProfile.fromJson(
              json['user_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.name,
      'location_sharing': locationSharing,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'last_location_at': lastLocationAt?.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      if (userProfile != null) 'user_profile': userProfile!.toJson(),
    };
  }

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    GroupMemberRole? role,
    bool? locationSharing,
    double? lastLat,
    double? lastLng,
    DateTime? lastLocationAt,
    DateTime? joinedAt,
    UserProfile? userProfile,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      locationSharing: locationSharing ?? this.locationSharing,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      joinedAt: joinedAt ?? this.joinedAt,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  /// Whether this member has a recent location (within the last 5 minutes).
  bool get hasRecentLocation {
    if (lastLocationAt == null || lastLat == null || lastLng == null) {
      return false;
    }
    return DateTime.now().difference(lastLocationAt!).inMinutes < 5;
  }

  /// Whether this member can manage the group (owner or admin).
  bool get canManage =>
      role == GroupMemberRole.owner || role == GroupMemberRole.admin;

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        role,
        locationSharing,
        lastLat,
        lastLng,
        lastLocationAt,
        joinedAt,
        userProfile,
      ];

  @override
  String toString() =>
      'GroupMember(id: $id, userId: $userId, role: ${role.name}, '
      'locationSharing: $locationSharing)';
}
