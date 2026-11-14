import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/core/models/group_member.dart';
import 'package:waylo/core/models/itinerary_item.dart';
import 'package:waylo/core/models/travel_group.dart';
import 'package:waylo/features/groups/bloc/groups_bloc.dart';
import 'package:waylo/features/groups/bloc/groups_event.dart';
import 'package:waylo/features/groups/bloc/groups_state.dart';
import 'package:waylo/features/groups/widgets/group_radar_map.dart';
import 'package:waylo/features/groups/widgets/invite_code_widget.dart';
import 'package:waylo/features/groups/widgets/itinerary_day_card.dart';
import 'package:waylo/features/groups/widgets/member_avatar.dart';

class GroupDetailScreen extends StatefulWidget {
  final TravelGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItineraryModal() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = widget.group.startDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Añadir Parada al Itinerario Maestro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la atracción o actividad',
                hintText: 'Ej. Royal Albert Dock',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas o consejos para el grupo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  context.read<GroupsBloc>().add(
                        AddItineraryItemEvent(
                          groupId: widget.group.id,
                          customTitle: titleController.text.trim(),
                          scheduledDate: selectedDate,
                          notes: notesController.text.trim(),
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Añadir y Sincronizar en Tiempo Real'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_note_rounded), text: 'Itinerario'),
            Tab(icon: Icon(Icons.radar_rounded), text: 'Radar'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Miembros'),
          ],
        ),
      ),
      body: BlocBuilder<GroupsBloc, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = state is GroupDetailLoaded ? state.members : widget.group.members;
          final itinerary = state is GroupDetailLoaded ? state.itinerary : <ItineraryItem>[];
          final isSharing = state is GroupDetailLoaded ? state.isSharingMyLocation : false;

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Itinerary Tab
              ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 80),
                children: [
                  ItineraryDayCard(
                    date: widget.group.startDate,
                    items: itinerary,
                    onStatusChanged: (itemId, status) {
                      context.read<GroupsBloc>().add(
                            UpdateItineraryItemStatusEvent(itemId: itemId, status: status),
                          );
                    },
                    onDelete: (itemId) {
                      context.read<GroupsBloc>().add(RemoveItineraryItemEvent(itemId));
                    },
                  ),
                ],
              ),

              // 2. Radar Tab
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  GroupRadarMap(
                    members: members,
                    isSharingMyLocation: isSharing,
                    onToggleSharing: (val) {
                      context.read<GroupsBloc>().add(
                            ToggleLocationSharingEvent(groupId: widget.group.id, enabled: val),
                          );
                    },
                  ),
                ],
              ),

              // 3. Members Tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InviteCodeWidget(
                    inviteCode: widget.group.inviteCode,
                    groupName: widget.group.name,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Miembros del Viaje (${members.length}/${widget.group.maxMembers})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...members.map((member) {
                    final profile = member.userProfile;
                    final isOwner = member.role == GroupMemberRole.owner;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: MemberAvatar(member: member),
                      title: Text(profile?.displayName ?? 'Viajero'),
                      subtitle: Text(
                        member.locationSharing
                            ? '🟢 Compartiendo ubicación'
                            : '⚪ Ubicación privada',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOwner ? Colors.amber.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOwner ? 'ORGANIZADOR' : 'MIEMBRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? Colors.amber.shade900 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItineraryModal,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Añadir Parada'),
      ),
    );
  }
}
