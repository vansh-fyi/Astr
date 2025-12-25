import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/object_detail_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/planner/presentation/pages/forecast_screen.dart';
import '../../features/profile/domain/entities/saved_location.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/providers/tos_provider.dart';
import '../../features/profile/presentation/screens/add_location_screen.dart';
import '../../features/profile/presentation/screens/locations_screen.dart';
import '../../features/profile/presentation/screens/tos_screen.dart';
import '../../features/splash/presentation/providers/initialization_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'scaffold_with_nav_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  final GlobalKey<NavigatorState> shellNavigatorCatalogKey = GlobalKey<NavigatorState>(debugLabel: 'shellCatalog');
  final GlobalKey<NavigatorState> shellNavigatorForecastKey = GlobalKey<NavigatorState>(debugLabel: 'shellForecast');
  final GlobalKey<NavigatorState> shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  // Watch the provider to rebuild the router when state changes.
  // This ensures the redirect logic is re-evaluated.
  final bool tosAccepted = ref.watch(tosNotifierProvider);
  final bool initialized = ref.watch(initializationNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final bool isSplashRoute = state.uri.path == '/splash';
      final bool isTosRoute = state.uri.path == '/tos';

      // Show splash during initialization
      if (!initialized) {
        return isSplashRoute ? null : '/splash';
      }

      // After initialization, handle ToS redirect
      if (!tosAccepted) {
        return isTosRoute ? null : '/tos';
      }

      if (isTosRoute || isSplashRoute) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) => SplashScreen(
          onInitializationComplete: () {
            ref.read(initializationNotifierProvider.notifier).initialize();
          },
        ),
      ),
      GoRoute(
        path: '/tos',
        builder: (BuildContext context, GoRouterState state) => const ToSScreen(),
      ),
      GoRoute(
        path: '/add-location',
        builder: (BuildContext context, GoRouterState state) => const AddLocationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorCatalogKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/catalog',
                pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
                  child: CatalogScreen(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':objectId',
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      final String objectId = state.pathParameters['objectId']!;
                      return MaterialPage(
                        child: ObjectDetailScreen(objectId: objectId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorForecastKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/forecast',
                pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
                  child: ForecastScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorProfileKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'locations',
                    pageBuilder: (BuildContext context, GoRouterState state) => const MaterialPage(
                      child: LocationsScreen(),
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'add',
                        pageBuilder: (BuildContext context, GoRouterState state) {
                          final SavedLocation? locationToEdit = state.extra as SavedLocation?;
                          return MaterialPage(
                            child: AddLocationScreen(locationToEdit: locationToEdit),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
