import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:waylo/features/groups/bloc/groups_bloc.dart';
import 'package:waylo/features/groups/bloc/groups_event.dart';
import 'package:waylo/features/groups/bloc/groups_state.dart';
import 'package:waylo/features/groups/screens/create_group_screen.dart';
import 'package:waylo/features/groups/screens/group_detail_screen.dart';
import 'package:waylo/features/groups/screens/join_group_screen.dart';
import 'package:waylo/features/groups/widgets/member_avatar.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroupsBloc>().add(const LoadUserGroups());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos de Viaje', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Unirse por código',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<GroupsBloc, GroupsState>(
        listener: (context, state) {
          if (state is GroupsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is GroupsLoading || state is GroupsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupsLoaded) {
            if (state.groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_takeoff_rounded, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no tienes grupos de viaje',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea un grupo para coordinar con amigos en tiempo real o únete con un código.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Primer Grupo'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GroupsBloc>().add(const LoadUserGroups());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.read<GroupsBloc>().add(SelectGroupEvent(group.id));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(group: group),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    group.destinationCity,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${formatter.format(group.startDate)} - ${formatter.format(group.endDate)}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    for (int i = 0; i < group.members.length && i < 4; i++)
                                      Transform.translate(
                                        offset: Offset(-8.0 * i, 0),
                                        child: MemberAvatar(member: group.members[i]),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${group.members.length}/${group.maxMembers} miembros',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Grupo'),
      ),
    );
  }
}
