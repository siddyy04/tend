import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import '../features/capture/share/share_intent_bootstrap.dart';

/// Root application widget.
///
/// Uses [MaterialApp.router] when bootstrap succeeded; otherwise shows a
/// clear startup error (Isar / Supabase init failure).
class App extends ConsumerWidget {
  const App({super.key, this.initializationError});

  /// Non-null when Supabase or Isar bootstrap failed in [main].
  final Object? initializationError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initializationError != null) {
      return MaterialApp(
        title: 'Tend',
        home: _BootstrapError(error: initializationError!),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Tend',
      routerConfig: router,
      builder: (context, child) {
        return ShareIntentBootstrap(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Startup failed:\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
