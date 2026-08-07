import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';
import '../features/circle/circle_screen.dart';
import '../features/opportunities/opportunities_screen.dart';
import '../features/search/search_screen.dart';

/// Route path constants for Sprint 0.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const circle = '/circle';
  static const today = '/today';
  static const search = '/search';
}

/// Notifies [GoRouter] when [authControllerProvider] changes.
class _AuthRouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Application [GoRouter], reactive to auth session state.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen<AppAuthState>(authControllerProvider, (_, _) => refresh.notify());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onAuth = location == AppRoutes.auth;

      if (auth.isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      if (auth.isAuthenticated) {
        if (onSplash || onAuth) {
          return AppRoutes.circle;
        }
        return null;
      }

      // Unauthenticated
      if (!onAuth) {
        return AppRoutes.auth;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.circle,
                builder: (context, state) => const CircleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const OpportunitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bottom-nav shell — preserves per-tab state via [StatefulShellRoute.indexedStack].
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'My Circle',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
