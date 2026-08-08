import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';
import 'package:my_first_app/domain/repositories/person_repository.dart';

import '../../support/isar_test_init.dart';

void main() {
  late Isar isar;
  late IsarPersonRepository repo;
  late Directory tempDir;

  setUpAll(() async {
    await ensureIsarCoreForTests();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tend_person_repo_');
    isar = await Isar.open(
      [PersonSchema],
      directory: tempDir.path,
      name: 'tend_person_repo_test',
    );
    repo = IsarPersonRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('getByUuid returns active person and null for soft-deleted', () async {
    final now = DateTime(2026, 8, 8);
    final person = Person()
      ..uuid = 'person-active-1'
      ..name = 'Alex'
      ..circleTier = CircleTier.innerCircle
      ..relationshipType = null
      ..createdAt = now
      ..updatedAt = now
      ..syncStatus = SyncStatus.pending
      ..deletedAt = null;

    await repo.create(person);

    expect(await repo.getByUuid('person-active-1'), isNotNull);

    await repo.softDelete('person-active-1');

    expect(await repo.getByUuid('person-active-1'), isNull);
    // Soft-delete still finds the row via the unique index helper.
    final tombstoned = await isar.persons.getByUuid('person-active-1');
    expect(tombstoned, isNotNull);
    expect(tombstoned!.deletedAt, isNotNull);
  });
}
