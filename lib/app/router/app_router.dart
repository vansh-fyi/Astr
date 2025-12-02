import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/object_detail_screen.dart';
import '../../features/planner/presentation/pages/forecast_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/providers/tos_provider.dart';
import '../../features/profile/presentation/screens/tos_screen.dart';
import '../../features/profile/presentation/screens/locations_screen.dart';
import 'package:astr/features/profile/presentation/screens/add_location_screen.dart';
import 'package:astr/features/profile/domain/entities/saved_location.dart';
import 'scaffold_with_nav_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  final shellNavigatorCatalogKey = GlobalKey<NavigatorState>(debugLabel: 'shellCatalog');
  final shellNavigatorForecastKey = GlobalKey<NavigatorState>(debugLabel: 'shellForecast');
  final shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  // Watch the provider to rebuild the router when state changes.
  // This ensures the redirect logic is re-evaluated.
  final tosAccepted = ref.watch(tosNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isTosRoute = state.uri.path == '/tos';

      if (!tosAccepted) {
        return isTosRoute ? null : '/tos';
      }

      if (isTosRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/tos',
        builder: (context, state) => const ToSScreen(),
      ),
      GoRoute(
        path: '/add-location',
        builder: (context, state) => const AddLocationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorCatalogKey,
            routes: [
              GoRoute(
                path: '/catalog',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CatalogScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':objectId',
                    pageBuilder: (context, state) {
                      final objectId = state.pathParameters['objectId']!;
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
            routes: [
              GoRoute(
                path: '/forecast',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ForecastScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'locations',
                    pageBuilder: (context, state) => const MaterialPage(
                      child: LocationsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'add',
                        pageBuilder: (context, state) {
                          final locationToEdit = state.extra as SavedLocation?;
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
