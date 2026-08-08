import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';
import '../features/capture/capture_entry_point.dart';
import '../features/capture/capture_screen.dart';
import '../features/capture/confirmation/capture_confirmation_args.dart';
import '../features/capture/confirmation/capture_confirmation_screen.dart';
import '../features/capture/confirmation/capture_multi_confirmation_screen.dart';
import '../features/capture/confirmation/capture_multi_summary_screen.dart';
import '../features/capture/model_setup_screen.dart';
import '../features/capture/photo/ocr_text_args.dart';
import '../features/capture/photo/ocr_text_screen.dart';
import '../features/capture/photo/photo_capture_screen.dart';
import '../features/capture/share/share_providers.dart';
import '../features/capture/share/share_text_screen.dart';
import '../features/capture/share/shared_capture_payload.dart';
import '../features/capture/voice/voice_recording_screen.dart';
import '../features/capture/voice/voice_transcript_screen.dart';
import '../features/circle/circle_screen.dart';
import '../features/memory_form/memory_form_screen.dart';
import '../features/opportunities/opportunities_screen.dart';
import '../features/person_form/person_form_screen.dart';
import '../features/person_profile/person_profile_screen.dart';
import '../features/search/person_search_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../debug/gemma_probe_screen.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onAuth = location == AppRoutes.auth;
      final onShare = location == AppRoutes.captureShare;
      final pendingShare = ref.read(pendingShareProvider);

      if (auth.isLoading) {
        // Never yank an in-progress share capture back to splash.
        if (onShare || pendingShare != null) {
          return onSplash || onShare ? null : AppRoutes.captureShare;
        }
        return onSplash ? null : AppRoutes.splash;
      }

      if (auth.isAuthenticated) {
        if (onSplash || onAuth) {
          // Share flow: never land on Circle while a share is staged.
          if (pendingShare != null) {
            return AppRoutes.captureShare;
          }
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
      // Full-screen form routes (no bottom nav) — keyed by uuid, never Isar id.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.personNew,
        builder: (context, state) => const PersonFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/person/edit/:personUuid',
        builder: (context, state) {
          final personUuid = state.pathParameters['personUuid']!;
          return PersonFormScreen(personUuid: personUuid);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/:personUuid',
        builder: (context, state) {
          final personUuid = state.pathParameters['personUuid']!;
          return PersonProfileScreen(personUuid: personUuid);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/:personUuid/search',
        builder: (context, state) {
          final personUuid = state.pathParameters['personUuid']!;
          return PersonSearchScreen(personUuid: personUuid);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/:personUuid/memory/new',
        builder: (context, state) {
          final personUuid = state.pathParameters['personUuid']!;
          final initialEventText =
              state.extra is String ? state.extra as String : null;
          return MemoryFormScreen(
            personUuid: personUuid,
            initialEventText: initialEventText,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/:personUuid/memory/edit/:memoryUuid',
        builder: (context, state) {
          final personUuid = state.pathParameters['personUuid']!;
          final memoryUuid = state.pathParameters['memoryUuid']!;
          return MemoryFormScreen(
            personUuid: personUuid,
            memoryUuid: memoryUuid,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.modelSetup,
        builder: (context, state) => const ModelSetupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: AppRoutes.gemmaProbe,
          builder: (context, state) => const GemmaProbeScreen(),
        ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.capture,
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureVoice,
        builder: (context, state) => const VoiceRecordingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureVoiceTranscript,
        builder: (context, state) {
          final transcript = state.extra;
          if (transcript is! String || transcript.trim().isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Missing transcript')),
            );
          }
          return VoiceTranscriptScreen(initialTranscript: transcript);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.capturePhoto,
        builder: (context, state) => const PhotoCaptureScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.capturePhotoText,
        builder: (context, state) {
          final args = state.extra;
          if (args is! OcrTextArgs) {
            return const Scaffold(
              body: Center(child: Text('Missing OCR text')),
            );
          }
          return OcrTextScreen(args: args);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureShare,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final payload =
              extra is SharedCapturePayload ? extra : null;
          return MaterialPage<void>(
            key: ValueKey<Object>(
              payload == null
                  ? state.pageKey
                  : Object.hash(payload.text, payload.sourceRef),
            ),
            name: AppRoutes.captureShare,
            child: ShareTextScreen(initialPayload: payload),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureConfirm,
        builder: (context, state) {
          final args = state.extra;
          if (args is! CaptureConfirmationArgs) {
            return const Scaffold(
              body: Center(child: Text('Missing capture details')),
            );
          }
          return CaptureConfirmationScreen(args: args);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureConfirmSummary,
        builder: (context, state) {
          final args = state.extra;
          if (args is! CaptureConfirmationArgs) {
            return const Scaffold(
              body: Center(child: Text('Missing capture details')),
            );
          }
          return CaptureMultiSummaryScreen(args: args);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.captureConfirmMulti,
        builder: (context, state) {
          final args = state.extra;
          if (args is! CaptureConfirmationArgs) {
            return const Scaffold(
              body: Center(child: Text('Missing capture details')),
            );
          }
          return CaptureMultiConfirmationScreen(args: args);
        },
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
      floatingActionButton: const CaptureEntryPoint(),
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
