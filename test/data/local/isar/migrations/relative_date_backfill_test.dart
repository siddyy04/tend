import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/memory.dart';
import 'package:my_first_app/data/local/isar/migrations/relative_date_backfill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/isar_test_init.dart';

void main() {
  late Isar isar;
  late Directory tempDir;

  setUpAll(() async {
    await ensureIsarCoreForTests();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('tend_date_backfill_');
    isar = await Isar.open(
      [MemorySchema],
      directory: tempDir.path,
      name: 'tend_date_backfill_test',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('backfill resolves relative null dateValue using createdAt', () async {
    final created = DateTime(2026, 8, 5, 14, 30);
    final memory = Memory()
      ..uuid = 'mem-rel-1'
      ..personUuid = 'person-1'
      ..category = MemoryCategory.health
      ..eventText = 'Started physiotherapy yesterday'
      ..quoteEvidence = null
      ..datePrecision = DatePrecision.relative
      ..dateValueRaw = 'yesterday'
      ..dateValue = null
      ..importanceScore = 3
      ..extractionConfidence = null
      ..personMatchConfidence = null
      ..sensitivityFlag = SensitivityLevel.high
      ..sourceType = SourceType.text
      ..sourceRef = null
      ..needsUserConfirmation = false
      ..embedding = null
      ..createdAt = created
      ..updatedAt = created
      ..syncStatus = SyncStatus.pending
      ..deletedAt = null;

    await isar.writeTxn(() async {
      await isar.memorys.put(memory);
    });

    final updated = await backfillRelativeDates(isar);
    expect(updated, 1);

    final after = await isar.memorys.getByUuid('mem-rel-1');
    expect(after!.dateValue, DateTime(2026, 8, 4));

    // Idempotent — second pass updates nothing.
    expect(await backfillRelativeDates(isar), 0);
  });

  test('runRelativeDateBackfillIfNeeded runs once via prefs flag', () async {
    final created = DateTime(2026, 8, 8);
    final memory = Memory()
      ..uuid = 'mem-rel-2'
      ..personUuid = 'person-1'
      ..category = MemoryCategory.family
      ..eventText = 'Follow-up next week'
      ..quoteEvidence = null
      ..datePrecision = DatePrecision.relative
      ..dateValueRaw = 'next week'
      ..dateValue = null
      ..importanceScore = 3
      ..extractionConfidence = null
      ..personMatchConfidence = null
      ..sensitivityFlag = SensitivityLevel.medium
      ..sourceType = SourceType.text
      ..sourceRef = null
      ..needsUserConfirmation = false
      ..embedding = null
      ..createdAt = created
      ..updatedAt = created
      ..syncStatus = SyncStatus.pending
      ..deletedAt = null;

    await isar.writeTxn(() async {
      await isar.memorys.put(memory);
    });

    expect(await runRelativeDateBackfillIfNeeded(isar), 1);
    expect(await runRelativeDateBackfillIfNeeded(isar), 0);
  });
}
