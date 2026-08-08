import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/domain/rules/date_resolution_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key — one-time relative-date backfill (Foundation Cleanup).
const relativeDateBackfillPrefsKey = 'migration_relative_date_backfill_v1';

/// Idempotent backfill: for each Memory with `datePrecision == relative` and
/// `dateValue == null`, resolve [Memory.dateValueRaw] using [Memory.createdAt]
/// as the anchor and write [Memory.dateValue] when resolvable.
///
/// Skips rows that already have `dateValue` set. Safe to run more than once.
/// Returns the number of rows updated.
Future<int> backfillRelativeDates(Isar isar) async {
  final candidates = await isar.memorys
      .filter()
      .datePrecisionEqualTo(DatePrecision.relative)
      .and()
      .dateValueIsNull()
      .findAll();

  if (candidates.isEmpty) return 0;

  var updated = 0;
  await isar.writeTxn(() async {
    for (final memory in candidates) {
      if (memory.dateValue != null) continue;
      final raw = memory.dateValueRaw;
      if (raw == null || raw.trim().isEmpty) continue;

      final resolved = resolveRelativeDate(
        rawPhrase: raw,
        anchorDate: memory.createdAt,
      );
      if (resolved == null) continue;

      memory.dateValue = resolved;
      await isar.memorys.put(memory);
      updated++;
    }
  });
  return updated;
}

/// Runs [backfillRelativeDates] once per install (prefs flag), then marks done.
///
/// The backfill itself is also idempotent, so a crash mid-run is safe to retry.
Future<int> runRelativeDateBackfillIfNeeded(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(relativeDateBackfillPrefsKey) ?? false) {
    return 0;
  }

  final updated = await backfillRelativeDates(isar);
  await prefs.setBool(relativeDateBackfillPrefsKey, true);
  return updated;
}
