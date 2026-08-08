import 'package:isar_community/isar.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// Person persistence contract — Isar is touched only through this layer.
abstract class PersonRepository {
  /// Active (non-tombstoned) people as a flat list. No grouping.
  Stream<List<Person>> watchActivePeople();

  /// Snapshot of active people (for Search attribution / name matching).
  Future<List<Person>> getActivePeople();

  Future<Person?> getByUuid(String uuid);

  Future<void> create(Person person);

  Future<void> update(Person person);

  /// Soft-delete only: sets [Person.deletedAt], [Person.updatedAt], and
  /// [Person.syncStatus] — never hard-deletes the Isar row.
  Future<void> softDelete(String uuid);
}

/// Isar-backed [PersonRepository].
class IsarPersonRepository implements PersonRepository {
  IsarPersonRepository(this._isar);

  final Isar _isar;

  @override
  Stream<List<Person>> watchActivePeople() {
    return _isar.persons.filter().deletedAtIsNull().watch(fireImmediately: true);
  }

  @override
  Future<List<Person>> getActivePeople() {
    return _isar.persons.filter().deletedAtIsNull().findAll();
  }

  @override
  Future<Person?> getByUuid(String uuid) {
    return _isar.persons
        .filter()
        .uuidEqualTo(uuid)
        .and()
        .deletedAtIsNull()
        .findFirst();
  }

  @override
  Future<void> create(Person person) async {
    await _isar.writeTxn(() async {
      await _isar.persons.put(person);
    });
  }

  @override
  Future<void> update(Person person) async {
    await _isar.writeTxn(() async {
      await _isar.persons.put(person);
    });
  }

  @override
  Future<void> softDelete(String uuid) async {
    await _isar.writeTxn(() async {
      final person = await _isar.persons.getByUuid(uuid);
      if (person == null) {
        throw StateError('Cannot soft-delete unknown person uuid: $uuid');
      }
      final now = DateTime.now();
      person.deletedAt = now;
      person.updatedAt = now;
      person.syncStatus = SyncStatus.pending;
      await _isar.persons.put(person);
    });
  }
}
