import 'package:flutter/material.dart';
import 'package:waylo/core/models/group_member.dart';

class MemberAvatar extends StatelessWidget {
  final GroupMember member;
  final double radius;
  final bool showOnlineIndicator;

  const MemberAvatar({
    super.key,
    required this.member,
    this.radius = 18,
    this.showOnlineIndicator = true,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = member.userProfile;
    final name = profile?.displayName ?? 'Viajero';
    final isOwner = member.role == GroupMemberRole.owner;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: isOwner ? Colors.amber.shade700 : theme.colorScheme.primary,
          backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
          child: profile?.avatarUrl == null
              ? Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        if (showOnlineIndicator && member.locationSharing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
