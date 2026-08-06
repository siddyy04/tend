import 'package:flutter/material.dart';

/// Root application widget.
///
/// Hosts [MaterialApp] only. Routing, auth redirects, and shell navigation
/// are wired in later Sprint 0 steps via `router.dart`.
class App extends StatelessWidget {
  const App({super.key, this.initializationError});

  /// Non-null when Supabase or Isar bootstrap failed in [main].
  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tend',
      home: initializationError == null
          ? const _BootstrapOk()
          : _BootstrapError(error: initializationError!),
    );
  }
}

class _BootstrapOk extends StatelessWidget {
  const _BootstrapOk();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Tend'),
      ),
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
