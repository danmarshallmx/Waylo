import 'dart:async';
import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:waylo/core/models/memory_photo.dart';
import 'package:waylo/core/models/poi.dart';
import 'package:waylo/core/utils/geo_utils.dart';

class MemoriesRepository {
  final SupabaseClient _supabase;
  RealtimeChannel? _photosChannel;

  MemoriesRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<MemoryPhoto>> getGroupPhotos(String groupId) async {
    final response = await _supabase
        .from('memory_photos')
        .select('*')
        .eq('group_id', groupId)
        .order('captured_at', ascending: false);

    return (response as List).map((json) => MemoryPhoto.fromJson(json)).toList();
  }

  /// Extracts EXIF coordinates and UTC timestamp from local image file
  Future<Map<String, dynamic>> extractExifMetadata(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);

    double? latitude;
    double? longitude;
    DateTime capturedAt = DateTime.now().toUtc();

    try {
      // Extract GPS
      final gpsLat = data['GPS GPSLatitude'];
      final gpsLatRef = data['GPS GPSLatitudeRef']?.printable;
      final gpsLng = data['GPS GPSLongitude'];
      final gpsLngRef = data['GPS GPSLongitudeRef']?.printable;

      if (gpsLat != null && gpsLng != null) {
        latitude = _convertToDegrees(gpsLat);
        if (gpsLatRef == 'S') latitude = -latitude;

        longitude = _convertToDegrees(gpsLng);
        if (gpsLngRef == 'W') longitude = -longitude;
      }

      // Extract capture time
      final dateTimeOriginal = data['EXIF DateTimeOriginal']?.printable;
      if (dateTimeOriginal != null) {
        // format usually: YYYY:MM:DD HH:MM:SS
        final parts = dateTimeOriginal.split(' ');
        final dateParts = parts[0].replaceAll(':', '-');
        capturedAt = DateTime.parse('${dateParts}T${parts[1]}Z');
      }
    } catch (e) {
      debugPrint('EXIF parse error: $e');
    }

    return {
      'latitude': latitude,
      'longitude': longitude,
      'captured_at': capturedAt,
      'raw_exif': data.map((key, value) => MapEntry(key, value.printable)),
    };
  }

  double _convertToDegrees(IfdTag tag) {
    final values = tag.values.toList();
    final deg = (values[0] as Ratio).toDouble();
    final min = (values[1] as Ratio).toDouble();
    final sec = (values[2] as Ratio).toDouble();
    return deg + (min / 60.0) + (sec / 3600.0);
  }

  /// Uploads photo file to Supabase storage, extracts metadata, inserts DB row
  Future<MemoryPhoto> uploadPhoto({
    required String groupId,
    required String filePath,
    List<POI> destinationPois = const [],
    void Function(double progress)? onProgress,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final file = File(filePath);
    final fileName = '${const Uuid().v4()}_${file.uri.pathSegments.last}';
    final storagePath = '$groupId/$fileName';

    // 1. Extract EXIF
    final exif = await extractExifMetadata(filePath);
    final double? lat = exif['latitude'] as double?;
    final double? lng = exif['longitude'] as double?;
    final DateTime capturedAt = exif['captured_at'] as DateTime;

    // 2. Match nearest POI if coordinates exist (<200m)
    String? matchedPoiId;
    if (lat != null && lng != null && destinationPois.isNotEmpty) {
      double minDistance = double.infinity;
      for (final poi in destinationPois) {
        final d = GeoUtils.distanceKm(lat, lng, poi.latitude, poi.longitude) * 1000;
        if (d <= 200 && d < minDistance) {
          minDistance = d;
          matchedPoiId = poi.id;
        }
      }
    }

    onProgress?.call(0.3);

    // 3. Upload to Storage
    await _supabase.storage.from('waylo-memories').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    onProgress?.call(0.7);

    final publicUrl =
        _supabase.storage.from('waylo-memories').getPublicUrl(storagePath);

    // 4. Save record
    final record = await _supabase
        .from('memory_photos')
        .insert({
          'group_id': groupId,
          'user_id': userId,
          'poi_id': matchedPoiId,
          'storage_url': publicUrl,
          'thumbnail_url': publicUrl,
          'latitude': lat,
          'longitude': lng,
          'captured_at': capturedAt.toIso8601String(),
          'exif_data': exif['raw_exif'] ?? {},
        })
        .select()
        .single();

    onProgress?.call(1.0);

    return MemoryPhoto.fromJson(record);
  }

  Future<void> deletePhoto(String photoId) async {
    await _supabase.from('memory_photos').delete().eq('id', photoId);
  }

  Future<void> updateCaption(String photoId, String caption) async {
    await _supabase
        .from('memory_photos')
        .update({'caption': caption})
        .eq('id', photoId);
  }

  // ──────────────────── Supabase Realtime Subscriptions ────────────────────

  void subscribeToGroupPhotos(String groupId, Function(MemoryPhoto) onNewPhoto) {
    unsubscribe();

    _photosChannel = _supabase
        .channel('public:memory_photos:group_id=eq.$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'memory_photos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final photo = MemoryPhoto.fromJson(payload.newRecord);
            onNewPhoto(photo);
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    if (_photosChannel != null) {
      _supabase.removeChannel(_photosChannel!);
      _photosChannel = null;
    }
  }
}
