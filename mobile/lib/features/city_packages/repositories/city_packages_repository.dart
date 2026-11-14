import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:waylo/core/models/audio_capsule.dart';
import 'package:waylo/core/models/city_package.dart';
import 'package:waylo/core/models/poi.dart';

class CityPackagesRepository {
  final SupabaseClient _supabase;
  late final Box<Map> _cityBox;
  Database? _db;
  bool _initialized = false;

  CityPackagesRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    _cityBox = await Hive.openBox<Map>('downloaded_cities');

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/waylo_cities.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pois (
            id TEXT PRIMARY KEY,
            city_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            category TEXT NOT NULL,
            rating REAL DEFAULT 0,
            image_url TEXT,
            audio_url TEXT,
            weight INTEGER DEFAULT 1,
            localized_names TEXT,
            tags TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audio_capsules (
            id TEXT PRIMARY KEY,
            poi_id TEXT NOT NULL,
            language TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            audio_url TEXT NOT NULL,
            local_path TEXT,
            duration_seconds INTEGER DEFAULT 0,
            size_bytes INTEGER DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_pois_city_id ON pois(city_id)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_audio_poi_id ON audio_capsules(poi_id)',
        );
      },
    );

    _initialized = true;
  }

  /// Fetches the list of available city packages from Supabase.
  Future<List<CityPackage>> fetchAvailableCities() async {
    await _ensureInitialized();

    final response = await _supabase
        .from('city_packages')
        .select()
        .eq('is_active', true)
        .order('name');

    return (response as List<dynamic>)
        .map((json) => CityPackage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Downloads a city package with all assets.
  ///
  /// Returns a [Stream<double>] emitting progress values from 0.0 to 1.0.
  Stream<double> downloadCityPackage(String cityId) {
    final controller = StreamController<double>();

    _performDownload(cityId, controller).then((_) {
      controller.close();
    }).catchError((error) {
      controller.addError(error);
      controller.close();
    });

    return controller.stream;
  }

  Future<void> _performDownload(
    String cityId,
    StreamController<double> controller,
  ) async {
    await _ensureInitialized();

    // 1. Fetch manifest from Supabase
    controller.add(0.05);
    final manifestResponse = await _supabase
        .from('city_packages')
        .select()
        .eq('id', cityId)
        .single();

    final cityPackage =
        CityPackage.fromJson(manifestResponse as Map<String, dynamic>);
    controller.add(0.1);

    // 2. Download POIs JSON
    final poisResponse = await _supabase
        .from('pois')
        .select()
        .eq('city_id', cityId);

    final pois = (poisResponse as List<dynamic>)
        .map((json) => POI.fromJson(json as Map<String, dynamic>))
        .toList();
    controller.add(0.3);

    // 3. Store POIs in local SQLite
    final batch = _db!.batch();
    for (final poi in pois) {
      batch.insert(
        'pois',
        {
          ...poi.toJson(),
          'localized_names': poi.localizedNames != null
              ? jsonEncode(poi.localizedNames)
              : null,
          'tags': jsonEncode(poi.tags),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    controller.add(0.5);

    // 4. Download audio capsules metadata
    final audioCapsuleResponse = await _supabase
        .from('audio_capsules')
        .select()
        .inFilter('poi_id', pois.map((p) => p.id).toList());

    final audioCapsules = (audioCapsuleResponse as List<dynamic>)
        .map((json) => AudioCapsule.fromJson(json as Map<String, dynamic>))
        .toList();
    controller.add(0.6);

    // 5. Download audio files in parallel (batches of 5)
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/waylo/audio/$cityId');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }

    final totalAudio = audioCapsules.length;
    int downloadedCount = 0;

    for (int i = 0; i < audioCapsules.length; i += 5) {
      final batch = audioCapsules.skip(i).take(5).toList();
      await Future.wait(batch.map((capsule) async {
        try {
          final response = await http.get(Uri.parse(capsule.audioUrl));
          if (response.statusCode == 200) {
            final filePath =
                '${audioDir.path}/${capsule.id}.mp3';
            await File(filePath).writeAsBytes(response.bodyBytes);

            // Store metadata with local path in SQLite
            await _db!.insert(
              'audio_capsules',
              {
                ...capsule.toJson(),
                'local_path': filePath,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {
          // Skip failed audio files, continue downloading
        }
        downloadedCount++;
      }));

      final audioProgress = totalAudio > 0
          ? (downloadedCount / totalAudio) * 0.3
          : 0.3;
      controller.add(0.6 + audioProgress);
    }

    // 6. Store city package metadata in Hive
    await _cityBox.put(cityId, cityPackage.toJson());
    controller.add(1.0);
  }

  /// Returns the list of downloaded city packages from local storage.
  Future<List<CityPackage>> getDownloadedCities() async {
    await _ensureInitialized();

    final cities = <CityPackage>[];
    for (final key in _cityBox.keys) {
      final json = _cityBox.get(key);
      if (json != null) {
        cities.add(CityPackage.fromJson(Map<String, dynamic>.from(json)));
      }
    }
    return cities;
  }

  /// Deletes a downloaded city package and cleans up all local storage.
  Future<void> deleteCityPackage(String cityId) async {
    await _ensureInitialized();

    // Remove from Hive
    await _cityBox.delete(cityId);

    // Remove POIs from SQLite
    await _db!.delete('pois', where: 'city_id = ?', whereArgs: [cityId]);

    // Remove audio capsule records (get them first for file cleanup)
    final capsules = await _db!.query(
      'audio_capsules',
      columns: ['local_path'],
      where: 'poi_id IN (SELECT id FROM pois WHERE city_id = ?)',
      whereArgs: [cityId],
    );

    // Delete audio files
    for (final capsule in capsules) {
      final path = capsule['local_path'] as String?;
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }

    // Remove audio capsule records
    await _db!.rawDelete(
      'DELETE FROM audio_capsules WHERE poi_id IN (SELECT id FROM pois WHERE city_id = ?)',
      [cityId],
    );

    // Cleanup directory
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/waylo/audio/$cityId');
    if (audioDir.existsSync()) {
      audioDir.deleteSync(recursive: true);
    }
  }

  /// Checks for version updates by comparing local vs remote package versions.
  ///
  /// Returns a map of cityId → latest remote version for packages that
  /// have available updates.
  Future<Map<String, int>> checkForUpdates() async {
    await _ensureInitialized();

    final downloadedCities = await getDownloadedCities();
    if (downloadedCities.isEmpty) return {};

    final cityIds = downloadedCities.map((c) => c.id).toList();
    final remoteResponse = await _supabase
        .from('city_packages')
        .select('id, version')
        .inFilter('id', cityIds);

    final updates = <String, int>{};
    for (final remote in (remoteResponse as List<dynamic>)) {
      final remoteId = remote['id'] as String;
      final remoteVersion = remote['version'] as int;
      final local = downloadedCities.firstWhere(
        (c) => c.id == remoteId,
        orElse: () => downloadedCities.first,
      );
      if (remoteVersion > local.version) {
        updates[remoteId] = remoteVersion;
      }
    }

    return updates;
  }

  /// Returns all POIs for a given city from local SQLite.
  Future<List<POI>> getCityPOIs(String cityId) async {
    await _ensureInitialized();

    final results = await _db!.query(
      'pois',
      where: 'city_id = ?',
      whereArgs: [cityId],
    );

    return results.map((row) {
      final json = Map<String, dynamic>.from(row);
      // Decode JSON strings back to proper types
      if (json['localized_names'] != null &&
          json['localized_names'] is String) {
        json['localized_names'] = jsonDecode(json['localized_names'] as String);
      }
      if (json['tags'] != null && json['tags'] is String) {
        json['tags'] = jsonDecode(json['tags'] as String);
      }
      return POI.fromJson(json);
    }).toList();
  }

  /// Returns the local file path for an audio capsule.
  Future<String?> getAudioCapsule(String poiId, String language) async {
    await _ensureInitialized();

    final results = await _db!.query(
      'audio_capsules',
      columns: ['local_path'],
      where: 'poi_id = ? AND language = ?',
      whereArgs: [poiId, language],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['local_path'] as String?;
    }
    return null;
  }
}
