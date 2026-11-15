import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waylo/core/models/group_member.dart';
import 'package:waylo/core/models/itinerary_item.dart';
import 'package:waylo/core/models/travel_group.dart';

class GroupsRepository {
  final SupabaseClient _supabase;
  RealtimeChannel? _itineraryChannel;
  RealtimeChannel? _membersChannel;

  GroupsRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  static final List<TravelGroup> _defaultGroups = [
    TravelGroup(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Ruta Tequila & Tradición',
      inviteCode: 'WAY9X2',
      ownerId: '00000000-0000-0000-0000-000000000001',
      destinationCity: 'Guadalajara',
      startDate: DateTime(2026, 11, 20),
      endDate: DateTime(2026, 11, 25),
      maxMembers: 5,
      members: const [],
      createdAt: DateTime(2026, 11, 14),
    ),
  ];

  Future<List<TravelGroup>> getUserGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .from('travel_groups')
            .select('*, group_members(*, profiles(*))')
            .order('created_at', ascending: false);

        final list = (response as List).map((json) => TravelGroup.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return _defaultGroups;
  }

  Future<TravelGroup> createGroup({
    required String name,
    required String destinationCity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    var userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      try {
        final authRes = await _supabase.auth.signInAnonymously();
        userId = authRes.user?.id;
      } catch (_) {
        userId = '00000000-0000-0000-0000-000000000001';
      }
    }

    final inviteCode = generateInviteCode();

    final groupRes = await _supabase
        .from('travel_groups')
        .insert({
          'name': name,
          'invite_code': inviteCode,
          'owner_id': userId,
          'destination_city': destinationCity,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'max_members': 5,
        })
        .select()
        .single();

    final group = TravelGroup.fromJson(groupRes);

    // Auto-join owner as first member
    await _supabase.from('group_members').insert({
      'group_id': group.id,
      'user_id': userId,
      'role': 'owner',
      'location_sharing': true,
    });

    return group;
  }

  Future<TravelGroup> joinGroupByCode(String code) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final groupRes = await _supabase
        .from('travel_groups')
        .select('*, group_members(*)')
        .eq('invite_code', code.trim().toUpperCase())
        .single();

    final group = TravelGroup.fromJson(groupRes);

    if (group.members.length >= group.maxMembers) {
      throw Exception('El grupo ha alcanzado el límite máximo de miembros (5).');
    }

    final isAlreadyMember = group.members.any((m) => m.userId == userId);
    if (!isAlreadyMember) {
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'member',
        'location_sharing': false,
      });
    }

    return group;
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select('*, profiles(*)')
        .eq('group_id', groupId);

    return (response as List).map((json) => GroupMember.fromJson(json)).toList();
  }

  Future<List<ItineraryItem>> getItineraryItems(String groupId) async {
    final response = await _supabase
        .from('itinerary_items')
        .select('*')
        .eq('group_id', groupId)
        .order('scheduled_date', ascending: true)
        .order('sort_order', ascending: true);

    return (response as List).map((json) => ItineraryItem.fromJson(json)).toList();
  }

  Future<void> addItineraryItem({
    required String groupId,
    String? poiId,
    String? customTitle,
    required DateTime scheduledDate,
    String? scheduledTime,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase.from('itinerary_items').insert({
      'group_id': groupId,
      'poi_id': poiId,
      'custom_title': customTitle,
      'added_by': userId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime ?? '10:00',
      'status': 'planned',
      'notes': notes,
    });
  }

  Future<void> updateItineraryStatus(String itemId, ItineraryStatus status) async {
    await _supabase
        .from('itinerary_items')
        .update({'status': status.toJsonString()})
        .eq('id', itemId);
  }

  Future<void> removeItineraryItem(String itemId) async {
    await _supabase.from('itinerary_items').delete().eq('id', itemId);
  }

  Future<void> toggleLocationSharing(String groupId, bool enabled) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('group_members')
        .update({'location_sharing': enabled})
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> updateLocation(String groupId, double lat, double lng) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('group_members')
        .update({
          'last_lat': lat,
          'last_lng': lng,
          'last_location_at': DateTime.now().toIso8601String(),
        })
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .eq('location_sharing', true);
  }

  // ──────────────────── Supabase Realtime Subscriptions ────────────────────

  void subscribeToGroup(
    String groupId, {
    required Function(List<ItineraryItem>) onItineraryChanged,
    required Function(List<GroupMember>) onMembersChanged,
  }) {
    unsubscribe();

    _itineraryChannel = _supabase
        .channel('public:itinerary_items:group_id=eq.$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'itinerary_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) async {
            final items = await getItineraryItems(groupId);
            onItineraryChanged(items);
          },
        )
        .subscribe();

    _membersChannel = _supabase
        .channel('public:group_members:group_id=eq.$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) async {
            final members = await getGroupMembers(groupId);
            onMembersChanged(members);
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    if (_itineraryChannel != null) {
      _supabase.removeChannel(_itineraryChannel!);
      _itineraryChannel = null;
    }
    if (_membersChannel != null) {
      _supabase.removeChannel(_membersChannel!);
      _membersChannel = null;
    }
  }
}
