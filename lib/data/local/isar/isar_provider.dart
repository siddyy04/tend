import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'collections/connection.dart';
import 'collections/follow_up.dart';
import 'collections/memory.dart';
import 'collections/person.dart';
import 'collections/suggestion_log_entry.dart';

/// All Isar collection schemas from SCHEMA.md.
///
/// Passed to [initializeIsar] so the database fails fast if open cannot succeed.
final List<CollectionSchema<dynamic>> tendIsarSchemas = [
  PersonSchema,
  MemorySchema,
  FollowUpSchema,
  SuggestionLogEntrySchema,
  ConnectionSchema,
];

/// Riverpod access to the opened Isar instance.
///
/// Must be overridden in [main] after a successful [initializeIsar].
/// Reading without an override is a programming error.
final isarProvider = Provider<Isar>((ref) {
  throw StateError(
    'Isar has not been initialized. '
    'Call initializeIsar() in main and override isarProvider.',
  );
});

/// Opens the local Isar database with [tendIsarSchemas].
///
/// Throws if schemas are empty or if [Isar.open] fails — the app must not
/// continue without a working database.
Future<Isar> initializeIsar({
  List<CollectionSchema<dynamic>>? schemas,
}) async {
  final effectiveSchemas = schemas ?? tendIsarSchemas;
  if (effectiveSchemas.isEmpty) {
    throw StateError(
      'Isar initialization failed: no collection schemas registered.',
    );
  }

  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    effectiveSchemas,
    directory: dir.path,
    name: 'tend',
  );
}
