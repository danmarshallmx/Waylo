import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:waylo/features/city_packages/screens/city_packages_screen.dart';
import 'package:waylo/features/geolocation/screens/geolocation_screen.dart';
import 'package:waylo/features/groups/screens/groups_list_screen.dart';
import 'package:waylo/features/memories/screens/memories_screen.dart';
import 'package:waylo/features/planning/screens/planning_screen.dart';
import '../main.dart';

/// Application route path constants.
abstract class RoutePaths {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String planning = '/planning';
  static const String geolocation = '/geolocation';
  static const String groups = '/groups';
  static const String memories = '/memories';
}

/// Central GoRouter configuration for the Waylo app.
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: RoutePaths.home,
      debugLogDiagnostics: false,
      routes: _routes,
      errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    );
  }

  /// All application routes.
  List<RouteBase> get _routes => [
        GoRoute(
          path: RoutePaths.splash,
          name: 'splash',
          builder: (context, state) => const CityPackagesScreen(),
        ),
        GoRoute(
          path: RoutePaths.auth,
          name: 'auth',
          builder: (context, state) => const _PlaceholderScreen(title: 'Iniciar Sesión'),
        ),

        // ── Main Shell with 5 Module Tabs ─────────────────────────────
        ShellRoute(
          builder: (context, state, child) => _MainShell(child: child),
          routes: [
            GoRoute(
              path: RoutePaths.home,
              name: 'home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: CityPackagesScreen(),
              ),
            ),
            GoRoute(
              path: RoutePaths.planning,
              name: 'planning',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PlanningScreen(),
              ),
            ),
            GoRoute(
              path: RoutePaths.geolocation,
              name: 'geolocation',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: GeolocationScreen(),
              ),
            ),
            GoRoute(
              path: RoutePaths.groups,
              name: 'groups',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: GroupsListScreen(),
              ),
            ),
            GoRoute(
              path: RoutePaths.memories,
              name: 'memories',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MemoriesScreen(groupId: '00000000-0000-0000-0000-000000000001'),
              ),
            ),
          ],
        ),
      ];
}

class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              context.go(RoutePaths.home);
              break;
            case 1:
              context.go(RoutePaths.planning);
              break;
            case 2:
              context.go(RoutePaths.geolocation);
              break;
            case 3:
              context.go(RoutePaths.groups);
              break;
            case 4:
              context.go(RoutePaths.memories);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Ciudades',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Planeación',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'En Destino',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Bóveda',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;
  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
