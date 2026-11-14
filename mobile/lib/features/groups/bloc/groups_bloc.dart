import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waylo/features/groups/bloc/groups_event.dart';
import 'package:waylo/features/groups/bloc/groups_state.dart';
import 'package:waylo/features/groups/repositories/groups_repository.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GroupsRepository _repository;

  GroupsBloc({required GroupsRepository repository})
      : _repository = repository,
        super(const GroupsInitial()) {
    on<LoadUserGroups>(_onLoadUserGroups);
    on<CreateGroupEvent>(_onCreateGroup);
    on<JoinGroupEvent>(_onJoinGroup);
    on<SelectGroupEvent>(_onSelectGroup);
    on<AddItineraryItemEvent>(_onAddItineraryItem);
    on<UpdateItineraryItemStatusEvent>(_onUpdateItineraryItemStatus);
    on<RemoveItineraryItemEvent>(_onRemoveItineraryItem);
    on<ToggleLocationSharingEvent>(_onToggleLocationSharing);
    on<UpdateMyCoordinatesEvent>(_onUpdateMyCoordinates);
    on<RealtimeItineraryUpdatedEvent>(_onRealtimeItineraryUpdated);
    on<RealtimeMembersUpdatedEvent>(_onRealtimeMembersUpdated);
  }

  Future<void> _onLoadUserGroups(LoadUserGroups event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading());
    try {
      final groups = await _repository.getUserGroups();
      emit(GroupsLoaded(groups: groups));
    } catch (e) {
      emit(GroupsError('Error cargando grupos de viaje: ${e.toString()}'));
    }
  }

  Future<void> _onCreateGroup(CreateGroupEvent event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading());
    try {
      final group = await _repository.createGroup(
        name: event.name,
        destinationCity: event.destination,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      add(SelectGroupEvent(group.id));
    } catch (e) {
      emit(GroupsError('Error creando grupo: $e'));
    }
  }

  Future<void> _onJoinGroup(JoinGroupEvent event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading());
    try {
      final group = await _repository.joinGroupByCode(event.inviteCode);
      add(SelectGroupEvent(group.id));
    } catch (e) {
      emit(GroupsError('No se pudo unir al grupo: $e'));
    }
  }

  Future<void> _onSelectGroup(SelectGroupEvent event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading());
    try {
      final groups = await _repository.getUserGroups();
      final currentGroup = groups.firstWhere((g) => g.id == event.groupId);
      final members = await _repository.getGroupMembers(event.groupId);
      final itinerary = await _repository.getItineraryItems(event.groupId);

      // Start Realtime WebSockets subscription
      _repository.subscribeToGroup(
        event.groupId,
        onItineraryChanged: (items) => add(RealtimeItineraryUpdatedEvent(items)),
        onMembersChanged: (mems) => add(RealtimeMembersUpdatedEvent(mems)),
      );

      emit(GroupDetailLoaded(
        group: currentGroup,
        members: members,
        itinerary: itinerary,
        isSharingMyLocation: false,
      ));
    } catch (e) {
      emit(GroupsError('Error al seleccionar grupo: $e'));
    }
  }

  Future<void> _onAddItineraryItem(
      AddItineraryItemEvent event, Emitter<GroupsState> emit) async {
    try {
      await _repository.addItineraryItem(
        groupId: event.groupId,
        poiId: event.poiId,
        customTitle: event.customTitle,
        scheduledDate: event.scheduledDate,
        scheduledTime: event.scheduledTime,
        notes: event.notes,
      );
      final items = await _repository.getItineraryItems(event.groupId);
      final current = state;
      if (current is GroupDetailLoaded) {
        emit(current.copyWith(itinerary: items));
      }
    } catch (e) {
      emit(GroupsError('Error añadiendo parada: $e'));
    }
  }

  Future<void> _onUpdateItineraryItemStatus(
      UpdateItineraryItemStatusEvent event, Emitter<GroupsState> emit) async {
    final current = state;
    if (current is! GroupDetailLoaded) return;

    try {
      await _repository.updateItineraryStatus(event.itemId, event.status);
      final updated = current.itinerary.map((i) {
        if (i.id == event.itemId) {
          return i.copyWith(status: event.status);
        }
        return i;
      }).toList();
      emit(current.copyWith(itinerary: updated));
    } catch (_) {}
  }

  Future<void> _onRemoveItineraryItem(
      RemoveItineraryItemEvent event, Emitter<GroupsState> emit) async {
    final current = state;
    if (current is! GroupDetailLoaded) return;

    try {
      await _repository.removeItineraryItem(event.itemId);
      final updated = current.itinerary.where((i) => i.id != event.itemId).toList();
      emit(current.copyWith(itinerary: updated));
    } catch (_) {}
  }

  Future<void> _onToggleLocationSharing(
      ToggleLocationSharingEvent event, Emitter<GroupsState> emit) async {
    final current = state;
    if (current is! GroupDetailLoaded) return;

    await _repository.toggleLocationSharing(event.groupId, event.enabled);
    emit(current.copyWith(isSharingMyLocation: event.enabled));
  }

  Future<void> _onUpdateMyCoordinates(
      UpdateMyCoordinatesEvent event, Emitter<GroupsState> emit) async {
    await _repository.updateLocation(event.groupId, event.lat, event.lng);
  }

  void _onRealtimeItineraryUpdated(
      RealtimeItineraryUpdatedEvent event, Emitter<GroupsState> emit) {
    final current = state;
    if (current is GroupDetailLoaded) {
      emit(current.copyWith(itinerary: event.items));
    }
  }

  void _onRealtimeMembersUpdated(
      RealtimeMembersUpdatedEvent event, Emitter<GroupsState> emit) {
    final current = state;
    if (current is GroupDetailLoaded) {
      emit(current.copyWith(members: event.members));
    }
  }

  @override
  Future<void> close() {
    _repository.unsubscribe();
    return super.close();
  }
}
