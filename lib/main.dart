import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/providers/litert/litert_inference_adapter.dart';
import 'app/app.dart';
import 'data/local/isar/isar_provider.dart';
import 'data/local/isar/migrations/relative_date_backfill.dart';
import 'data/remote/supabase/supabase_client.dart';

/// Application entrypoint.
///
/// Responsibilities (Sprint 0): initialize Supabase, initialize Isar,
/// wrap with [ProviderScope], run [App]. No other logic belongs here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureLiteRtRuntimeInitialized();

  try {
    await initializeSupabase();
    final isar = await initializeIsar();
    // Foundation Cleanup Item B — one-time relative dateValue backfill.
    await runRelativeDateBackfillIfNeeded(isar);

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const App(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Bootstrap failed: $error\n$stackTrace');
    runApp(
      ProviderScope(
        child: App(initializationError: error),
      ),
    );
  }
}
