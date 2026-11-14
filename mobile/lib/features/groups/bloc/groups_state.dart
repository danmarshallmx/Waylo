import 'package:equatable/equatable.dart';
import 'package:waylo/core/models/group_member.dart';
import 'package:waylo/core/models/itinerary_item.dart';
import 'package:waylo/core/models/travel_group.dart';

abstract class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  final List<TravelGroup> groups;

  const GroupsLoaded({required this.groups});

  @override
  List<Object?> get props => [groups];
}

class GroupDetailLoaded extends GroupsState {
  final TravelGroup group;
  final List<GroupMember> members;
  final List<ItineraryItem> itinerary;
  final bool isSharingMyLocation;

  const GroupDetailLoaded({
    required this.group,
    required this.members,
    required this.itinerary,
    this.isSharingMyLocation = false,
  });

  @override
  List<Object?> get props => [group, members, itinerary, isSharingMyLocation];

  GroupDetailLoaded copyWith({
    TravelGroup? group,
    List<GroupMember>? members,
    List<ItineraryItem>? itinerary,
    bool? isSharingMyLocation,
  }) {
    return GroupDetailLoaded(
      group: group ?? this.group,
      members: members ?? this.members,
      itinerary: itinerary ?? this.itinerary,
      isSharingMyLocation: isSharingMyLocation ?? this.isSharingMyLocation,
    );
  }
}

class GroupsError extends GroupsState {
  final String message;

  const GroupsError(this.message);

  @override
  List<Object?> get props => [message];
}
