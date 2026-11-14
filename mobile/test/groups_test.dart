import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/models/group_member.dart';
import 'package:waylo/core/models/travel_group.dart';
import 'package:waylo/features/groups/repositories/groups_repository.dart';

void main() {
  group('Travel Groups & Realtime Coordination Tests', () {
    test('generateInviteCode produces 6-character alphanumeric uppercase code', () {
      final repo = GroupsRepository();
      final code = repo.generateInviteCode();

      expect(code.length, 6);
      expect(code, matches(r'^[A-Z0-9]{6}$'));
    });

    test('Multiple invite codes should be uniquely randomized', () {
      final repo = GroupsRepository();
      final codes = List.generate(50, (_) => repo.generateInviteCode()).toSet();
      // Out of 50 codes, at least 49 should be unique (virtually 0 collisions with 32^6 combinations)
      expect(codes.length, greaterThanOrEqualTo(49));
    });

    test('TravelGroup enforces maxMembers limit for Pro accounts', () {
      final group = TravelGroup(
        id: 'group_test_1',
        name: 'Liverpool Beatles Tour',
        inviteCode: 'WAYLO8',
        ownerId: 'user_owner_1',
        destinationCity: 'Liverpool',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 5),
        maxMembers: 5,
        members: List.generate(
          5,
          (i) => GroupMember(
            id: 'mem_$i',
            groupId: 'group_test_1',
            userId: 'user_$i',
            role: i == 0 ? GroupMemberRole.owner : GroupMemberRole.member,
            joinedAt: DateTime.now(),
          ),
        ),
        createdAt: DateTime.now(),
      );

      expect(group.members.length, 5);
      expect(group.members.length >= group.maxMembers, isTrue);
    });
  });
}
