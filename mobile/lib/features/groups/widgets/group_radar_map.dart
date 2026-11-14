import 'package:flutter/material.dart';
import 'package:waylo/core/models/group_member.dart';

class GroupRadarMap extends StatelessWidget {
  final List<GroupMember> members;
  final bool isSharingMyLocation;
  final ValueChanged<bool>? onToggleSharing;

  const GroupRadarMap({
    super.key,
    required this.members,
    required this.isSharingMyLocation,
    this.onToggleSharing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharingMembers = members.where((m) => m.locationSharing && m.lastLat != null).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Radar Grupal en Tiempo Real',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Compartir mi ubicación:', style: TextStyle(fontSize: 11)),
                  Switch(
                    value: isSharingMyLocation,
                    onChanged: onToggleSharing,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Radar canvas
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar concentric circles
                for (double size in [60.0, 110.0, 160.0])
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.tealAccent.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                // Center pin
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.tealAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                // Render sharing members as pins
                if (sharingMembers.isEmpty)
                  const Text(
                    'Ningún miembro está compartiendo ubicación en este momento.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  )
                else
                  ...sharingMembers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final member = entry.value;
                    final offsets = [
                      const Offset(-40, -30),
                      const Offset(45, 20),
                      const Offset(-20, 50),
                      const Offset(50, -45),
                      const Offset(-55, 10),
                    ];
                    final offset = offsets[idx % offsets.length];

                    return Transform.translate(
                      offset: offset,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withOpacity(0.5),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: const Icon(Icons.person, size: 12, color: Colors.black87),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.userProfile?.displayName?.split(' ')[0] ?? 'Viajero',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${sharingMembers.length} de ${members.length} miembros activos en el radar. Privacidad individual respetada.',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
