import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod access to the opened Isar instance.
///
/// Overridden in [main] after [initializeIsar] succeeds with schemas.
/// Remains `null` during bootstrap until the data model layer registers
/// collection schemas (Isar requires at least one schema to open).
final isarProvider = Provider<Isar?>((ref) => null);

/// Application documents directory used for the Tend Isar database file.
Future<String> _isarDirectoryPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

/// Initializes local Isar storage.
///
/// [schemas] must be non-empty for a real [Isar] instance (Isar enforces this).
/// During this bootstrap step, schemas are not registered yet — this function
/// still verifies the documents directory is reachable and returns `null`.
/// The data model step will call this again (or extend it) with SCHEMA.md
/// collection schemas so [Isar.open] can complete.
Future<Isar?> initializeIsar({
  List<CollectionSchema<dynamic>> schemas = const [],
}) async {
  final directory = await _isarDirectoryPath();

  if (schemas.isEmpty) {
    // Directory probe only — proves path_provider + storage access work.
    // Real open is deferred until collections/codegen exist.
    assert(() {
      debugPrint(
        'Isar bootstrap: directory ready at $directory '
        '(open deferred until schemas are registered).',
      );
      return true;
    }());
    return null;
  }

  return Isar.open(
    schemas,
    directory: directory,
    name: 'tend',
  );
}
