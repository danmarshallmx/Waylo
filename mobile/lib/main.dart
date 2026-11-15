import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'config/app_config.dart';

/// Global navigator key for notification tap navigation.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Global Supabase client accessor.
SupabaseClient get supabase => Supabase.instance.client;

/// Global notification plugin accessor.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Custom BlocObserver for debugging state transitions.
class WayloBlocObserver extends BlocObserver {
  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    debugPrint('${bloc.runtimeType} $transition');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('${bloc.runtimeType} Error: $error');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent UX.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize date formatting for Spanish & international locales
  try {
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('es_MX', null);
    await initializeDateFormatting('en', null);
  } catch (e) {
    debugPrint('DateFormatting init: $e');
  }

  // Initialize Supabase.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Authenticate anonymously so user has a valid Supabase UUID for real-time groups & memories
  try {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Supabase.instance.client.auth.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Supabase anonymous sign-in: $e');
  }

  // Initialize Hive for local NoSQL caching.
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Open commonly used Hive boxes.
  await Hive.openBox<dynamic>('settings');
  await Hive.openBox<dynamic>('city_cache');
  await Hive.openBox<dynamic>('download_progress');

  // Initialize local notifications.
  await _initializeNotifications();

  // Set up BlocObserver for debugging.
  Bloc.observer = WayloBlocObserver();

  runApp(const WayloApp());
}

/// Configure the local notifications plugin for both Android and iOS.
Future<void> _initializeNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  // Request permissions on iOS.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  // Create notification channels for Android.
  const geofenceChannel = AndroidNotificationChannel(
    'waylo_geofence',
    'Nearby POI Alerts',
    description: 'Notifications when you are near a point of interest.',
    importance: Importance.high,
  );

  const groupChannel = AndroidNotificationChannel(
    'waylo_group',
    'Group Updates',
    description: 'Notifications about your travel group activity.',
    importance: Importance.defaultImportance,
  );

  const downloadChannel = AndroidNotificationChannel(
    'waylo_download',
    'Downloads',
    description: 'City pack download progress and completion.',
    importance: Importance.low,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(geofenceChannel);
  await androidPlugin?.createNotificationChannel(groupChannel);
  await androidPlugin?.createNotificationChannel(downloadChannel);
}

/// Handle notification tap routing.
void _onNotificationTapped(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  // Payloads follow the pattern "route:/path?params"
  if (payload.startsWith('route:')) {
    final route = payload.substring(6);
    navigatorKey.currentState?.pushNamed(route);
  }
}
