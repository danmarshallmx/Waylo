import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'features/city_packages/bloc/city_packages_bloc.dart';
import 'features/city_packages/bloc/city_packages_event.dart';
import 'features/city_packages/repositories/city_packages_repository.dart';
import 'features/geolocation/bloc/geolocation_bloc.dart';
import 'features/geolocation/repositories/geolocation_repository.dart';
import 'features/geolocation/services/audio_player_service.dart';
import 'features/geolocation/services/geofence_service.dart';
import 'features/groups/bloc/groups_bloc.dart';
import 'features/groups/bloc/groups_event.dart';
import 'features/groups/repositories/groups_repository.dart';
import 'features/memories/bloc/memories_bloc.dart';
import 'features/memories/repositories/memories_repository.dart';
import 'features/planning/bloc/planning_bloc.dart';
import 'features/planning/repositories/planning_repository.dart';
import 'main.dart';

/// Root widget for the Waylo application.
class WayloApp extends StatefulWidget {
  const WayloApp({super.key});

  @override
  State<WayloApp> createState() => _WayloAppState();
}

class _WayloAppState extends State<WayloApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();

    // Listen to Supabase auth state changes for route redirects.
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      switch (event) {
        case AuthChangeEvent.signedIn:
          _appRouter.router.go('/home');
          break;
        case AuthChangeEvent.signedOut:
          _appRouter.router.go('/auth');
          break;
        case AuthChangeEvent.tokenRefreshed:
          debugPrint('Waylo: Auth token refreshed.');
          break;
        case AuthChangeEvent.passwordRecovery:
          _appRouter.router.go('/auth/reset-password');
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CityPackagesRepository>(
          create: (_) => CityPackagesRepository(),
        ),
        RepositoryProvider<PlanningRepository>(
          create: (_) => PlanningRepository(),
        ),
        RepositoryProvider<GeofenceService>(
          create: (_) => GeofenceService(),
        ),
        RepositoryProvider<AudioPlayerService>(
          create: (_) => AudioPlayerService(),
        ),
        RepositoryProvider<GeolocationRepository>(
          create: (ctx) => GeolocationRepository(
            geofenceService: ctx.read<GeofenceService>(),
          ),
        ),
        RepositoryProvider<GroupsRepository>(
          create: (_) => GroupsRepository(),
        ),
        RepositoryProvider<MemoriesRepository>(
          create: (_) => MemoriesRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CityPackagesBloc>(
            create: (ctx) => CityPackagesBloc(
              repository: ctx.read<CityPackagesRepository>(),
            )..add(const LoadAvailableCities()),
          ),
          BlocProvider<PlanningBloc>(
            create: (ctx) => PlanningBloc(
              repository: ctx.read<PlanningRepository>(),
            ),
          ),
          BlocProvider<GeolocationBloc>(
            create: (ctx) => GeolocationBloc(
              repository: ctx.read<GeolocationRepository>(),
              geofenceService: ctx.read<GeofenceService>(),
              audioPlayerService: ctx.read<AudioPlayerService>(),
            ),
          ),
          BlocProvider<GroupsBloc>(
            create: (ctx) => GroupsBloc(
              repository: ctx.read<GroupsRepository>(),
            )..add(const LoadUserGroups()),
          ),
          BlocProvider<MemoriesBloc>(
            create: (ctx) => MemoriesBloc(
              repository: ctx.read<MemoriesRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Waylo',
          debugShowCheckedModeBanner: false,
          theme: WayloTheme.lightTheme,
          darkTheme: WayloTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
