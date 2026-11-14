import 'package:equatable/equatable.dart';
import 'package:waylo/core/models/group_member.dart';
import 'package:waylo/core/models/itinerary_item.dart';

abstract class GroupsEvent extends Equatable {
  const GroupsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserGroups extends GroupsEvent {
  const LoadUserGroups();
}

class CreateGroupEvent extends GroupsEvent {
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  const CreateGroupEvent({
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [name, destination, startDate, endDate];
}

class JoinGroupEvent extends GroupsEvent {
  final String inviteCode;

  const JoinGroupEvent(this.inviteCode);

  @override
  List<Object?> get props => [inviteCode];
}

class SelectGroupEvent extends GroupsEvent {
  final String groupId;

  const SelectGroupEvent(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class AddItineraryItemEvent extends GroupsEvent {
  final String groupId;
  final String? poiId;
  final String? customTitle;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String? notes;

  const AddItineraryItemEvent({
    required this.groupId,
    this.poiId,
    this.customTitle,
    required this.scheduledDate,
    this.scheduledTime,
    this.notes,
  });

  @override
  List<Object?> get props => [groupId, poiId, customTitle, scheduledDate, scheduledTime, notes];
}

class UpdateItineraryItemStatusEvent extends GroupsEvent {
  final String itemId;
  final ItineraryStatus status;

  const UpdateItineraryItemStatusEvent({required this.itemId, required this.status});

  @override
  List<Object?> get props => [itemId, status];
}

class RemoveItineraryItemEvent extends GroupsEvent {
  final String itemId;

  const RemoveItineraryItemEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ToggleLocationSharingEvent extends GroupsEvent {
  final String groupId;
  final bool enabled;

  const ToggleLocationSharingEvent({required this.groupId, required this.enabled});

  @override
  List<Object?> get props => [groupId, enabled];
}

class UpdateMyCoordinatesEvent extends GroupsEvent {
  final String groupId;
  final double lat;
  final double lng;

  const UpdateMyCoordinatesEvent({
    required this.groupId,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [groupId, lat, lng];
}

class RealtimeItineraryUpdatedEvent extends GroupsEvent {
  final List<ItineraryItem> items;

  const RealtimeItineraryUpdatedEvent(this.items);

  @override
  List<Object?> get props => [items];
}

class RealtimeMembersUpdatedEvent extends GroupsEvent {
  final List<GroupMember> members;

  const RealtimeMembersUpdatedEvent(this.members);

  @override
  List<Object?> get props => [members];
}
